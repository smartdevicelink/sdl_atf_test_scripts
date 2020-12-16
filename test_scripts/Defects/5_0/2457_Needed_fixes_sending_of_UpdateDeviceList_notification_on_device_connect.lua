---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2457
--
-- Description:
-- Steps to reproduce:
-- 1) HMI and SDL started, connect device
-- Expected:
-- 1) SDL has to notify system with BC.UpdateDeviceList on device connect
-- even if device does not have any SDL-enabled applications running
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require ('user_modules/utils')
local SDL = require("SDL")
local hmi_values = require('user_modules/hmi_values')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local hmiParams = hmi_values.getDefaultHMITable()
hmiParams.BasicCommunication.UpdateDeviceList = nil
local mobDeviceParams = { host = config.mobileHost, port = config.mobilePort }
local devices = {
  web_engine = {
    id = utils.buildDeviceMAC("WS"),
    name = utils.buildDeviceName("WS"),
    transportType = "WEBENGINE_WEBSOCKET"
  },
  mobile = {
    id = utils.buildDeviceMAC("TCP", mobDeviceParams),
    name = utils.buildDeviceName("TCP", mobDeviceParams),
    transportType = "WIFI"
  }
}
-- [[ Local Functions ]]
local function start ()
  local exp = {}
  if SDL.buildOptions.webSocketServerSupport == "OFF" then
    table.insert(exp, { deviceList = { [1] = devices.mobile } })
  else
    table.insert(exp, { deviceList = { [1] = devices.web_engine } })
  end
  if SDL.buildOptions.webSocketServerSupport == "ON" and config.defaultMobileAdapterType == "TCP" then
    table.insert(exp, { deviceList = { [1] = devices.web_engine, [2] = devices.mobile } })
  end
  common.start(hmiParams)
  common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateDeviceList", table.unpack(exp))
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(#exp)
  common.getHMIConnection():ExpectRequest("BasicCommunication.OnDeviceAdded")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Start SDL, HMI, connect Mobile", start)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
