---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local m = {}

m.appType = {
  MEDIA = { hmiType = "MEDIA", isMedia = true },
  NAVIGATION = { hmiType = "NAVIGATION", isMedia = true },
  DEFAULT = { hmiType = "DEFAULT", isMedia = false }
}

--[[ Shared Functions ]]
m.Title = runner.Title
m.Step = runner.Step

m.start = actions.start
m.mobile = actions.mobile
m.hmi = actions.hmi
m.app = actions.app

m.preconditions = actions.preconditions
m.postconditions = actions.postconditions

m.wait = actions.run.wait
m.runAfter = actions.run.runAfter

--[[ Common Functions ]]
function m.unexpectedDisconnect()
  m.mobile.closeSession()
  m.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  utils.wait(1000)
end

function m.setAppHMILevel(pHMILevel, pAppId)
  if pHMILevel == "NONE" then return end
  if not pHMILevel then pHMILevel = "FULL" end
  if not pAppId then pAppId = 1 end
  if pHMILevel ~= "FULL" then
    m.mobile.getSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "FULL" }, { hmiLevel = pHMILevel })
    :Times(2)
  else
    m.mobile.getSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "FULL" })
  end
  local cid = m.hmi.getConnection():SendRequest("SDL.ActivateApp", { appID = m.app.getHMIId(pAppId) })
  m.hmi.getConnection():ExpectResponse(cid)
  :Do(function()
      if pHMILevel ~= "FULL" then
        m.hmi.getConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = m.app.getHMIId(pAppId) })
      end
    end)
  m.wait(500)
end

function m.checkHMILevelResumption(pHMILevel)
  if pHMILevel == nil then
    m.mobile.getSession():ExpectNotification("OnHMIStatus"):Times(0)
    m.hmi.getConnection():ExpectRequest("BasicCommunication.ActivateApp"):Times(Between(0,1))
  elseif pHMILevel == "LIMITED" then
    m.mobile.getSession():ExpectNotification("OnHMIStatus", { hmiLevel = "LIMITED" })
    m.hmi.getConnection():ExpectRequest("BasicCommunication.ActivateApp"):Times(0)
  elseif pHMILevel == "FULL" then
    m.mobile.getSession():ExpectNotification("OnHMIStatus", { hmiLevel = "FULL" })
    m.hmi.getConnection():ExpectRequest("BasicCommunication.ActivateApp")
    :Do(function(_, data)
        m.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
  else
    utils.cprint(35, "Unexpected HMI level defined")
  end
  m.wait(3500)
end

function m.registerApp(pAppType, pAppId)
  if not pAppId then pAppId = 1 end
  m.app.getParams(pAppId).appHMIType = { m.appType[pAppType].hmiType }
  m.app.getParams(pAppId).isMediaApplication = m.appType[pAppType].isMedia
  m.app.registerNoPTU(pAppId)
end

function m.activateApp(pExpLevel, pAppId)
  if not pAppId then pAppId = 1 end
  local requestId = m.hmi.getConnection():SendRequest("SDL.ActivateApp", { appID = m.app.getHMIId(pAppId) })
  m.hmi.getConnection():ExpectResponse(requestId)
  local expOccurence = 1
  if pExpLevel == nil then expOccurence = 0 end
  m.mobile.getSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = pExpLevel }):Times(expOccurence)
  m.wait(500)
end

return m
