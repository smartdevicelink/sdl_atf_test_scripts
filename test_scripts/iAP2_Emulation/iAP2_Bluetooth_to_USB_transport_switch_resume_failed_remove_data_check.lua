--  Requirement summary:
--  TBD
--
--  Description:
--  iAP2 Bluetooth connection is switched to iAP2 USB connection automatically, application(s) remains registered,
--  but application(s) sends wrong hashID or it's absent so all resume data must be cleaned up
--
--  1. Used precondition
--  SDL is built with BUILD_TEST = ON to enable iAP2 BT/USB transport adapter emulation
--  SDL, HMI are running on system.
--
--  2. Performed steps
--  iAP2 Bluetooth mobile device connects to system
--  appID_1->RegisterAppInterface(params)
--  RAI response is SUCCESS
--  application subscribes for buttons, vehicle data, waypoints, sends files, commands, choices etc.
--
--  same iAP2 mobile device is connected over USB to system and re-registers within AppTransportChangeTimer timeout
--  appID_1->RegisterAppInterface(params), but with wrong hashID
--  all resume data must be cleaned up, global properties should be reset, files (except icon) removed
--
--  Expected behavior:
--  1. SDL successfully registers application and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--     application send all possible data for resumption and files
--
--  2. SDL successfully registers application and notifies mobile only with RAI response
--     SDL->appID: RESUME_FAILED, success:"true":RegisterAppInterface()
--     application remains registered internally
--     application does not send OnAppUnregistered notification to HMI
--     application does not send OnAppRegistered notification to HMI
--     all resume data cleaned up or reset, files (except icon) removed

---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2

-- [[ Required Shared Libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

local mobile = require("mobile_connection")
local mobile_session = require("mobile_session")

local tcp = require("tcp_connection")
local file_connection = require("file_connection")

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_iap2_emulation")
require("cardinalities")
require("user_modules/AppTypes")

-- [[Local variables]]
local app_RAI_params = config["application1"].registerAppInterfaceParams
local light_cyan_color = 36
local put_file_name = "file.json"
local icon_file_name = "icon.png"

--[[ 
IN ORDER TO USE IAP2 EMULATION IN SDL IT MUST BE BUILT ON 
https://github.com/dev-gh/sdl_core/tree/experimental/IAP_adapters_emulation
WITH 
BUILD_TESTS = ON
]]
local iAP2_BT_DeviceID = "127.0.0.1"
local iAP2_BT_Port = 23456
local iAP2_BT_out = "iap2bt.out"
local iAP2_BT_Type = "BLUETOOTH"

-- Device IDs must be the same in order to trigger switching logic
local iAP2_USB_DeviceID = iAP2_BT_DeviceID
local iAP2_USB_Port = 34567
local iAP2_USB_out = "iap2usb.out"
local iAP2_USB_Type = "USB_IOS"

local function createIAP2Device(deviceID, devicePort, deviceOut)
    local iap2Connection = tcp.Connection(deviceID, devicePort)
    local fileConnection = file_connection.FileConnection(deviceOut, iap2Connection)
    local iap2Device = mobile.MobileConnection(fileConnection)

    event_dispatcher:AddConnection(iap2Device)

    return iap2Device
end

local function isFileExisting(file_name)
    -- Device id produced for iAP2 Bluetooth by SDL = hashed device id
    local device_id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
    return commonFunctions:File_exists(
        config.pathToSDL .. "storage/" .. app_RAI_params.appID .. "_" .. device_id .. "/" .. file_name
    )
end

local function AddFileForApplication(session, file_name, file_type)
    local correlation_id =
        session:SendRPC(
        "PutFile",
        {
            syncFileName = file_name,
            fileType = file_type,
            persistentFile = false,
            systemFile = false
        },
        "files/" .. file_name
    )
    EXPECT_RESPONSE(correlation_id, session, {success = true}):Do(
        function(_, data)
            if true ~= isFileExisting(file_name) then
                Test:FailTestCase("File '" .. file_name .. "' is not found")
            end
        end
    )
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

local iap2bt_device = 0
local iap2bt_mobileSession = 0

Test["Connecting iAP2 Bluetooth"] =
    function(self)
    -- iAP2 Bluetooth connection with application registered
    iap2bt_device = createIAP2Device(iAP2_BT_DeviceID, iAP2_BT_Port, iAP2_BT_out)

    Test:connectMobile(iap2bt_device)

    iap2bt_mobileSession = mobile_session.MobileSession(self, iap2bt_device, app_RAI_params)

    local rpc_service_id = 7
    iap2bt_mobileSession:StartService(rpc_service_id):Do(
        function()
            local correlation_id = iap2bt_mobileSession:SendRPC("RegisterAppInterface", app_RAI_params)
            iap2bt_mobileSession:ExpectResponse(correlation_id, {success = true, resultCode = "SUCCESS"})

            EXPECT_HMINOTIFICATION(
                "Buttons.OnButtonSubscription",
                {
                    isSubscribed = true,
                    name = "CUSTOM_BUTTON"
                }
            )
        end
    )
end

Test["Adding way points subsription"] =
    function(self)
    local correlation_id = iap2bt_mobileSession:SendRPC("SubscribeWayPoints", {})
    EXPECT_HMICALL("Navigation.SubscribeWayPoints"):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )
    EXPECT_RESPONSE(correlation_id, iap2bt_mobileSession, {success = true, resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnHashChange", iap2bt_mobileSession)
end

Test["Adding command"] =
    function(self)
    local correlation_id =
        iap2bt_mobileSession:SendRPC(
        "AddCommand",
        {
            cmdID = 1,
            menuParams = {
                position = 0,
                menuName = "Command"
            },
            vrCommands = {
                "VRCommandonepositive"
            }
        }
    )

    EXPECT_HMICALL(
        "UI.AddCommand",
        {
            cmdID = 1,
            menuParams = {
                position = 0,
                menuName = "Command"
            }
        }
    ):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_HMICALL(
        "VR.AddCommand",
        {
            cmdID = 1,
            type = "Command",
            vrCommands = {
                "VRCommandonepositive"
            }
        }
    ):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_RESPONSE(correlation_id, iap2bt_mobileSession, {success = true, resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnHashChange", iap2bt_mobileSession)
end

Test["Adding submenu"] =
    function(self)
    local id = 11
    local correlation_id =
        iap2bt_mobileSession:SendRPC(
        "AddSubMenu",
        {
            menuID = id,
            menuName = "SubMenumandatoryonly"
        }
    )
    EXPECT_HMICALL(
        "UI.AddSubMenu",
        {
            menuID = id,
            menuParams = {
                menuName = "SubMenumandatoryonly"
            }
        }
    ):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_RESPONSE(correlation_id, iap2bt_mobileSession, {success = true, resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnHashChange", iap2bt_mobileSession)
end

Test["Adding choice set"] =
    function(self)
    local id = 123
    local correlation_id =
        iap2bt_mobileSession:SendRPC(
        "CreateInteractionChoiceSet",
        {
            interactionChoiceSetID = id,
            choiceSet = {
                {
                    choiceID = id,
                    menuName = "Choice" .. id,
                    vrCommands = {
                        "VRChoice" .. id
                    }
                }
            }
        }
    )

    EXPECT_HMICALL(
        "VR.AddCommand",
        {
            cmdID = id,
            type = "Choice",
            vrCommands = {"VRChoice" .. id}
        }
    ):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_RESPONSE(correlation_id, iap2bt_mobileSession, {success = true, resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnHashChange", iap2bt_mobileSession)
end

Test["Adding global properties"] =
    function(self)
    local correlation_id =
        iap2bt_mobileSession:SendRPC(
        "SetGlobalProperties",
        {
            helpPrompt = {{text = "Speak", type = "TEXT"}},
            timeoutPrompt = {{text = "Hello", type = "TEXT"}},
            vrHelpTitle = "Options",
            vrHelp = {{position = 1, text = "OK"}}
        }
    )

    EXPECT_HMICALL("UI.SetGlobalProperties"):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_HMICALL("TTS.SetGlobalProperties"):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_RESPONSE(correlation_id, iap2bt_mobileSession, {success = true, resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnHashChange", iap2bt_mobileSession)
end

Test["Adding button subscription"] =
    function()
    local correlation_id = iap2bt_mobileSession:SendRPC("SubscribeButton", {buttonName = "PRESET_0"})

    EXPECT_HMINOTIFICATION(
        "Buttons.OnButtonSubscription",
        {
            isSubscribed = true,
            name = "PRESET_0"
        }
    )

    EXPECT_RESPONSE(correlation_id, iap2bt_mobileSession, {success = true, resultCode = "SUCCESS"})

    EXPECT_NOTIFICATION("OnHashChange", iap2bt_mobileSession)
end

Test["Adding vehicle info subsription"] =
    function(self)
    local correlation_id = iap2bt_mobileSession:SendRPC("SubscribeVehicleData", {odometer = true})
    EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData"):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )
    EXPECT_RESPONSE(correlation_id, iap2bt_mobileSession, {success = true, resultCode = "SUCCESS"})
end

Test["Adding regular file"] = function(self)
    AddFileForApplication(iap2bt_mobileSession, put_file_name, "JSON")
end

Test["Adding application icon"] =
    function(self)
    AddFileForApplication(iap2bt_mobileSession, icon_file_name, "GRAPHIC_PNG")

    local correlation_id = iap2bt_mobileSession:SendRPC("SetAppIcon", {syncFileName = icon_file_name})

    EXPECT_HMICALL("UI.SetAppIcon"):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_RESPONSE(correlation_id, iap2bt_mobileSession, {resultCode = "SUCCESS", success = true})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

local isChoiceRemoved = false
local isCommandRemoved = false

Test["Connecting iAP2 USB"] =
    function(self)
    -- iAP2 USB connection with same application
    local iap2usb_device = createIAP2Device(iAP2_USB_DeviceID, iAP2_USB_Port, iAP2_USB_out)

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered"):Times(0)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered"):Times(0)

    EXPECT_HMICALL(
        "BasicCommunication.UpdateDeviceList",
        {
            -- To check why two devices are in list, maybe an issue
            deviceList = {
                {id = config.deviceMAC, name = iAP2_BT_DeviceID, transportType = iAP2_BT_Type},
                {id = config.deviceMAC, name = iAP2_USB_DeviceID, transportType = iAP2_USB_Type}
            }
        }
    ):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

            -- Disconnect Bluetooth connection
            iap2bt_device:Close()
        end
    )

    Test:connectMobile(iap2usb_device)

    local iap2usb_mobileSession = mobile_session.MobileSession(self, iap2usb_device, app_RAI_params)

    local rpc_service_id = 7
    iap2usb_mobileSession:StartService(rpc_service_id):Do(
        function()
            app_RAI_params.hashID = "some_wrong_hash_id"
            local correlation_id = iap2usb_mobileSession:SendRPC("RegisterAppInterface", app_RAI_params)
            iap2usb_mobileSession:ExpectResponse(correlation_id, {success = true, resultCode = "RESUME_FAILED"})
        end
    )

    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints"):Do(
        function(_, data)
            commonFunctions:userPrint(light_cyan_color, "Unsubscribed from waypoints")
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_HMICALL(
        "UI.DeleteCommand",
        {
            cmdID = 1
        }
    ):Do(
        function(_, data)
            commonFunctions:userPrint(light_cyan_color, "UI commands removed")
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_HMICALL(
        "UI.DeleteSubMenu",
        {
            menuID = 11
        }
    ):Do(
        function(_, data)
            commonFunctions:userPrint(light_cyan_color, "Submenus removed")
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_HMICALL("VR.DeleteCommand"):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    ):ValidIf(
        function(_, data)
            if data.params["type"] == "Choice" then
                commonFunctions:userPrint(light_cyan_color, "Choices removed")
                isChoiceRemoved = true
            end
            if data.params["type"] == "Command" then
                commonFunctions:userPrint(light_cyan_color, "VR command removed")
                isCommandRemoved = true
            end

            return true
        end
    ):Times(AtLeast(1))

    EXPECT_HMICALL(
        "UI.SetGlobalProperties",
        {
            -- TODO: add more parameters to check
            keyboardProperties = {
                keyboardLayout = "QWERTY",
                language = "EN-US"
            },
            vrHelpTitle = "Test Application"
        }
    ):Do(
        function(_, data)
            commonFunctions:userPrint(light_cyan_color, "UI global properties removed")
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_HMICALL("TTS.SetGlobalProperties"):Do(
        function(_, data)
            commonFunctions:userPrint(light_cyan_color, "TTS global properties removed")
            -- TODO: add more parameters to check
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {isSubscribed = false, name = "PRESET_0"}):Times(1):Do(
        function(_, data)
            commonFunctions:userPrint(light_cyan_color, "Buttons subscriptions removed")
        end
    )

    EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData", {odometer = true}):Do(
        function(_, data)
            commonFunctions:userPrint(light_cyan_color, "Vehicle data subscriptions removed")
            self.hmiConnection:SendResponse(
                data.id,
                data.method,
                "SUCCESS",
                {odometer = {resultCode = "SUCCESS", dataType = "VEHICLEDATA_ODOMETER"}}
            )
        end
    )
end

Test["Verifying choice/command expectations"] = function(self)
    if true ~= isChoiceRemoved then
        Test:FailTestCase("Choice hasn't been removed")
    end

    if true ~= isCommandRemoved then
        Test:FailTestCase("Command hasn't been removed")
    end
end

Test["Verifying file(s) existence after clean-up"] = function(self)
    -- Icon must be preserved
    if true == isFileExisting(icon_file_name) then
        commonFunctions:userPrint(light_cyan_color, "File '" .. icon_file_name .. "' is preserved as expected")
    else
        Test:FailTestCase("File '" .. icon_file_name .. "' is removed")
    end

    -- Other file(s) must be removed
    if true ~= isFileExisting(put_file_name) then
        commonFunctions:userPrint(light_cyan_color, "File '" .. put_file_name .. "' is removed")
    else
        Test:FailTestCase("File '" .. put_file_name .. "' is not removed")
    end
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test:StopSDL()
    StopSDLAndRestorePT()
end

return Test
