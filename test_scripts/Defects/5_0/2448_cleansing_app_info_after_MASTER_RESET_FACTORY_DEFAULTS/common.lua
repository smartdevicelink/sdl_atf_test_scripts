--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local sdl = require("SDL")
local runner = require("user_modules/script_runner")

--[[ Module ]]
local m = {}

--[[ Test configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
m.preconditions = actions.preconditions
m.start = actions.start
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.policyTableUpdate = actions.policyTableUpdate
m.AddSubMenu = actions.AddSubMenu
m.postconditions = actions.postconditions
m.Title = runner.Title
m.Step = runner.Step
m.getHMIConnection = actions.getHMIConnection
m.getMobileSession = actions.getMobileSession
m.disconnect = actions.mobile.disconnect
m.hashID = 0

--[[ Local Functions ]]
function m.waitUntilResumptionDataIsStored()
  utils.wait(actions.sdl.getSDLIniParameter("AppSavePersistentDataTimeout"))
end

function m.shutignDown(pReason)
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = pReason })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      sdl:StopSDL()
    end)
end

function m.appResumption(isPTU)
  local session = actions.mobile.createSession()
  session:StartService(7)
  :Do(function()
      if m.hashID ~= 0 then actions.app.getParams().hashID = m.hashID end
      local corId = session:SendRPC("RegisterAppInterface", actions.app.getParams())
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = actions.app.getParams().appName } })
      :Do(function()
          if isPTU == true then
            actions.ptu.expectStart()
          end
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "RESUME_FAILED" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          session:ExpectNotification("OnPermissionsChange")
          :Times(AnyNumber())
        end)
    end)

  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)
end

function m.AddSubMenu()
  local requestParams = {
    menuID = 1000,
    position = 500,
    menuName ="SubMenupositive"
  }

  local corId = m.getMobileSession():SendRPC("AddSubMenu", requestParams)
  m.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  m.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS"})
  m.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashID = data.payload.hashID
    end)
end

return m
