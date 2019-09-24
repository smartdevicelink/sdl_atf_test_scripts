---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: SDL resumes applications state after unexpected disconnect for the same applications that are registered
--  on two mobile devices
--
-- Precondition:
-- 1)SDL and HMI are started
-- 2)Mobile №1 and №2 are connected to SDL and are consented
-- 3)Application App1 is registered on Mobile №1 and Mobile №2 (two copies of one application)
--   App1 from Mobile №1 and App1 from Mobile №2 are activated sequentially
--   App1 from Mobile №1 has FULL HMI Level, App1 from Mobile №2 has BACKGROUND HMI Level
--
-- Steps:
-- 1)User disconnects Mobile №1 and Mobile №2 from SDL without correct exit aplications.
--    User re-register App1 from Mobile №1
--   Check:
--    App1 from Mobile №1 is registered, SDL sends OnAppRegistered with the same HMI appID
--     as before unexpected disconnect, then resend AddCommand and AddSubmenu RPCs to HMI,
--     sends BasicCommunication.ActivateApp to HMI and after success response from HMI,
--     SDL sends to App OnHMIStatus(FULL)
-- 2)User re-register App1 from Mobile №2
--   Check:
--    App1 from Mobile №2 is registered, SDL sends OnAppRegistered with the same HMI appID
--     as before unexpected disconnect, resend AddCommand and AddSubmenu RPCs to HMI
--     and does not set App1 from Mobile №2 to BACKGROUND HMI level
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = {
    appName = "Test Application 3",
    isMediaApplication = true,
    appHMIType = { "DEFAULT" },
    appID = "0003",
    fullAppID = "0000035",
  }
}

local contentData = {
  [1] = {
    addCommand = {
      mob = { cmdID = 1, vrCommands = { "OnlyVR" }},
      hmi = { cmdID = 1, type = "Command", vrCommands = { "OnlyVR" }}
    },
    addSubMenu = {
      mob = { menuID = 1, position = 500, menuName = "NewSubMenu" },
      hmi = { menuID = 1, menuParams = { position = 500, menuName = "NewSubMenu" }}
    }
  },
  [2] = {
    addCommand = {
      mob = { cmdID = 1, vrCommands = { "vrCommand" }},
      hmi = { cmdID = 1, type = "Command", vrCommands = { "vrCommand" }}
    },
    addSubMenu = {
      mob = { menuID = 1, position = 300, menuName = "ReactiveSubMenu" },
      hmi = { menuID = 1, menuParams = { position = 300, menuName = "ReactiveSubMenu" }}
    }
  }
}

local appData = {}

--[[ Local Functions ]]
local function modificationOfPreloadedPT(pPolicyTable)
  local pt = pPolicyTable.policy_table
  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null

  local policyAppParams = common.cloneTable(pt.app_policies["default"])
  policyAppParams.AppHMIType = appParams[1].appHMIType
  policyAppParams.groups = { "Base-4" }

  pt.app_policies[appParams[1].fullAppID] = policyAppParams
end

local function addContent(pAppId, pContentData)
  appData[pAppId] = { hmiAppId = common.app.getHMIId(pAppId) }
  common.addCommand(pAppId, pContentData.addCommand)
  common.run.runAfter(function() common.addSubMenu(pAppId, pContentData.addSubMenu) end, 100)
  common.mobile.getSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(exp, data)
      if exp.occurences == 2 then
        appData[pAppId].hashId = data.payload.hashID
      end
    end)
  :Times(2)
end

local function validateAppId(pRequestName, pExpValue, pActValue)
  if pActValue ~= pExpValue then
    local msg = pRequestName .. " request has incorrect appId value. Expected: " .. tostring(pExpValue)
        .. ", actual: " .. tostring(pActValue)
    return false, msg
  end
  return true
end

local function expectHmiContent(pAppId, pContentData)
  local hmi = common.hmi.getConnection()
  local hmiAppId = common.app.getHMIId(pAppId)
  hmi:ExpectRequest("VR.AddCommand", pContentData[pAppId].addCommand.hmi)
  :ValidIf(function(_, data)
    return validateAppId("VR.AddCommand", hmiAppId, data.params.appID)
  end)
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS")
    end)

  hmi:ExpectRequest("UI.AddSubMenu", pContentData[pAppId].addSubMenu.hmi)
  :ValidIf(function(_, data)
    return validateAppId("UI.AddSubMenu", hmiAppId, data.params.appID)
  end)
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS")
    end)
end

local function expResDataApp1Dev1()
  local session = common.mobile.getSession(1)
  local hmi = common.hmi.getConnection()

  session:ExpectNotification("OnHashChange")
  session:ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(2)

  hmi:ExpectRequest("BasicCommunication.ActivateApp")
  :ValidIf(function(_, data)
    return validateAppId("BasicCommunication.ActivateApp", common.app.getHMIId(1), data.params.appID)
  end)
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS")
    end)

  expectHmiContent(1, contentData)
end

local function expResDataApp1Dev2()
  local sessionDev1 = common.mobile.getSession(1)
  local sessionDev2 = common.mobile.getSession(2)

  sessionDev1:ExpectNotification("OnHashChange"):Times(0)
  sessionDev2:ExpectNotification("OnHashChange")
  sessionDev1:ExpectNotification("OnHMIStatus"):Times(0)
  sessionDev2:ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })

  expectHmiContent(2, contentData)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modificationOfPreloadedPT})
runner.Step("Start SDL and HMI 1st cycle", common.start)
runner.Step("Connect two mobile Devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from Device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App1 from Device 2", common.registerAppEx, {2, appParams[1], 2})
runner.Step("Activate App1 from Device 2", common.activateApp, {2})
runner.Step("Add command and submenu for App1 on Device 2", addContent, {2, contentData[2]})
runner.Step("Activate App1 from Device 1", common.activateApp, {1})
runner.Step("Add command and submenu for App1 on Device 1", addContent, {1, contentData[1]})

runner.Title("Test")
runner.Step("Unexpected disconnect App1 from Device 2", common.unexpectedDisconnect, {2})
runner.Step("Unexpected disconnect App1 from Device 1", common.unexpectedDisconnect, {1})
runner.Step("Resume App1 from Device 1", common.reRegisterAppEx, {1, 1, appData, expResDataApp1Dev1})
runner.Step("Resume App1 from Device 2", common.reRegisterAppEx, {2, 2, appData, expResDataApp1Dev2})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
