---------------------------------------------------------------------------------------------------
--  Requirement summary:
--  TBD
--
--  Description:
--  iAP2 Bluetooth connection is switched to iAP2 USB connection automatically, application(s) remains registered,
--  but application(s) sends wrong hashID or it's absent
--
--  1. Used precondition
--  SDL is built with BUILD_TEST = ON to enable iAP2 BT/USB transport adapter emulation
--  SDL, HMI are running on system.
--
--  2. Performed steps
--  iAP2 Bluetooth mobile device connects to system
--  appID_1->RegisterAppInterface(params)
--  RAI response is SUCCESS
--  application sends SubscribeButton for PRESET_0 button (resume data)
--  SDL sends OnHashChange to application
--
--  same iAP2 mobile device is connected over USB to system and re-registers within AppTransportChangeTimer timeout
--  appID_1->RegisterAppInterface(params), but with wrong hashID
--
--  Expected behavior:
--  1. SDL successfully registers application and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--     SDL->appID: SUCCESS, success:"true": SubscribeButtons()
--     SDL->appID: OnHashChange
--
--  2. SDL successfully registers application and notifies mobile only with RAI response
--     SDL->appID: RESUME_FAILED, success:"true":RegisterAppInterface()
--     application remains registered internally
--     application does not send OnAppUnregistered notification to HMI
--     application does not send OnAppRegistered notification to HMI
--     SDL->HMI: Buttons.OnButtonSubscription, isSubscribed = false, name = PRESET_0
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/iAP2TransportSwitch/common')
local mobSession = require("mobile_session")

--[[ Conditions to skip test ]]
if config.defaultMobileAdapterType ~= "TCP" then
  runner.skipTest("Test is applicable only for TCP connection")
end

--[[ Local Variables ]]
local deviceBluetooth
local sessionBluetooth

--[[ Local Functions ]]
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

local function addDataForResumption()
  local cid = sessionBluetooth:SendRPC("SubscribeButton", { buttonName = "PRESET_0" })
  EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {
    isSubscribed = true,
    name = "PRESET_0"
  })
  sessionBluetooth:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  sessionBluetooth:ExpectNotification("OnHashChange")
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

  EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", { isSubscribed = false, name = "PRESET_0" })

  self:waitForAllEvents(2000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI", common.start)

runner.Title("Test")
runner.Step("Connect Bluetooth Device", connectBluetoothDevice)
runner.Step("Add Data for Resumption", addDataForResumption)
runner.Step("Connect USB Device", connectUSBDevice)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
