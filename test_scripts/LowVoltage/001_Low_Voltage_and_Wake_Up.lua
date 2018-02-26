---------------------------------------------------------------------------------------------------
-- In case:
-- 1) SDL is started (there was no LOW_VOLTAGE signal sent)
-- 2) There are following app’s in HMI levels:
-- App1 is in FULL
-- App2 is in LIMITED
-- App3 is in BACKGROUND
-- App4 is in NONE
-- 3) All apps have some data that can be resumed
-- 4) SDL get LOW_VOLTAGE signal via mqueue
-- 5) And then SDL get WAKE_UP signal via mqueue
-- 6) All apps are registered with the same hashID
-- SDL does:
-- 1) after 4th step:
-- Stop all read write activities
-- Stop Audio/Video streaming
-- Ignore all RPCs from mobile side
-- Ignore all RPCs from HMI side
-- 2) after 5th step: Start it’s work successfully
-- 3) after 6th step:
-- Resume app data for App1, App2, App3 and App4
-- Resume HMI level for App1, App2, App4
-- Not resume HMI level for App3
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/LowVoltage/common')
local runner = require('user_modules/script_runner')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function checkSDLIgnoresRPCFromMobileSide()
  common.getMobileSession():SendRPC("AddCommand", { cmdID = 2, vrCommands = { "OnlyVRCommand" }})

  common.getHMIConnection():ExpectAny():Times(0)
  :Do(function(_, data)
      print("HMI Event")
      commonFunctions:printTable(data)
    end)

  common.getMobileSession():ExpectAny():Times(0)
  :Do(function(_, data)
      print("Mobile Event")
      commonFunctions:printTable(data)
    end)
  common.delayedExp(11000)
end

local function checkSDLIgnoresRPCFromHMISide()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    isActive = true, eventName = "EMERGENCY_EVENT" })

  common.getHMIConnection():ExpectAny():Times(0)
  :Do(function(_, data)
      print("HMI Event")
      commonFunctions:printTable(data)
    end)

  common.getMobileSession():ExpectAny():Times(0)
  :Do(function(_, data)
      print("Mobile Event")
      commonFunctions:printTable(data)
    end)
  common.delayedExp(11000)
end

local function configureHMILevels(pNumOfApps)
  local apps = {
    [1] = { 1 },
    [2] = { 2, 1 },
    [3] = { 2, 3, 1 },
    [4] = { 2, 3, 1 }
  }
  for k, i in pairs(apps[pNumOfApps]) do
    local function activateApp()
      local cid = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(i) })
      common.getHMIConnection():ExpectResponse(cid)
      :Do(function() common.cprint(35, "Activate App: " .. i) end)
    end
    RUN_AFTER(activateApp, 100 * k)
  end
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })

  if pNumOfApps >= 2 then
    common.getMobileSession(2):ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE" },
      { hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
    :Times(2)
  end
  if pNumOfApps >= 3 then
    common.getMobileSession(3):ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
      { hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
    :Times(2)
  end
end

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

local function checkResumptionHMILevel(pAppId)
  local f = {}
  f[1] = function()
    common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = common.getHMIAppId(1) })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
      end)
    common.getMobileSession(1):ExpectNotification("OnHMIStatus",
      { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
      { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
    :Times(2)
  end
  f[2] = function()
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnResumeAudioSource", {
      appID = common.getHMIAppId(2) })
    common.getMobileSession(2):ExpectNotification("OnHMIStatus",
      { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
      { hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
    :Times(2)
  end
  f[3] = function()
    common.getMobileSession(3):ExpectNotification("OnHMIStatus",
      { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    :Times(1)
  end
  f[4] = function()
    common.getMobileSession(4):ExpectNotification("OnHMIStatus",
      { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    :Times(1)
  end
  f[pAppId]()
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

local numOfApps = 1

for i = 1, numOfApps do
  runner.Step("Register App " .. i, common.registerApp, { i })
  runner.Step("PolicyTableUpdate " .. i, common.policyTableUpdate, { i })
end

runner.Step("Configure HMI levels", configureHMILevels, { numOfApps })

for i = 1, numOfApps do
  runner.Step("Add resumption data for App " .. i, addResumptionData, { i })
end

runner.Title("Test")

runner.Step("Wait until Resumption Data is stored" , common.waitUntilResumptionDataIsStored)

runner.Step("Send LOW_VOLTAGE signal", common.sendMQLowVoltageSignal)

runner.Step("Check SDL Ignores RPCs from Mobile side", checkSDLIgnoresRPCFromMobileSide)
runner.Step("Check SDL Ignores RPCs from HMI side", checkSDLIgnoresRPCFromHMISide)

runner.Step("Send WAKE_UP signal", common.sendMQWakeUpSignal)

runner.Step("Re-connect Mobile", common.connectMobile)
for i = 1, numOfApps do
  runner.Step("Re-register App " .. i .. ", check resumption data and HMI level", common.reRegisterApp, {
    i, checkAppId, checkResumptionData, checkResumptionHMILevel, "SUCCESS", 1000
  })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
