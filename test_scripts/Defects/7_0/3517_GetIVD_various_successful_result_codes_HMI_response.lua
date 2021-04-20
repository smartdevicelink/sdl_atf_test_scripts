---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_core/issues/3517
---------------------------------------------------------------------------------------------------
-- Steps:
-- 1. RC App subscribes to InteriorVehicleData by sending GetIVD request with subscribe=true
-- 2. SDL transfers this request to HMI
-- 3. HMI responds with any <successful> resultCode:
--   "SUCCESS", "WARNINGS", "RETRY", "SAVED", "WRONG_LANGUAGE"
--
-- Expected:
-- SDL processes requests as successful
-- SDL sends OnHashChange to mobile App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local rc = require('user_modules/sequences/remote_control')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Apps Configuration ]]
common.app.getParams().appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local successCodes = { "SUCCESS", "WARNINGS", "RETRY", "SAVED", "WRONG_LANGUAGE" }
local moduleType = "RADIO"
local moduleId = rc.predefined.getRcCapabilities()[moduleType][1].moduleInfo.moduleId

--[[ Local Functions ]]
local function pTUfunc(tbl)
  local appPolicies = tbl.policy_table.app_policies
  local index = common.app.getParams().fullAppID
  appPolicies[index].groups = { "Base-4", "RemoteControl" }
  appPolicies[index].moduleType = { moduleType }
end

local function getInteriorVehicleData(pResponseResultCode)
  local appId = 1
  local subscribe = true
  local rpc = "GetInteriorVehicleData"
  local mobSession = common.mobile.getSession()
  local hmi = common.hmi.getConnection()
  local appReq = rc.rpc.getAppRequestParams(rpc, moduleType, moduleId, subscribe)
  local hmiReq = rc.rpc.getHMIRequestParams(rpc, moduleType, moduleId, appId, subscribe)
  local hmiRes = rc.rpc.getHMIResponseParams(rpc, moduleType, moduleId, subscribe)
  local appRes = rc.rpc.getAppResponseParams(rpc, true, pResponseResultCode, moduleType, moduleId, subscribe)
  local cid = mobSession:SendRPC(rc.rpc.getAppEventName(rpc), appReq)
  hmi:ExpectRequest(rc.rpc.getHMIEventName(rpc), hmiReq)
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, pResponseResultCode, hmiRes)
    end)
  mobSession:ExpectResponse(cid, appRes)
  mobSession:ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.app.register)
runner.Step("PTU", common.ptu.policyTableUpdate, { pTUfunc })
runner.Step("Unregister App", common.app.unRegister)

runner.Title("Test")
for _, code in pairs(successCodes) do
  runner.Title("HMI response " .. code)
  runner.Step("Register App", common.app.registerNoPTU)
  runner.Step("Activate App", common.app.activate)
  runner.Step("GetInteriorVehicleData", getInteriorVehicleData, { code })
  runner.Step("Unregister App", common.app.unRegister)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
