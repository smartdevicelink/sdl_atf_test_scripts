---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Capabilities
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
local commonRC = require('test_scripts/RC/commonRC')
local hmi_values = require('user_modules/hmi_values')

--[[ Local Variables ]]
local disabledModule = "RADIO"
local enabledModule = "CLIMATE"

--[[ Local Functions ]]
local function getHMIParams()
  local params = hmi_values.getDefaultHMITable()
  params.RC.IsReady.params.available = true
  params.RC.GetCapabilities = nil
  return params
end

local function rpcUnsupportedResource(pModuleType, pRPC, self)
  local pAppId = 1
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
end

local function rpcSuccess(pModuleType, pRPC, self)
  local pAppId = 1
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), commonRC.getHMIRequestParams(pRPC, pModuleType, pAppId))
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(pRPC, pModuleType))
    end)
  mobSession:ExpectResponse(cid, commonRC.getAppResponseParams(pRPC, true, "SUCCESS", pModuleType))
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Update HMI capabilities file", commonRC.updateDefaultCapabilities, { disabledModule })
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { getHMIParams() })
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test - Module enabled: " .. enabledModule .. ", disabled: " .. disabledModule)

runner.Step("GetInteriorVehicleData_UNSUPPORTED_RESOURCE", rpcUnsupportedResource, { disabledModule, "GetInteriorVehicleData" })
runner.Step("SetInteriorVehicleData_UNSUPPORTED_RESOURCE", rpcUnsupportedResource, { disabledModule, "SetInteriorVehicleData" })
runner.Step("ButtonPress_UNSUPPORTED_RESOURCE", rpcUnsupportedResource, { disabledModule, "ButtonPress" })

runner.Step("GetInteriorVehicleData_SUCCESS", rpcSuccess, { enabledModule, "GetInteriorVehicleData" })
runner.Step("SetInteriorVehicleData_SUCCESS", rpcSuccess, { enabledModule, "SetInteriorVehicleData" })
runner.Step("ButtonPress_SUCCESS", rpcSuccess, { enabledModule, "ButtonPress" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
