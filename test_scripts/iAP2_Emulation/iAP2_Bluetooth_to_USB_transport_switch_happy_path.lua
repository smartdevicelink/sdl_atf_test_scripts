--  Requirement summary:
--  TBD
--
--  Description:
--  iAP2 Bluetooth connection is switched to iAP2 USB connection automatically, application(s) remains registered
--
--  1. Used precondition
--  SDL is built with BUILD_TEST = ON to enable iAP2 BT/USB transport adapter emulation
--  SDL, HMI are running on system.
--
--  2. Performed steps
--  iAP2 Bluetooth mobile device connects to system
--  appID_1->RegisterAppInterface(params)
--  RAI response is SUCCESS
--
--  same iAP2 mobile device is connected over USB to system and re-registers within AppTransportChangeTimer timeout
--  appID_1->RegisterAppInterface(params)
--
--  Expected behavior:
--  1. SDL successfully registers application and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--
--  2. SDL successfully registers application and notifies mobile only with RAI response
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--     application remains registered internally
--     application does not send OnAppUnregistered notification to HMI
--     application does not send OnAppRegistered notification to HMI

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

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

local function createIAP2Device(deviceID, devicePort, deviceOut)
    local iap2Connection = tcp.Connection(deviceID, devicePort)
    local fileConnection = file_connection.FileConnection(deviceOut, iap2Connection)
    local iap2Device = mobile.MobileConnection(fileConnection)

    event_dispatcher:AddConnection(iap2Device)

    return iap2Device
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

local iap2bt_device = 0

Test["Connecting iAP2 Bluetooth"] =
    function(self)
    -- iAP2 Bluetooth connection with application registered
    iap2bt_device = createIAP2Device(iAP2_BT_DeviceID, iAP2_BT_Port, iAP2_BT_out)

    EXPECT_HMICALL(
        "BasicCommunication.UpdateDeviceList",
        {
            deviceList = {{id = config.deviceMAC, name = iAP2_BT_DeviceID, transportType = iAP2_BT_Type}}
        }
    ):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
    )

    Test:connectMobile(iap2bt_device)

    local iap2bt_mobileSession = mobile_session.MobileSession(self, iap2bt_device, app_RAI_params)

    Test:startSession(iap2bt_mobileSession)
end

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
            local correlationId = iap2usb_mobileSession:SendRPC("RegisterAppInterface", app_RAI_params)
            iap2usb_mobileSession:ExpectResponse(correlationId, {success = true, resultCode = "SUCCESS"})
        end
    )
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test:StopSDL()
    StopSDLAndRestorePT()
end

return Test
