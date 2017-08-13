---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Capabilities
--
-- Description:
-- In case:
-- HMI didn't respond on RC.IsReady request from SDL
-- and SDL send RC.GetCapabilities request to HMI
-- and HMI respond on this request with capabilities
--
-- SDL must:
-- Use these capabiltites during ignition cycle
-- Process RC-related RPCs accordingly
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local disabledModule = "RADIO"
local enabledModule = "CLIMATE"

--[[ Local Functions ]]
local function getHMIParams()
  local function getHMICapsParams()
    if enabledModule == "CLIMATE" then
      return { commonRC.DEFAULT, nil, commonRC.DEFAULT }
    elseif enabledModule == "RADIO" then
      return { nil, commonRC.DEFAULT, commonRC.DEFAULT }
    end
  end
  local hmiCaps = commonRC.buildHmiRcCapabilities(unpack(getHMICapsParams()))
  hmiCaps.RC.IsReady = nil
  local buttonCaps = hmiCaps.RC.GetCapabilities.params.remoteControlCapability.buttonCapabilities
  local buttonId = commonRC.getButtonIdByName(buttonCaps, commonRC.getButtonNameByModule(disabledModule))
  table.remove(buttonCaps, buttonId)
  return hmiCaps
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
runner.Step("Update HMI capabilities file", commonRC.updateDefaultCapabilities, { enabledModule })
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
