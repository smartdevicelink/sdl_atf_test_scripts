---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item:
--
-- Description:
-- In case:
-- HMI respond with available = true on RC.IsReady request from SDL
-- and HMI didn't respond on capabilities request from SDL
--
-- SDL must:
-- Use default capabiltites during ignition cycle stored in HMI_capabilities.json file
-- Process RC-related RPCs
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')
local hmi_values = require('user_modules/hmi_values')
local initialCommon = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local disabledModule = "CLIMATE"
local enabledModule = "SEAT"

--[[ Local Functions ]]
local function getHMIParams()
  local params = hmi_values.getDefaultHMITable()
  params.RC.IsReady.params.available = true
  params.RC.GetCapabilities = nil
  return params
end

local function rpcUnsupportedResource(pModuleType, pRPC)
  local pAppId = 1
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), initialCommon.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
end

local function rpcSuccess(pModuleType, pRPC)
  local pAppId = 1
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), initialCommon.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), initialCommon.getHMIRequestParams(pRPC, pModuleType, pAppId))
  :Do(function(_, data)
      commonRC.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", initialCommon.getHMIResponseParams(pRPC, pModuleType))
    end)
  mobSession:ExpectResponse(cid, initialCommon.getAppResponseParams(pRPC, true, "SUCCESS", pModuleType))
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Update HMI capabilities file", commonRC.updateDefaultCapabilities, { { disabledModule } })
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { getHMIParams() })
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test - Module enabled: " .. enabledModule .. ", disabled: " .. disabledModule)
runner.Step("GetInteriorVehicleData_UNSUPPORTED_RESOURCE", rpcUnsupportedResource,
      { disabledModule, "GetInteriorVehicleData" })
runner.Step("SetInteriorVehicleData_UNSUPPORTED_RESOURCE", rpcUnsupportedResource,
      { disabledModule, "SetInteriorVehicleData" })
runner.Step("GetInteriorVehicleData_SUCCESS", rpcSuccess, { enabledModule, "GetInteriorVehicleData" })
runner.Step("SetInteriorVehicleData_SUCCESS", rpcSuccess, { enabledModule, "SetInteriorVehicleData" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
