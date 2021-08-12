---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- Check data resumption succeeded in case if HMI responds with any <successful> result code to all requests from SDL
--
-- In case:
-- 1. AddCommand, AddSubMenu, CreateInteractionChoiceSet, SetGlobalProperties, SubscribeButton, SubscribeVehicleData,
--  SubscribeWayPoints, CreateWindow (<Rpc_n>) are sent by app
-- 2. Unexpected disconnect/IGN_OFF and Reconnect/IGN_ON are performed
-- 3. App re-registers with actual HashId
-- SDL does:
--  - start resumption process
--  - send set of <Rpc_n> requests to HMI
-- 4. HMI responds with any <successful> resultCode to each <Rpc_n> request:
--   "WARNINGS", "RETRY", "SAVED", "WRONG_LANGUAGE", "UNSUPPORTED_RESOURCE", "TRUNCATED_DATA"
-- SDL does:
--  - process responses from HMI
--  - restore all persistent data
--  - respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local successCodes = {
  "WARNINGS", "RETRY", "SAVED", "WRONG_LANGUAGE", "UNSUPPORTED_RESOURCE", "TRUNCATED_DATA"
}
-- [[ Local Function ]]
local function setResponseCode(pCode)
  function common.sendResponse(pData)
    common.getHMIConnection():SendResponse(pData.id, pData.method, pCode, common.getSuccessHMIResponseData(pData))
  end
end

--[[ Scenario ]]
for _, code in common.pairs(successCodes) do
  runner.Title("Case: HMI response: " .. code)
  runner.Step("Set code for HMI response", setResponseCode, { code })

  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Register app", common.registerAppWOPTU)
  runner.Step("Activate app", common.activateApp)
  runner.Step("Check subscriptions", common.checkSubscriptions, { false })

  runner.Title("Test")
  for k in pairs(common.rpcs) do
    runner.Step("Add " .. k, common[k])
  end
  runner.Step("Check subscriptions", common.checkSubscriptions, { true })
  runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
  runner.Step("Connect mobile", common.connectMobile)
  runner.Step("Reregister App resumption data", common.reRegisterAppSuccess,
    { 1, common.checkResumptionDataSuccess, common.resumptionFullHMILevel})
  runner.Step("Check subscriptions", common.checkSubscriptions, { true })
  runner.Step("Unregister App", common.unregisterAppInterface)

  runner.Title("Postconditions")
  runner.Step("Stop SDL", common.postconditions)
end

