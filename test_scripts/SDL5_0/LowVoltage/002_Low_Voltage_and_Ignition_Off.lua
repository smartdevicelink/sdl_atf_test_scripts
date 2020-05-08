---------------------------------------------------------------------------------------------------
-- In case:
-- 1) SDL is started (there was no LOW_VOLTAGE signal sent)
-- 2) There are following app’s in HMI levels:
-- App1 is in FULL
-- App2 is in LIMITED
-- App3 is in BACKGROUND
-- App4 is in NONE
-- 3) All apps have some data that can be resumed
-- 4) SDL get LOW_VOLTAGE signal
-- 5) And then SDL get IGNITION_OFF signal
-- 6) And then SDL is started
-- 7) All apps are registered with the same hashID
-- SDL does:
-- 1) after 5th step: Finish it’s work successfully (as for Ignition Off)
-- 2) after 6th step: Start it’s work successfully (as for next Ignition Cycle)
-- 3) after 7th step:
-- Resume app data for App1, App2, App3 and App4
-- Resume HMI level for App1, App2, App4
-- Not resume HMI level for App3
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/SDL5_0/LowVoltage/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function addResumptionData(pAppId)
  local f = {}
  f[1] = common.rpcSend.AddCommand
  f[2] = common.rpcSend.AddSubMenu
  f[3] = common.rpcSend.CreateInteractionChoiceSet
  f[4] = common.rpcSend.NoRPC
  f[pAppId](pAppId)
end

local function checkResumptionData(pAppId)
  local f = {}
  f[1] = common.rpcCheck.AddCommand
  f[2] = common.rpcCheck.AddSubMenu
  f[3] = common.rpcCheck.CreateInteractionChoiceSet
  f[4] = common.rpcCheck.NoRPC
  f[pAppId](pAppId)
end

local function checkAppId(pAppId, pData)
  if pData.params.application.appID ~= common.getHMIAppId(pAppId) then
    return false, "App " .. pAppId .. " is registered with not the same HMI App Id"
  end
  return true
end

local function sendIgnitionOffSignal()
  common.getMobileSession():ExpectAny():Times(0)
  common.getHMIConnection():ExpectAny():Times(0)
  common.sendIgnitionOffSignal()
  common.wait(2000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
local numOfApps = 4
for i = 1, numOfApps do
  runner.Step("Register App " .. i, common.registerApp, { i })
  runner.Step("PolicyTableUpdate", common.policyTableUpdate)
end
runner.Step("Configure HMI levels", common.configureHMILevels, { numOfApps })
for i = 1, numOfApps do
  runner.Step("Add resumption data for App " .. i, addResumptionData, { i })
end

runner.Title("Test")
runner.Step("Wait until Resumption Data is stored" , common.waitUntilResumptionDataIsStored)
runner.Step("Send LOW_VOLTAGE signal", common.sendLowVoltageSignal)
runner.Step("Close mobile connection", common.cleanSessions)
runner.Step("Send IGNITION_OFF signal", sendIgnitionOffSignal)
runner.Step("Ignition On", common.start)
for i = 1, numOfApps do
  runner.Step("Re-register App " .. i .. ", check resumption data and HMI level", common.reRegisterApp, {
    i, checkAppId, checkResumptionData, common.checkResumptionHMILevel, "SUCCESS", 1000
  })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
