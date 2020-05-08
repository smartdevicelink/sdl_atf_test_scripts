---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Verify that the SDL does not establish WebSocket-Secure connection in case of WS Server Certificate
--  does not define in SmartDeviceLink.ini file
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. Create WebSocket-Secure connection
--  a. SDL does not establish WebSocket-Secure connection
---------------------------------------------------------------------------------------------------
--[[ General test configuration ]]
config.defaultMobileAdapterType = "WSS"

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/WebEngine/commonWebEngine')
local hmi_values = require('user_modules/hmi_values')

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = {{webSocketServerSupport = {"ON"}}}

--[[ Local Variables ]]
local sslParametersServer = {
  "WSServerCertificatePath",
  "WSServerKeyPath",
  "WSServerCACertificatePath"
}
local hmiValues = hmi_values.getDefaultHMITable()
hmiValues.BasicCommunication.UpdateDeviceList.occurrence = 0

--[[ Local Functions ]]
local function addAllCertInIniFile(pCertName)
  common.addAllCertInIniFile()
  common.setSDLIniParameter(pCertName, ";")
end

--[[ Scenario ]]
for _, value  in ipairs(sslParametersServer) do
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Update WS Server Certificate parameters in smartDeviceLink.ini file", addAllCertInIniFile,
    { value })
  runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.startWOdeviceConnect, { hmiValues })

  runner.Title("Test")
  runner.Step("Connect WebEngine device", common.connectWSSWebEngine)

  runner.Title("Postconditions")
  runner.Step("Stop SDL", common.postconditions)
end
