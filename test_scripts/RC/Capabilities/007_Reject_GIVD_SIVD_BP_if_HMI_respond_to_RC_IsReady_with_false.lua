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
local hmi_values = require('user_modules/hmi_values')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function getHMIParams()
  local params = hmi_values.getDefaultHMITable()
  params.RC.IsReady.params.available = false
  params.RC.GetCapabilities.params = { }
  params.RC.GetCapabilities.occurrence = 0
  return params
end

local function rpcUnsupportedResource(pModuleType, pRPC, self)
  local pAppId = 1
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { getHMIParams() })
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Title("Module: " .. mod)
  runner.Step("GetInteriorVehicleData", rpcUnsupportedResource, { mod, "GetInteriorVehicleData" })
  runner.Step("SetInteriorVehicleData", rpcUnsupportedResource, { mod, "SetInteriorVehicleData" })
  runner.Step("ButtonPress", rpcUnsupportedResource, { mod, "ButtonPress" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
