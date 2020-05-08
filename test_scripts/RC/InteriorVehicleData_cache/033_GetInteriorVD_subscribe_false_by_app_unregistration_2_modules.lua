---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. Mobile app1 is subscribed to module_1
-- 2. Mobile app1 is subscribed to module_2
-- 3. Mobile app1 unregisters
-- SDL must
-- 1. send GetInteriorVD(module_1, subscribe = false) request to HMI
-- 2. send GetInteriorVD(module_2, subscribe = false) request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Function ]]
local function unregistrationApp()
  local rpc = "GetInteriorVehicleData"
  EXPECT_HMICALL(common.getHMIEventName(rpc))
  :Do(function(_, data)
      if data.params.moduleType == "CLIMATE" then
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        common.getHMIResponseParams(rpc, "CLIMATE", false))
      else
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        common.getHMIResponseParams(rpc, "RADIO", false))
      end
    end)
  :ValidIf(function(_, data)
      local ExpectedResult
      if data.params.moduleType == "CLIMATE" then
        ExpectedResult = common.getHMIRequestParams(rpc, "CLIMATE", 1, false)
      else
        ExpectedResult = common.getHMIRequestParams(rpc, "RADIO", 1, false)
      end
      if false == common.isTableEqual(data.params, ExpectedResult) then
        return false, "Parameters in RC.GetInteriorVehicleData are not match to expected result.\n" ..
          "Actual result:" .. common.tableToString(data.params) .. "\n" ..
          "Expected result:" ..common.tableToString(ExpectedResult) .."\n"
      end
      return true
    end)
  :Times(2)
  local mobSession = common.getMobileSession(1)
  local hmiAppId = common.getHMIAppId(1)
  local cid = mobSession:SendRPC("UnregisterAppInterface",{})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = hmiAppId, unexpectedDisconnect = false })
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app", common.registerAppWOPTU, { 1 })
runner.Step("Activate app", common.activateApp, { 1 })

runner.Title("Test")

runner.Step("GetInteriorVehicleData with subscribe=true " .. common.modules[1], common.GetInteriorVehicleData,
  { common.modules[1], true, true, 1 })
runner.Step("GetInteriorVehicleData with subscribe=true " .. common.modules[2], common.GetInteriorVehicleData,
  { common.modules[2], true, true, 1 })
runner.Step("RC.GetInteriorVehicleData with subscribe=false by app unregistration", unregistrationApp)


runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
