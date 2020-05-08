---------------------------------------------------------------------------------------------------
-- In case:
-- 1) SDL is started (there was no LOW_VOLTAGE signal sent)
-- 2) SDL is in progress of processing some RPC
-- 3) SDL get LOW_VOLTAGE signal
-- 4) And then SDL get WAKE_UP signal
-- SDL does:
-- 1) Resume it’s work successfully (as for Resumption)
-- 2) Discard processing of RPC
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/SDL5_0/LowVoltage/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local cid = nil
local hmiId

--[[ Local Functions ]]
local function checkResumptionData()
  common.getMobileSession():ExpectResponse(cid) -- check absence of response
  :Times(0)
end

local function showResponseDuringWakeUp()
  common.sendWakeUpSignal()
  common.getHMIConnection():SendResponse(hmiId, "UI.Show", "SUCCESS", {})
  common.getMobileSession():ExpectResponse(cid) -- check absence of response
  :Times(0)
end

local function checkResumptionHMILevel()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = common.getHMIAppId(1) })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
  :Times(2)
end

local function processRPCPartially()
  local params = {
    mainField1 = "Show Line 1",
    mainField2 = "Show Line 2",
    mainField3 = "Show Line 3"
  }
  cid = common.getMobileSession():SendRPC("Show", params)
  EXPECT_HMICALL("UI.Show")
  :Do(function(_, data)
    hmiId = data.id
  end)
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
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Wait until Resumption Data is stored" , common.waitUntilResumptionDataIsStored)
runner.Step("RPC Show partially", processRPCPartially)
runner.Step("Send LOW_VOLTAGE signal", common.sendLowVoltageSignal)
runner.Step("Send WAKE_UP signal and absence Show response on mobile app", showResponseDuringWakeUp)
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Re-connect Mobile", common.connectMobile)
runner.Step("Re-register App, check resumption data and HMI level", common.reRegisterApp, {
  1, checkAppId, checkResumptionData, checkResumptionHMILevel, "SUCCESS", 11000
})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
