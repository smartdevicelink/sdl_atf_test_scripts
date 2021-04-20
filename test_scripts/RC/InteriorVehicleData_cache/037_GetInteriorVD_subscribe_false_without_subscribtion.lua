---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. Mobile app1 is not subscribed to module_1
-- 2. Mobile app1 sends GetInteriorVD(module_1, subscribe = false) request
-- 3. Mobile app1 is subscribed to module_1
-- 4. Mobile app2 sends GetInteriorVD(module_1, subscribe = false) request
-- SDL must
-- 1. send GetInteriorVD(module_1) request without subscribe parameter to HMI by processing GetInteriorVD(module_1, subscribe = false) from app1
-- 2. respond GetInteriorVD(module_1, subscribe = false) to mobile app
-- 3. not send GetInteriorVD(module_1) request to HMI by processing GetInteriorVD(module_1, subscribe = false) from app2
-- 4. respond GetInteriorVD(module_1, subscribe = false) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Functions]]
local function GetInteriorVehicleData(pModuleType, isSubscribe)
  local rpc = "GetInteriorVehicleData"
  local subscribe = isSubscribe
  local mobSession = common.getMobileSession(1)
  local cid = mobSession:SendRPC(common.getAppEventName(rpc),
    common.getAppRequestParams(rpc, pModuleType, subscribe))
  local hmiRequestParams = common.getHMIRequestParams(rpc, pModuleType, 1, subscribe)
  hmiRequestParams.subscribe = nil
  EXPECT_HMICALL(common.getHMIEventName(rpc), hmiRequestParams)
  :Do(function(_, data)
	    local hmiResponseParams = common.getHMIResponseParams(rpc, pModuleType, subscribe)
	    hmiResponseParams.subscribe = nil
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseParams)
    end)
  :ValidIf(function(_, data)
      if data.params.subscribe then
        return false, "RC.GetInteriorVehicleData request contains unexpected 'subscribe' parameter"
      end
      return true
    end)
  mobSession:ExpectResponse(cid, common.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, subscribe))
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app1", common.registerAppWOPTU, { 1 })
runner.Step("Register app2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app1", common.activateApp, { 1 })
runner.Step("Activate app2", common.activateApp, { 2 })

runner.Title("Test")

for _, mod in pairs(common.modules) do
  runner.Step("App1 GetInteriorVehicleData with subscribe=false without subscription" .. mod, GetInteriorVehicleData,
    { mod, false })
  runner.Step("App1 GetInteriorVehicleData with subscribe=true " .. mod, common.GetInteriorVehicleData,
    { mod, true, true, 1 })
  runner.Step("App2 GetInteriorVehicleData with subscribe=false in case cache is available" .. mod, common.GetInteriorVehicleData,
    { mod, false, false, 2 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
