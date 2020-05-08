---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/1
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/detailed_info_GetSystemCapability.md
-- Item: Use Case 1: Alternative flow 1
--
-- Requirement summary:
-- [SDL_RC] Capabilities
--
-- Description:
-- In case:
-- HMI respond with available = false on RC.IsReady request from SDL
--
-- SDL must:
-- Do not send RC.GetCapabilities request to HMI
-- Reject all RPCs from mobile application to such interface with result code UNSUPPORTED_RESOURCE, success:false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getHMIParams()
  local params = commonRC.getDefaultHMITable()
  params.RC.IsReady.params.available = false
  params.RC.GetCapabilities.params = { }
  params.RC.GetCapabilities.occurrence = 0
  return params
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { getHMIParams() })
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

for _, mod in pairs(commonRC.modules)  do
  runner.Title("Module: " .. mod)
  runner.Step("GetInteriorVehicleData_UNSUPPORTED_RESOURCE", commonRC.rpcDenied,
  { mod, 1, "GetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })
runner.Step("SetInteriorVehicleData_UNSUPPORTED_RESOURCE", commonRC.rpcDenied,
  { mod, 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })
runner.Step("ButtonPress_UNSUPPORTED_RESOURCE", commonRC.rpcDenied,
  { mod, 1, "ButtonPress", "UNSUPPORTED_RESOURCE" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
