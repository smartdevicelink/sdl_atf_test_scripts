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
-- 2) HMI sends statusAvailable = true for light_value in capabilities
-- 3) Application requests SetInteriorVehicleData RPC with light_value and status = "RAMP_UP"/"RAMP_DOWN"/"UNKNOWN"/ "INVALID"
-- SDL must:
-- 1) Reject such request with READ_ONLY result code, and info="The LightStatus enum passed is READ ONLY and cannot be written."
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local Module = "LIGHT"

--[[ Local Functions ]]
local function setInteriorVDunsupportedResource(pStatus, pSupportedParam)
  local requestParams = common.getAppRequestParams("SetInteriorVehicleData", Module)
  requestParams.moduleData.lightControlData.lightState[1].status = pStatus
  if pSupportedParam then
    local supportedValue = {
      id = "REAR_CARGO_LIGHTS",
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
    resultCode = "READ_ONLY",
    info = "The LightStatus enum passed is READ ONLY and cannot be written."
  }
  common.rpcUnsuccessResultCode(1, "SetInteriorVehicleData", requestParams, result )
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, value in pairs (common.readOnlyLightStatus) do
  runner.Step("SetInteriorVehicleData READ_ONLY with only read only value",
    setInteriorVDunsupportedResource, { value })
  runner.Step("SetInteriorVehicleData READ_ONLY with read only and settable values",
    setInteriorVDunsupportedResource, { value, true })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
