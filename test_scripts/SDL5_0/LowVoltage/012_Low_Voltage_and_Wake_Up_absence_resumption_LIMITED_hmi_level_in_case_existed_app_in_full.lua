---------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is in LIMITED HMILevel
-- 2. App has some persistent data that can be resumed
-- 3. Mobile app is disconnected during the time frame of 30 sec (inclusive) before "SDL_LOW_VOLTAGE" unix signal from HMI
-- 4. Mobile app registers with the same hashID during 30 sec. after "WAKE_UP" unix signal in the same ignition cycle
-- 5. there is application currently in FULL
-- SDL does:
-- 1. not resume LIMITED HMILevel for app
-- 2. resume persistent data
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/SDL5_0/LowVoltage/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Local Functions ]]
local function addResumptionData()
  common.rpcSend.AddCommand(1, 1)
end

local function checkResumptionData()
  common.rpcCheck.AddCommand(1, 1)
end

local function checkAppId(pAppId, pData)
  if pData.params.application.appID ~= common.getHMIAppId(pAppId) then
    return false, "App " .. pAppId .. " is registered with not the same HMI App Id"
  end
  return true
end

local function checkResumptionHMILevel()
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
  common.getMobileSession(2):ExpectNotification("OnHMIStatus")
  :Times(0)
  common.getHMIConnection():ExpectRequest("BasicCommunication.OnResumeAudioSource")
  :Times(0)
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App ", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("Activate app", common.activateApp)
runner.Step("Deactivate app to limited", common.deactivateAppToLimited, { 1 })
runner.Step("Add resumption data for App ", addResumptionData)

runner.Title("Test")
runner.Step("Wait until Resumption Data is stored" , common.waitUntilResumptionDataIsStored)
runner.Step("Close mobile connection", common.cleanSessions)
runner.Step("Wait 5 sec before LOW_VOLTAGE", common.wait, {5000})
runner.Step("Send LOW_VOLTAGE signal", common.sendLowVoltageSignal)
runner.Step("Send WAKE_UP signal", common.sendWakeUpSignal)
runner.Step("Wait 5 sec before registration", common.wait, {5000})
runner.Step("Re-connect Mobile", common.connectMobile)
runner.Step("Register app2", common.registerApp, { 2 })
runner.Step("Activate app2", common.activateApp, { 2 })
runner.Step("Re-register App , check resumption data and HMI level", common.reRegisterApp, {
  1, checkAppId, checkResumptionData, checkResumptionHMILevel, "SUCCESS", 10000
})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
