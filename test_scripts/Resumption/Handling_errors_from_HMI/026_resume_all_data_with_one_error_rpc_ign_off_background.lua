---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- In case:
-- 1. App is in Background HMI level
-- 2. Rpc_n for resumption is added by app
-- 3. IGN_OFF and IGN_ON are performed
-- 4. App reregisters with actual HashId
-- 5. Rpc_n request is sent from SDL to HMI during resumption
-- 6. HMI responds with error resultCode to Rpc_n request
-- SDL does:
-- 1. process unsuccess response from HMI
-- 2. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
-- 3. not restore Background HMI level
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Common Functions ]]
local function absenceResumptionToBackground()
  common.getHMIConnection():ExpectRequest("BasicCommunication.OnResumeAudioSource")
  :Times(0)

  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
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
    runner.Step("Activate app", common.activateNotAudibleApp)
    runner.Step("DeactivateA app to background", common.deactivateAppToBackground)
    for rpc in pairs(common.rpcs) do
      runner.Step("Add " .. rpc, common[rpc])
    end
    runner.Step("Add buttonSubscription", common.buttonSubscription)
    runner.Step("WaitUntilResumptionDataIsStored", common.waitUntilResumptionDataIsStored)
    runner.Step("IGNITION OFF", common.ignitionOff)
    runner.Step("IGNITION ON", common.start)
    runner.Step("Reregister App resumption " .. k, common.reRegisterApp,
      { 1, common.checkResumptionDataWithErrorResponse, absenceResumptionToBackground, k, interface})
    runner.Step("Unregister App", common.unregisterAppInterface)
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
