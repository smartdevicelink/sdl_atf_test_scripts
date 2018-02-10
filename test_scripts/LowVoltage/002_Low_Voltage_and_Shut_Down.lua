---------------------------------------------------------------------------------------------------
--
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/LowVoltage/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hashId = { }
local grammarId = { }

--[[ Local Functions ]]
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
  f[1] = function()
    local cid = common.getMobileSession(1):SendRPC("AddCommand", { cmdID = 1, vrCommands = { "OnlyVRCommand" }})
    common.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        grammarId[1] = data.params.grammarID
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    common.getMobileSession(1):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession(1):ExpectNotification("OnHashChange")
    :Do(function(_, data)
        hashId[1] = data.payload.hashID
      end)
  end
  f[2] = function()
    local cid = common.getMobileSession(2):SendRPC("AddSubMenu", { menuID = 1, position = 500, menuName = "SubMenu" })
    common.getHMIConnection():ExpectRequest("UI.AddSubMenu")
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    common.getMobileSession(2):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession(2):ExpectNotification("OnHashChange")
    :Do(function(_, data)
        hashId[2] = data.payload.hashID
      end)
  end
  f[3] = function()
    local cid = common.getMobileSession(3):SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = 1,
      choiceSet = {
        { choiceID = 1, menuName = "Choice", vrCommands = { "VrChoice" }}
      }
    })
    common.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        grammarId[3] = data.params.grammarID
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    common.getMobileSession(3):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession(3):ExpectNotification("OnHashChange")
    :Do(function(_, data)
        hashId[3] = data.payload.hashID
      end)
  end
  f[4] = function() end
  f[pAppId]()
end

local function checkResumptionData(pAppId)
  local f = {}
  f[1] = function()
    common.getHMIConnection():ExpectRequest("VR.AddCommand", {
      cmdID = 1,
      vrCommands = { "OnlyVRCommand" },
      type = "Command",
      grammarID = grammarId[1],
      appID = common.getHMIAppId(1)
    })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
  end
  f[2] = function()
    common.getHMIConnection():ExpectRequest("UI.AddSubMenu", {
      menuID = 1,
      menuParams = {
        position = 500,
        menuName = "SubMenu"
      },
      appID = common.getHMIAppId(2)
    })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
  end
  f[3] = function()
    common.getHMIConnection():ExpectRequest("VR.AddCommand", {
      cmdID = 1,
      vrCommands = { "VrChoice" },
      type = "Choice",
      grammarID = grammarId[3],
      appID = common.getHMIAppId(3)
    })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
  end
  f[4] = function() end
  f[pAppId]()
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
runner.Step("Send SHUT_DOWN signal", common.sendMQShutDownSignal)

runner.Step("Ignition On", common.start)

for i = 1, numOfApps do
  runner.Step("Re-register App " .. i .. ", check resumption data and HMI level", common.reRegisterApp, {
    i, hashId, checkAppId, checkResumptionData, checkResumptionHMILevel, "SUCCESS", 1000
  })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
