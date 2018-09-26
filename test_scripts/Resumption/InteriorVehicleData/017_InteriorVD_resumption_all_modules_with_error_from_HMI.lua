---------------------------------------------------------------------------------------------------
-- Proposal:
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1.App is subscribed to all modules
-- 2. Transport disconnect and reconnect are performed
-- 3. App reregisters with actual HashId
-- 4. RC.GetInteriorVD(subscribe=true) for all modules
-- 5. HMI responds with error resultCode to RC.GetInteriorVD(subscribe=true, modules_n) request
-- SDL does:
-- 1. process unsuccess response from HMI
-- 2. remove all restored data for others modules
-- 3. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/InteriorVehicleData/common_resumptionsInteriorVD')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function checkResumptionData()
  local resumedModules = {}
  local requestsNumber = 2*#common.modules - 1
  local function removeModule(pModule)
    for key, value in pairs(resumedModules) do
      if value == pModule then
        resumedModules[key] = nil
      end
    end
  end
  EXPECT_HMICALL("RC.GetInteriorVehicleData")
  :ValidIf(function(exp, data)
      if data.params.subscribe == true then
        table.insert(resumedModules, data.params.moduleType)
      elseif data.params.subscribe == false then
        removeModule(data.params.moduleType)
      end
      if exp.occurences == #common.modules then
        removeModule(data.params.moduleType)
        common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "Error message")
      else
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { moduleData = common.getModuleControlData(data.params.moduleType), isSubscribed = true })
      end
      if requestsNumber == exp.occurences and commonFunctions:is_table_equal(resumedModules, {}) ~= true then
        return false, "SDL does not revert all resumed data. Remained modules are " .. common.tableToString(resumedModules)
      end
      return true
    end)
  :Times(requestsNumber)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
for _, mod in pairs(common.modules) do
  runner.Step("Add interiorVD subscription for " .. mod, common.GetInteriorVehicleData, { mod, true, 1, 1 })
end

runner.Title("Test")
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption data", common.reRegisterApp,
  { 1, checkResumptionData, common.resumptionFullHMILevel, "RESUME_FAILED"})
runner.Step("Check subscription", common.GetInteriorVehicleData, { common.modules[1], false, 1, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

