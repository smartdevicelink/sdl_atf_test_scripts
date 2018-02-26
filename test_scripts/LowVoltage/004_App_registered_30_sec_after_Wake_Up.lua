---------------------------------------------------------------------------------------------------
-- Test Case #1: Extension 1
-- In case:
-- 1) App was in FULL HMI level before LOW_VOLTAGE
-- 2) App registers 30 sec after WAKE_UP
-- SDL does:
-- 1) Resume app data
-- 2) Not resume app HMI level
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/LowVoltage/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function addResumptionData()
  common.rpcSend.AddCommand(1)
end

local function checkResumptionData()
  common.rpcCheck.AddCommand(1)
end

local function checkResumptionHMILevel()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = common.getHMIAppId(1) })
  :Times(0)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

local function wait()
  common.cprint(35, "Wait 31 sec")
  common.delayedExp(31100)
end

local function checkAppId(pAppId, pData)
  if pData.params.application.appID ~= common.getHMIAppId(pAppId) then
    return false, "App " .. pAppId .. " is registered with not the same HMI App Id"
  end
  return true
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)

runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate for App", common.policyTableUpdate)
runner.Step("Activate App", common.activateApp)
runner.Step("Add resumption data for App", addResumptionData)

runner.Title("Test")

runner.Step("Wait until Resumption Data is stored" , common.waitUntilResumptionDataIsStored)

runner.Step("Send LOW_VOLTAGE signal", common.sendMQLowVoltageSignal)

runner.Step("Send WAKE_UP signal", common.sendMQWakeUpSignal)
runner.Step("Wait", wait)

runner.Step("Re-connect Mobile", common.connectMobile)
runner.Step("Re-register App, check resumption of Data and no resumption of HMI level", common.reRegisterApp, {
  1, checkAppId, checkResumptionData, checkResumptionHMILevel, "SUCCESS", 5000
})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
