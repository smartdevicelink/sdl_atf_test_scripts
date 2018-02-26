---------------------------------------------------------------------------------------------------
-- In case:
-- 1) SDL is started (there was no LOW_VOLTAGE signal sent)
-- 2) SDL is in progress of processing some RPC
-- 3) SDL get LOW_VOLTAGE signal via mqueue
-- 4) And then SDL get WAKE_UP signal via mqueue
-- SDL does:
-- 1) Resume it’s work successfully (as for Resumption)
-- 2) Discard processing of RPC
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/LowVoltage/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local addCommandCid = nil

--[[ Local Functions ]]
local function checkResumptionData()
  common.rpcCheck.AddCommand(1, 1)
  common.getMobileSession():ExpectResponse(addCommandCid)
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

local function processAddCommandPartially(pCmdId)
  addCommandCid = common.getMobileSession():SendRPC("AddCommand", { cmdID = pCmdId, vrCommands = { "CMD" .. pCmdId }})
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
end

local function processAddCommandSuccessfully(pCmdId)
  common.rpcSend.AddCommand(1, pCmdId)
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
runner.Step("AddCommand 1 success", processAddCommandSuccessfully, { 1 })
runner.Step("Wait until Resumption Data is stored" , common.waitUntilResumptionDataIsStored)

runner.Title("Test")

runner.Step("AddCommand 2 partial", processAddCommandPartially, { 2 })

runner.Step("Send LOW_VOLTAGE signal", common.sendMQLowVoltageSignal)

runner.Step("Send WAKE_UP signal", common.sendMQWakeUpSignal)

runner.Step("Re-connect Mobile", common.connectMobile)
runner.Step("Re-register App, check resumption data and HMI level", common.reRegisterApp, {
  1, checkAppId, checkResumptionData, checkResumptionHMILevel, "SUCCESS", 11000
})

runner.Step("AddCommand 2 success", processAddCommandSuccessfully, { 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
