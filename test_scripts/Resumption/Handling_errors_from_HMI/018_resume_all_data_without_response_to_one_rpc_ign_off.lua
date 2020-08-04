---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- In case:
-- 1. AddCommand, AddSubMenu, CreateInteractionChoiceSet, SetGlobalProperties, SubscribeButton, SubscribeVehicleData,
--  SubscribeWayPoints, CreateWindow are added by app
-- 2. IGN_OFF and IGN_ON are performed
-- 3. App reregisters with actual HashId
-- 4. Rpc_n request is sent from SDL to HMI during resumption
-- 5. HMI does not respond to Rpc_n request and responds with resultCode SUCCESS to another requests
-- SDL does:
-- 1. remove already restored data after default timeout
-- 2. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
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
for k, value in pairs(common.rpcs) do
  for _, interface in pairs(value) do
    runner.Title("Rpc " .. k .. " error resultCode to interface " .. interface)
    runner.Step("Register app", common.registerAppWOPTU)
    runner.Step("Activate app", common.activateApp)
    for rpc in pairs(common.rpcs) do
      runner.Step("Add " .. rpc, common[rpc])
    end
    runner.Step("Add buttonSubscription", common.buttonSubscription)
    runner.Step("WaitUntilResumptionDataIsStored", common.waitUntilResumptionDataIsStored)
    runner.Step("IGNITION OFF", common.ignitionOff)
    runner.Step("IGNITION ON", common.start)
    runner.Step("Reregister App resumption " .. k, common.reRegisterApp,
      { 1, common.checkResumptionDataWithErrorResponse, common.resumptionFullHMILevel, k, interface, 12000})
    runner.Step("Unregister App", common.unregisterAppInterface)
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
