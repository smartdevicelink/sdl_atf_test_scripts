---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description:
-- In case:
-- 1. Subscriptions for all interior vehicle data types are added
-- 2. Unexpected disconnect and Reconnect are performed
-- 3. App reregisters with actual HashId
-- 4. HMI responds with erroneous resultCode for one interior vehicle data type
-- SDL does:
-- 1. process unsuccess response from HMI
-- 2. remove already restored data
-- 3. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Function ]]
local function getExpectedData()
  local expectedData = {}
  for _, moduleTypeValue in pairs(common.rcModuleTypes) do
    table.insert(expectedData, common.geInteriorVDvalue(moduleTypeValue, true))
    table.insert(expectedData, common.geInteriorVDvalue(moduleTypeValue, false))
  end
  return expectedData
end

local function checkResumptionData()
  local actualData = {}
  local expectedData = getExpectedData()
  local expectedNumber = 2 * #common.rcModuleTypes - 1 --`-1` because SDL does not send revert request for data
                                                       -- with erroneous response
  common.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData")
  :Do(function(exp, data)
      common.log(data.method .. ", moduleType: " .. data.params.moduleType)
      if exp.occurences == #common.rcModuleTypes then
        for k = #expectedData, 1, -1 do
          if expectedData[k].moduleType == data.params.moduleType and expectedData[k].subscribe == false then
            table.remove(expectedData, k)
          end
        end
        local function sendResponse()
          common.log(data.method .. ": GENERIC_ERROR, moduleType: " .. data.params.moduleType)
          common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
        end
        common.run.runAfter(sendResponse, 300)
      else
        common.log(data.method .. ": SUCCESS, moduleType: " .. data.params.moduleType)
        local resParams = { }
        resParams.moduleData = common.getActualModuleIVData(data.params.moduleType, data.params.moduleId)
        resParams.isSubscribed = data.params.subscribe
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", resParams)
      end
    end)
  :ValidIf(function(exp, data)
      table.insert(actualData, data.params)
      return common.interiorVDvalidation(exp.occurences, expectedNumber, actualData, expectedData)
    end)
  :Times(expectedNumber)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register app", common.registerAppWOPTU)
runner.Step("Activate app", common.activateApp)
for _, moduleType in pairs(common.rcModuleTypes) do
  runner.Step("Add getInteriorVehicleData subscription for " .. moduleType, common.getInteriorVehicleData,
    { 1, false, moduleType })
end
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption data", common.reRegisterApp,
  { 1, checkResumptionData, common.resumptionFullHMILevel })
for _, moduleType in pairs(common.rcModuleTypes) do
  runner.Step("Check subscriptions for getInteriorVehicleData ".. moduleType, common.isSubscribed,
    { false, nil, moduleType })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
