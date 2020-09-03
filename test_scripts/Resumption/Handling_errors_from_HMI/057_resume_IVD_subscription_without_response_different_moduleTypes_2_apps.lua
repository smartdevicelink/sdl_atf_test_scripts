---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description:
-- In case:
-- 1. Subscriptions for moduleType_1 and moduleType_2 are added by app1
-- 2. Subscriptions for moduleType_2 and moduleType_3 are added by app2
-- 3. Unexpected disconnect and reconnect are performed
-- 4. App1 and app2 re-register with actual HashId
-- 5. RC.GetInteriorVehicleData(moduleType_1, subscribe = true) and
--  RC.GetInteriorVehicleData(moduleType_2, subscribe = true) related to app1
--  are sent from SDL to HMI during resumption
-- 6. RC.GetInteriorVehicleData(moduleType_3, subscribe = true) request related to app2 is sent to HMI
-- 7. HMI does not respond to RC.GetInteriorVehicleData(moduleType_1) request
--  HMI responds with successful resultCode to RC.GetInteriorVehicleData(moduleType_2) and
--  RC.GetInteriorVehicleData(moduleType_3) requests
-- SDL does:
--  - not send revert RC.GetInteriorVehicleData(moduleType_2, subscribe = false) related to app1 to HMI
--  - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to app1
--  - restore all data for app2 and respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS)
--    to app2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Function ]]
local function checkResumptionData()
  local actualData = {}
  local expectedData = {}
  table.insert(expectedData, common.getInteriorVDvalue("CLIMATE", true))
  table.insert(expectedData, common.getInteriorVDvalue("RADIO", true))
  table.insert(expectedData, common.getInteriorVDvalue("SEAT", true))

  common.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData")
  :Do(function(_, data)
      common.log("Received " .. data.method .. ", moduleType: " .. data.params.moduleType .. ", subscribe: " ..
        tostring(data.params.subscribe))
      if data.params.moduleType == "RADIO" then
        common.log(data.method .. ": no response, moduleType: RADIO")
        -- HMI does not respond
      else
        common.log("Sent " .. data.method .. ": SUCCESS, moduleType: " .. data.params.moduleType)
        local resParams = { }
        resParams.moduleData = common.getActualModuleIVData(data.params.moduleType, data.params.moduleId)
        resParams.isSubscribed = data.params.subscribe
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", resParams)
      end
    end)
  :ValidIf(function(exp, data)
      table.insert(actualData, data.params)
      if exp.occurences == #expectedData then
        return common.validateInteriorVD(actualData, expectedData)
      end
      return true
    end)
  :Times(#expectedData)
  :Timeout(12000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register app1", common.registerAppWOPTU)
runner.Step("Register app2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app1", common.activateApp)
runner.Step("Activate app2", common.activateApp, { 2 })
runner.Step("App1 getInteriorVehicleData subscription for CLIMATE", common.getInteriorVehicleData,
  { 1, false, "CLIMATE" })
runner.Step("App1 getInteriorVehicleData subscription for RADIO", common.getInteriorVehicleData,
  { 1, false, "RADIO" })
runner.Step("App2 getInteriorVehicleData subscription for CLIMATE", common.getInteriorVehicleData,
  { 2, true, "CLIMATE" })
runner.Step("App2 getInteriorVehicleData subscription for SEAT", common.getInteriorVehicleData,
  { 2, false, "SEAT" })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect, { 3 })
runner.Step("Connect mobile", common.connectMobile)
runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
runner.Step("openRPCserviceForApp2", common.openRPCservice, { 2 })
runner.Step("Reregister Apps resumption", common.reRegisterAppsWithError, { checkResumptionData, nil, nil, 15000 })
runner.Step("Check subscriptions for getInteriorVehicleData CLIMATE", common.isSubscribed, { false, true, "CLIMATE" })
runner.Step("Check no subscriptions for getInteriorVehicleData RADIO", common.isSubscribed, { false, false, "RADIO" })
runner.Step("Check subscriptions for getInteriorVehicleData SEAT", common.isSubscribed, { false, true, "SEAT" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
