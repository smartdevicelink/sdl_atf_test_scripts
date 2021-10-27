---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- Check data resumption is failed in case if HMI does not respond to at least one request from SDL during default timeout
-- (unexpected disconnect scenario)
--
-- In case:
-- 1. AddCommand, AddSubMenu, CreateInteractionChoiceSet, SetGlobalProperties, SubscribeButton, SubscribeVehicleData,
--  SubscribeWayPoints, CreateWindow, GetInteriorVehicleData (<Rpc_n>) are sent by app
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App re-registers with actual HashId
-- SDL does:
--  - start resumption process
--  - send set of <Rpc_n> requests to HMI
-- 4. HMI does not respond to one request and responds <successful> for others
-- SDL does:
--  - process responses from HMI
--  - remove already restored data when default timeout expires:
--    - send set of revert <Rpc_n> requests to HMI (except the one related to timed out response)
--    - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Common Functions ]]
function common.sendResponseWithDelay()
  -- HMI does not respond
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for k, value in common.pairs(common.rpcs) do
  for _, interface in common.pairs(value) do
    runner.Title("Rpc " .. k .. " missing response to interface " .. interface)
    runner.Step("Register app", common.registerAppWOPTU)
    runner.Step("Activate app", common.activateApp)
    for rpc in pairs(common.rpcs) do
      runner.Step("Add " .. rpc, common[rpc])
    end
    runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
    runner.Step("Connect mobile", common.connectMobile)
    runner.Step("Reregister App resumption " .. k, common.reRegisterAppResumeFailed,
      { 1, common.checkAllResumptionDataWithOneErrorResponse, common.resumptionFullHMILevel, k, interface, 12000})
    runner.Step("Unregister App", common.unregisterAppInterface)
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
