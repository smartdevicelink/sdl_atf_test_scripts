---------------------------------------------------------------------------------------------------
-- Proposal:
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. App is subscribed to all modules
-- 2. IGN_OFF and IGN_ON are  performed
-- 3. App starts registration with actual hashId after unexpected disconnect
-- SDL does:
-- 1. send RC.GetInteriorVD(subscribe=true) to HMI during resumption data for all modules
-- 2. respond RAI(SUCCESS) to mobile app
-- 3. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/InteriorVehicleData/common_resumptionsInteriorVD')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function checkResumptionData()
  local modulesToExpect = common.cloneTable(common.modules)
  EXPECT_HMICALL("RC.GetInteriorVehicleData")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { moduleData = common.getModuleControlData(data.params.moduleData.moduleType), isSubscribed = true })
    end)
  :ValidIf(function(exp, data)
    modulesToExpect[data.params.moduleData.moduleType] = true
    if exp.occurences == #modulesToExpect then
      for k, v in pairs(modulesToExpect) do
        if v == false then
          return false, "Module " .. k .. " was not resumed"
        end
      end
      return true
    end
    return true
  end)
  :Times(#modulesToExpect)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
for _, modules in pairs(common.modules) do
  runner.Step("Add interiorVD subscription for " .. modules, common.GetInteriorVehicleData, { modules, true, 1, 1 })
end

runner.Title("Test")
runner.Step("IGNITION_OFF", common.ignitionOff)
runner.Step("IGNITION_ON", common.start)
runner.Step("Reregister App resumption data", common.reRegisterApp,
  { 1, checkResumptionData, common.resumptionFullHMILevel })
for _, mod in pairs(common.modules) do
  runner.Step("Check subscription for " .. mod, common.GetInteriorVehicleData, { mod, nil, 0, 0 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

