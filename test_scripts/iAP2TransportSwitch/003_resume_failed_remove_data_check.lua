---------------------------------------------------------------------------------------------------
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
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/iAP2TransportSwitch/common')
local mobSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Conditions to skip test ]]
if config.defaultMobileAdapterType ~= "TCP" then
  runner.skipTest("Test is applicable only for TCP connection")
end

--[[ Local Variables ]]
local deviceBluetooth
local sessionBluetooth
local isChoiceRemoved = false
local isCommandRemoved = false
local putFileName = "file.json"
local iconFileName = "icon.png"

--[[ Local Functions ]]
local function isFileExisting(pFileName)
  local device_id = "ac355aa5275c7388743f1bd27761ab5fa79ec876927347b97bd6e0361ae04699"
  return commonFunctions:File_exists(config.pathToSDL .. "storage/" .. common.appParams.fullAppID
    .. "_" .. device_id .. "/" .. pFileName)
end

local function AddFileForApplication(session, pFileName, file_type, self)
  local cid = session:SendRPC("PutFile", {
      syncFileName = pFileName,
      fileType = file_type,
      persistentFile = false,
      systemFile = false
    },
    "files/" .. pFileName)
  session:ExpectResponse(cid, { success = true })
  :Do(function()
      if true ~= isFileExisting(pFileName) then
        self:FailTestCase("File '" .. pFileName .. "' is not found")
      end
   end)
end

local function connectBluetoothDevice(self)
  deviceBluetooth = self:createIAP2Device(common.device.bluetooth.id,
    common.device.bluetooth.port, common.device.bluetooth.out)

  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", {
    deviceList = common.getUpdatedDeviceList({
      {
        id = config.deviceMAC,
        name = common.device.bluetooth.uid,
        transportType = common.device.bluetooth.type
      }
    })
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  self:connectMobile(deviceBluetooth)
  :Do(function()
      sessionBluetooth = mobSession.MobileSession(self, deviceBluetooth, common.appParams)
      sessionBluetooth:StartService(7)
      :Do(function()
          local cid = sessionBluetooth:SendRPC("RegisterAppInterface", common.appParams)
          sessionBluetooth:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end)

      EXPECT_HMICALL("BasicCommunication.UpdateAppList")
      :Do(function(_, data)
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
        end)
      EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {
        isSubscribed = true,
        name = "CUSTOM_BUTTON"
      })
    end)
end

local function addCommand(self)
  local cid = sessionBluetooth:SendRPC("AddCommand", {
    cmdID = 1,
    menuParams = {
      position = 0,
      menuName = "Command"
    },
    vrCommands = {
      "VRCommandonepositive"
    }
  })

  EXPECT_HMICALL("UI.AddCommand", {
    cmdID = 1,
    menuParams = {
      position = 0,
      menuName = "Command"
    }
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  EXPECT_HMICALL("VR.AddCommand", {
    cmdID = 1,
    type = "Command",
    vrCommands = {
      "VRCommandonepositive"
    }
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  sessionBluetooth:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  sessionBluetooth:ExpectNotification("OnHashChange")
end

local function addSubmenu(self)
  local id = 11
  local cid = sessionBluetooth:SendRPC("AddSubMenu", {
    menuID = id,
    menuName = "SubMenumandatoryonly"
  })
  EXPECT_HMICALL("UI.AddSubMenu", {
    menuID = id,
    menuParams = {
      menuName = "SubMenumandatoryonly"
    }
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  sessionBluetooth:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  sessionBluetooth:ExpectNotification("OnHashChange")
end

local function addChoiceSet(self)
  local id = 123
  local cid = sessionBluetooth:SendRPC("CreateInteractionChoiceSet", {
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
  })
  EXPECT_HMICALL("VR.AddCommand", {
    cmdID = id,
    type = "Choice",
    vrCommands = {
      "VRChoice" .. id
    }
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  sessionBluetooth:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  sessionBluetooth:ExpectNotification("OnHashChange")
end

local function addGlobalProperties(self)
  local cid = sessionBluetooth:SendRPC("SetGlobalProperties", {
    helpPrompt = {
      {
        text = "Speak",
        type = "TEXT"
      }
    },
    timeoutPrompt = {
      {
        text = "Hello",
        type = "TEXT"
      }
    },
    vrHelpTitle = "Options",
    vrHelp = {
      {
        position = 1,
        text = "OK"
      }
    }
  })
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  EXPECT_HMICALL("TTS.SetGlobalProperties")
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  sessionBluetooth:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  sessionBluetooth:ExpectNotification("OnHashChange")
end

local function addButtonSubscription(self)
  local cid = sessionBluetooth:SendRPC("SubscribeButton", { buttonName = "PRESET_0" })
  EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", { isSubscribed = true, name = "PRESET_0" })
  sessionBluetooth:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  sessionBluetooth:ExpectNotification("OnHashChange")
end

local function addVehicleInfoSubscription(self)
  local cid = sessionBluetooth:SendRPC("SubscribeVehicleData", { odometer = true })
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        odometer = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_ODOMETER" }
      })
    end)
  sessionBluetooth:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function addWayPointsSubsription(self)
  local cid = sessionBluetooth:SendRPC("SubscribeWayPoints", { })
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  sessionBluetooth:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  sessionBluetooth:ExpectNotification("OnHashChange")
end

local function addRegularFile(self)
  AddFileForApplication(sessionBluetooth, putFileName, "JSON", self)
end

local function addApplicationIcon(self)
  AddFileForApplication(sessionBluetooth, iconFileName, "GRAPHIC_PNG", self)
  local cid = sessionBluetooth:SendRPC("SetAppIcon", { syncFileName = iconFileName })
  EXPECT_HMICALL("UI.SetAppIcon")
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  sessionBluetooth:ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
end

local function connectUSBDevice(self)
  local deviceUsb = self:createIAP2Device(common.device.usb.id,
    common.device.usb.port, common.device.usb.out)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered"):Times(0)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered"):Times(0)
  EXPECT_HMICALL("BasicCommunication.UpdateAppList"):Times(0)

  local is_switching_done = false

  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", {
    deviceList = common.getUpdatedDeviceList({
      {
        id = config.deviceMAC,
        name = common.device.usb.uid,
        transportType = common.device.usb.type
      },
      {
        id = config.deviceMAC,
        name = common.device.bluetooth.uid,
        transportType = common.device.bluetooth.type
      }
    })
  },
  {
    deviceList = common.getUpdatedDeviceList({
      {
        id = config.deviceMAC,
        name = common.device.usb.uid,
        transportType = common.device.usb.type
      }
    })
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

      if not is_switching_done then
        self:doTransportSwitch(deviceBluetooth)
        is_switching_done = true
      else
        local sessionUsb = mobSession.MobileSession(self, deviceUsb, common.appParams)
        sessionUsb:StartService(7)
        :Do(function()
            common.appParams.hashID = "some_wrong_hash_id"
            local cid = sessionUsb:SendRPC("RegisterAppInterface", common.appParams)
            sessionUsb:ExpectResponse(cid, { success = true, resultCode = "RESUME_FAILED" })
          end)
      end

      return true
    end)
  :Times(2)

  self:connectMobile(deviceUsb)

  EXPECT_HMICALL("UI.DeleteCommand", { cmdID = 1 })
  :Do(function(_, data)
      common.print("UI commands removed")
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  EXPECT_HMICALL("UI.DeleteSubMenu", { menuID = 11 })
  :Do(function(_, data)
      common.print("Submenus removed")
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  EXPECT_HMICALL("VR.DeleteCommand")
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  :ValidIf(function(_, data)
      if data.params["type"] == "Choice" then
        common.print("Choices removed")
        isChoiceRemoved = true
      end
      if data.params["type"] == "Command" then
        common.print("VR command removed")
        isCommandRemoved = true
      end
      return true
    end)
  :Times(AtLeast(1))

  EXPECT_HMICALL("UI.SetGlobalProperties", {
  -- TODO: add more parameters to check
    keyboardProperties = {
      keyboardLayout = "QWERTY",
      language = "EN-US"
    }
  })
  :Do(function(_, data)
      common.print("UI global properties removed")
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  EXPECT_HMICALL("TTS.SetGlobalProperties")
  :Do(function(_, data)
      common.print("TTS global properties removed")
      -- TODO: add more parameters to check
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", { isSubscribed = false, name = "PRESET_0" })
  :Do(function()
      common.print("Buttons subscriptions removed")
    end)

  EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData", { odometer = true })
  :Do(function(_, data)
      common.print("Vehicle data subscriptions removed")
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        odometer = {
          resultCode = "SUCCESS",
          dataType = "VEHICLEDATA_ODOMETER"
        }
      })
    end)

  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Do(function(_, data)
      common.print("Unsubscribed from waypoints")
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  self:waitForAllEvents(2000)
end

local function verifyChoiceCommandExpectations(self)
  if true ~= isChoiceRemoved then
      self:FailTestCase("Choice hasn't been removed")
  end
  if true ~= isCommandRemoved then
    self:FailTestCase("Command hasn't been removed")
  end
end

local function verifyFilesExistenceAfterCleanUp(self)
  if true == isFileExisting(iconFileName) then
    common.print("File '" .. iconFileName .. "' is preserved as expected")
  else
      self:FailTestCase("File '" .. iconFileName .. "' is removed")
  end
  if true ~= isFileExisting(putFileName) then
    common.print("File '" .. putFileName .. "' is removed")
  else
    self:FailTestCase("File '" .. putFileName .. "' is not removed")
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI", common.start)

runner.Step("Connect Bluetooth Device", connectBluetoothDevice)
runner.Step("Add Command", addCommand)
runner.Step("Add Submenu", addSubmenu)
runner.Step("Add ChoiceSet", addChoiceSet)
runner.Step("Add GlobalProperties", addGlobalProperties)
runner.Step("Add ButtonSubscription", addButtonSubscription)
runner.Step("Add VehicleInfoSubscription", addVehicleInfoSubscription)
runner.Step("Add WayPointsSubsription", addWayPointsSubsription)
runner.Step("Add RegularFile", addRegularFile)
runner.Step("Add ApplicationIcon", addApplicationIcon)

runner.Title("Test")

runner.Step("Connect USB Device", connectUSBDevice)
runner.Step("Verify ChoiceCommandExpectations", verifyChoiceCommandExpectations)
runner.Step("Verify FilesExistenceAfterCleanUp", verifyFilesExistenceAfterCleanUp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
