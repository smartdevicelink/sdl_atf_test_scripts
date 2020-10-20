---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description:
-- In case:
-- 1. Subscriptions for moduleType_1 and moduleType_2 are added by app
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App re-registers with actual HashId
-- 4. RC.GetInteriorVehicleData(moduleType_1, subscribe = true) and
--  RC.GetInteriorVehicleData(moduleType_2, subscribe = true) related to app are sent from SDL to HMI during resumption
-- 5. HMI responds with successful resultCode and isSubscibed = false to RC.GetInteriorVehicleData(moduleType_1) request
--  HMI responds with successful resultCode and isSubscibed = true to RC.GetInteriorVehicleData(moduleType_2) request
-- SDL does:
-- - send revert RC.GetInteriorVehicleData(moduleType_2, subscribe = false) to HMI
-- 6. HMI responds with successful resultCode to RC.GetInteriorVehicleData(moduleType_2)
-- SDL does:
-- - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local modules = { common.rcModuleTypes[1], common.rcModuleTypes[2] }

-- [[ Local Function ]]
local function checkResumptionData()
  local actualData = {}
  local expectedData = {}
  table.insert(expectedData, common.getInteriorVDvalue(modules[1], true))
  table.insert(expectedData, common.getInteriorVDvalue(modules[2], true))
  table.insert(expectedData, common.getInteriorVDvalue(modules[2], false))

  common.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData")
  :Do(function(_, data)
      common.log("Received " .. data.method .. ", moduleType: " .. data.params.moduleType .. ", subscribe: " ..
        tostring(data.params.subscribe))
      local resParams = { }
      if data.params.moduleType == modules[1] then
        resParams.isSubscribed = false
      else
        resParams.isSubscribed = data.params.subscribe
      end
      common.log("Sent " .. data.method .. ": SUCCESS, moduleType: " .. data.params.moduleType .. ", isSubscribed: " ..
        tostring(resParams.isSubscribed))
      resParams.moduleData = common.getActualModuleIVData(data.params.moduleType, data.params.moduleId)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", resParams)
    end)
  :ValidIf(function(exp, data)
      table.insert(actualData, data.params)
      if exp.occurences == #expectedData then
        return common.validateInteriorVD(actualData, expectedData)
      end
      return true
    end)
  :Times(#expectedData)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register app", common.registerAppWOPTU)
runner.Step("Activate app", common.activateApp)
for _, moduleType in common.pairs(modules) do
  runner.Step("Add getInteriorVehicleData subscription for " .. moduleType, common.getInteriorVehicleData,
    { 1, false, moduleType })
end
runner.Step("Unexpected disconnect", common.unexpectedDisconnect, { 2 })
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption data", common.reRegisterAppResumeFailed,
  { 1, checkResumptionData, common.resumptionFullHMILevel})
for _, moduleType in common.pairs(modules) do
  runner.Step("Check no subscriptions for getInteriorVehicleData " .. moduleType, common.isSubscribed,
    { false, nil, moduleType })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
