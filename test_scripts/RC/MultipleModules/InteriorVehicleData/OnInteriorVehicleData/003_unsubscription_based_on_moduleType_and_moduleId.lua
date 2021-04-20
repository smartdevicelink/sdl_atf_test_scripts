---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App subscribes to RADIO module. Check regularity of unsubscribe attempt by sending "GetInteriorVehicleData"
--  request containing "moduleType" and "moduleId" parameters
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
-- 5) App is subscribed to RADIO module with moduleId = "00bd6d93"
--
-- Steps:
-- 1) App sends "GetInteriorVehicleData"(moduleType = "RADIO", moduleId = "00bd6d93", subscribe = false) request
--   Check:
--    SDL resends "RC.GetInteriorVehicleData"(moduleType = "RADIO", moduleId = "00bd6d93", subscribe = false) request
--     to the HMI
--    HMI sends "RC.GetInteriorVehicleData"
--     (moduleType = "RADIO", moduleId = "00bd6d93", radioControlData, isSubscribed = false) response to the SDL
--    SDL resends "GetInteriorVehicleData"
--     (moduleType = "RADIO", moduleId = "00bd6d93", radioControlData, resultCode = "SUCCESS") response to the App
-- 2) After some changes were made to the "00bd6d93" module HMI sends "RC.OnInteriorVehicleData"
--     (moduleType = "RADIO", moduleId = "00bd6d93", radioControlData) notification to the SDL
--   Check:
--    SDL does not send any notifications to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local customRadioCapabilities = {
  {
    moduleName = "Radio Driver Seat",
    moduleInfo = {
      moduleId = "00bd6d93-e093-4bf0-9784-281febe41bed",
      location = {
        col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      serviceArea = {
        col = 0, row = 0, level = 0, colspan = 3, rowspan = 2, levelspan = 1
      },
      allowMultipleAccess = true
    },
    radioEnableAvailable = true,
    radioBandAvailable = true,
    radioFrequencyAvailable = true,
    hdChannelAvailable = true,
    rdsDataAvailable = true,
    availableHDsAvailable = true,
    stateAvailable = true,
    signalStrengthAvailable = true,
    signalChangeThresholdAvailable = true,
    sisDataAvailable = true,
    hdRadioEnableAvailable = true,
    siriusxmRadioAvailable = true
  }
}
local rcCapabilities = { RADIO = customRadioCapabilities }
local radioDataToSet = {
  moduleType = "RADIO",
  moduleId = customRadioCapabilities[1].moduleInfo.moduleId,
  radioControlData = {
    frequencyInteger = 100,
    frequencyFraction = 5,
    band = "FM"
  }
}
local moduleId = customRadioCapabilities[1].moduleInfo.moduleId

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Subscribe on RADIO module by sending moduleType and moduleId", common.subscribeToModule,
  { "RADIO", moduleId, 1 })

runner.Title("Test")
runner.Step("Unsubscribe from RADIO module by sending moduleType and moduleId", common.unsubscribeFromModule,
  { "RADIO", moduleId, 1 })
runner.Step("Check of not receiving notification after making changes in RADIO module", common.isSubscribed,
  { "RADIO", moduleId, 1, false, radioDataToSet })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
