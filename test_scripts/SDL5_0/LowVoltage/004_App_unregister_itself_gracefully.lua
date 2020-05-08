---------------------------------------------------------------------------------------------------
-- Test Case #1: Extension 3
-- In case:
-- 1) App unregisters itself gracefully before LOW_VOLTAGE
-- 2) App registers again after WAKE_UP
-- SDL does:
-- 1) Not resume app data
-- 2) Not resume app HMI level
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/SDL5_0/LowVoltage/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function addResumptionData()
  common.rpcSend.AddCommand(1)
end

local function checkResumptionData()
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Times(0)
end

local function checkResumptionHMILevel()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = common.getHMIAppId(1) })
  :Times(0)
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

local function checkAppId(pAppId, pData)
  if pData.params.application.appID == common.getHMIAppId(pAppId) then
    return false, "App " .. pAppId .. " is registered with the same HMI App Id"
  end
  return true
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("Activate App", common.activateApp)
runner.Step("Add resumption data for App", addResumptionData)

runner.Title("Test")
runner.Step("Wait until Resumption Data is stored" , common.waitUntilResumptionDataIsStored)
runner.Step("Unregister App", common.unregisterApp)
runner.Step("Send LOW_VOLTAGE signal", common.sendLowVoltageSignal)
runner.Step("Close mobile connection", common.cleanSessions)
runner.Step("Send WAKE_UP signal", common.sendWakeUpSignal)
runner.Step("Re-connect Mobile", common.connectMobile)
runner.Step("Re-register App, check no resumption of Data and no resumption of HMI level", common.reRegisterApp, {
  1, checkAppId, checkResumptionData, checkResumptionHMILevel, "RESUME_FAILED", 5000
})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
