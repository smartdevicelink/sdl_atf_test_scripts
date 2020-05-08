---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/1
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/detailed_info_GetSystemCapability.md
-- Item: Use Case 1:Exception 3.3
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) SDL receive several supported Radio parameters in GetCapabilites response and
-- 2) App sends RC RPC request with several supported by HMI parameters and some unssuported
-- SDL must:
-- 1) Reject such request with UNSUPPORTED_RESOURCE result code, success: false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local moduleId = commonRC.getModuleId("CLIMATE")
local climate_capabilities = {{
  moduleName = "Climate",
  moduleInfo = {
    moduleId = moduleId
  },
  fanSpeedAvailable = true,
  acEnableAvailable = true,
  acMaxEnableAvailable = true
}}
local capParams = {}
capParams.CLIMATE = climate_capabilities
capParams.RADIO = commonRC.DEFAULT
capParams.BUTTONS = commonRC.DEFAULT
local rc_capabilities = commonRC.buildHmiRcCapabilities(capParams)
local climate_params =
{
  moduleType = "CLIMATE",
  moduleId = moduleId,
  climateControlData =
  {
    fanSpeed = 30,
    acEnable = true,
    acMaxEnable = true,
    circulateAirEnable = true -- unsupported parameter
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, {rc_capabilities})
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate_App", commonRC.activateApp)

runner.Title("Test")
for _, module_name in pairs({"CLIMATE", "RADIO"}) do
    runner.Step("GetInteriorVehicleData for " .. module_name, commonRC.subscribeToModule, {module_name, 1})
    runner.Step("ButtonPress for " .. module_name, commonRC.rpcAllowed, {module_name, 1, "ButtonPress"})
end
runner.Step("SetInteriorVehicleData rejected if at least one prameter unsuported", commonRC.rpcDeniedWithCustomParams,
  { climate_params, 1, "SetInteriorVehicleData", resultCode = "UNSUPPORTED_RESOURCE"})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
