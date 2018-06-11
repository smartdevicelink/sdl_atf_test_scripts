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
-- 2) HMI sends statusAvailable = false for light_value
-- 3) Application requests SetInteriorVehicleData RPC with light_value
-- SDL must:
-- 1) Reject such request with READ_ONLY result code
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local Module = "LIGHT"

--[[ Local Functions ]]
local function setStatusAvailableFalse()
  local lightParams = common.getModuleControlData(Module)
  local lightName = lightParams.lightControlData.lightState[1].id
  local hmiValues = hmi_values.getDefaultHMITable()
  for _, value in pairs (hmiValues.RC.GetCapabilities.params.remoteControlCapability.lightControlCapabilities.supportedLights) do
	if value.name == lightName then
      value.statusAvailable = false
     end
  end
  return hmiValues
end

local function setInteriorVDreadOnly()
  local requestParams = common.getAppRequestParams("SetInteriorVehicleData", Module)
  local result = { success = false, resultCode = "READ_ONLY" }
  common.rpcUnsuccessResultCode(1, "SetInteriorVehicleData", requestParams, result )
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { setStatusAvailableFalse() })
runner.Step("RAI, PTU", common.raiPTUn)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetInteriorVehicleData READ_ONLY", setInteriorVDreadOnly)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
