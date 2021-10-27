---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- Check data resumption is failed in case if HMI responds with <erroneous> result code
-- to at least one request from SDL (Ignition Off/On scenario)
--
-- In case:
-- 1. AddCommand, AddSubMenu, CreateInteractionChoiceSet, SetGlobalProperties, SubscribeButton, SubscribeVehicleData,
--  SubscribeWayPoints, CreateWindow, GetInteriorVehicleData are sent by app
-- 2. IGN_OFF and IGN_ON are performed
-- 3. App re-registers with actual HashId
-- SDL does:
--  - start resumption process
--  - send set of <Rpc_n> requests to HMI
-- 4. HMI responds with <erroneous> resultCode to one request and <successful> for others
-- SDL does:
--  - process responses from HMI
--  - remove already restored data
--  - send set of revert <Rpc_n> requests to HMI (except the one related to <erroneous> response)
--  - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for k, value in common.pairs(common.rpcs) do
  for _, interface in common.pairs(value) do
    runner.Title("Rpc " .. k .. " error resultCode to interface " .. interface)
    runner.Step("Register app", common.registerAppWOPTU)
    runner.Step("Activate app", common.activateApp)
    runner.Step("Check subscriptions", common.checkSubscriptions, { false })
    for rpc in pairs(common.rpcs) do
      runner.Step("Add " .. rpc, common[rpc])
    end
    runner.Step("Check subscriptions", common.checkSubscriptions, { true })
    runner.Step("WaitUntilResumptionDataIsStored", common.waitUntilResumptionDataIsStored)
    runner.Step("IGNITION OFF", common.ignitionOff)
    runner.Step("IGNITION ON", common.start)
    runner.Step("Reregister App resumption " .. k, common.reRegisterAppResumeFailed,
      { 1, common.checkAllResumptionDataWithOneErrorResponse, common.resumptionFullHMILevel, k, interface})
    runner.Step("Check subscriptions", common.checkSubscriptions, { false })
    runner.Step("Unregister App", common.unregisterAppInterface)
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
