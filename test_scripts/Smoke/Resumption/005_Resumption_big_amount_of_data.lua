--  Requirement summary:
--  [Data Resumption]: Data Persistance
--
--  Description:
--  Check that SDL perform resumption with a big amount of data
--  after unexpected disconnect.
--
--  1. Used precondition
--  App is registered and activated on HMI.
--  20 SubMenus, 20 commands, 20 choice sets are added successfully.
--
--  2. Performed steps
--  Turn off transport.
--  Turn on transport.
--
--  Expected behavior:
--  1. App is unregistered successfully.
--     App is registered successfully,  SDL sends OnAppRegistered on HMI with "resumeVrGrammars"=true.
--     SDL resumes all app's data and sends BC.ActivateApp to HMI. App gets FULL HMI Level
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Functions ]]
function common.addCommand(pId)
  local params = { cmdID = pId, vrCommands = { "OnlyVRCommand_" .. pId }}
  local cid = common.getMobileSession():SendRPC("AddCommand", params)
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.hashId = data.payload.hashID
    end)
end

function common.addSubMenu(pId)
  local params = { menuID = pId, position = 500, menuName = "SubMenu_" .. pId }
  local cid = common.getMobileSession():SendRPC("AddSubMenu", params)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.hashId = data.payload.hashID
    end)
end

local function expResData()
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
  :Times(20)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
  :Times(20)
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function expResLvl()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(2)
end

local function onCommand()
  common.getHMIConnection():SendNotification("UI.OnCommand", { cmdID = 20, appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnCommand", { cmdID = 20, triggerSource= "MENU" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
for i = 1, 20 do
  runner.Step("Add Command " .. i, common.addCommand, { i })
end
for i = 1, 20 do
  runner.Step("Add SubMenu " .. i, common.addSubMenu, { i })
end

runner.Title("Test")
runner.Step("Unexpected Disconnect", common.unexpectedDisconnect)
runner.Step("ReRegister App", common.reregisterApp, { "SUCCESS", expResData, expResLvl })
runner.Step("OnCommand", onCommand)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
