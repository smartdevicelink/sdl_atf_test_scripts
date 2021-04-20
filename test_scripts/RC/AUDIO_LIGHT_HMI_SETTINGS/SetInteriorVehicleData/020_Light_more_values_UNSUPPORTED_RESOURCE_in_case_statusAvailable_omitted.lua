---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0165-rc-lights-more-names-and-status-values.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) Application is registered with REMOTE_CONTROL appHMIType
-- 2) HMI sends light_value without statusAvailable in capabilities
-- 3) Application requests SetInteriorVehicleData RPC with light_value
-- SDL must:
-- 1) respond with result code UNSUPPORTED_RESOURCE, and info="The requested parameter of the given LightName is not supported by the vehicle."
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local Module = "LIGHT"

--[[ Local Functions ]]
local function removeLightValueFromCapabilities()
  local lightParams = common.getModuleControlData(Module)
  local lightName = lightParams.lightControlData.lightState[1].id
  local hmiValues = common.getDefaultHMITable()
  for key, value in pairs (hmiValues.RC.GetCapabilities.params.remoteControlCapability.lightControlCapabilities.supportedLights) do
    if value.name == lightName then
      hmiValues.RC.GetCapabilities.params.remoteControlCapability.lightControlCapabilities.supportedLights[key].statusAvailable = nil
     end
  end
  return hmiValues
end

local function setInteriorVDunsupportedResource(pSupportedParam)
  local requestParams = common.getAppRequestParams("SetInteriorVehicleData", Module)
  if pSupportedParam then
    local supportedValue = {
      id = removeLightValueFromCapabilities().RC.GetCapabilities.params.remoteControlCapability.lightControlCapabilities.supportedLights[1].name,
      status = "ON",
      density = 0.5,
      sRGBColor = {
        red = 50,
        green = 50,
        blue = 50
      }
    }
    table.insert (requestParams.moduleData.lightControlData.lightState, supportedValue)
  end
  local result = {
    success = false,
    resultCode = "UNSUPPORTED_RESOURCE",
    info = "The requested parameter of the given LightName is not supported by the vehicle."
  }
  common.rpcUnsuccessResultCode(1, "SetInteriorVehicleData", requestParams, result )
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { removeLightValueFromCapabilities() })
runner.Step("RAI, PTU", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetInteriorVehicleData UNSUPPORTED_RESOURCE with only unsupported value", setInteriorVDunsupportedResource)
runner.Step("SetInteriorVehicleData UNSUPPORTED_RESOURCE with supported and unsupported values",
  setInteriorVDunsupportedResource, { true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
