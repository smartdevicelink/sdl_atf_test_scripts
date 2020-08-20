---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ Variables ]]
local m = actions
m.type = "FILE"

--[[ Functions]]
function m.pTUpdateFunc(pTbl)
  pTbl.policy_table.functional_groupings["Base-4"].rpcs.ShowAppMenu = nil
end

function m.addSubMenu(pMenuID)
  local cid = m.getMobileSession():SendRPC("AddSubMenu",
    {
      menuID = pMenuID,
      position = 500,
      menuName ="SubMenupositive"
    })
    m.getHMIConnection():ExpectRequest("UI.AddSubMenu",
      {
        menuID = pMenuID,
        menuParams = {
          position = 500,
          menuName ="SubMenupositive"
        }
      })
  :Do(function(_,data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession():ExpectNotification("OnHashChange",{})
end

function m.showAppMenuSuccess(pMenuID)
  local cid = m.getMobileSession():SendRPC("ShowAppMenu", { menuID = pMenuID })
  m.getHMIConnection():ExpectRequest("UI.ShowAppMenu", { appID = m.getHMIAppId(), menuID = pMenuID })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function m.showAppMenuUnsuccess(pMenuID, pResultCode, infoExists)
  local cid = m.getMobileSession():SendRPC("ShowAppMenu", { menuID = pMenuID })
  m.getHMIConnection():ExpectRequest("UI.ShowAppMenu")
  :Times(0)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode })
  :ValidIf(function(_,data)
    if (infoExists == true) then
      return data.payload.info ~= nil
    else
      return true
    end
  end)
  m.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
end

function m.showAppMenuHMIwithoutResponse(pMenuID)
  local cid = m.getMobileSession():SendRPC("ShowAppMenu", { menuID = pMenuID })
  m.getHMIConnection():ExpectRequest("UI.ShowAppMenu", { appID = m.getHMIAppId(), menuID = pMenuID })
  :Do(function()
    -- HMI did not response
  end)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  m.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
end

function m.changeHMISystemContext(pSystemContext)
  m.getHMIConnection():SendNotification("UI.OnSystemContext", { systemContext = pSystemContext })
  m.getMobileSession():ExpectNotification("OnHMIStatus", { systemContext = pSystemContext, hmiLevel = "FULL" })
end

function m.deactivateAppToBackground(pSystemContext)
  if not pSystemContext then pSystemContext = "MAIN" end
  m.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "AUDIO_SOURCE", isActive = true })
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = pSystemContext })
end

function m.hmiLeveltoLimited(pAppId, pSystemContext)
  if not pAppId then pAppId = 1 end
  m.getHMIConnection(pAppId):SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = m.getHMIAppId(pAppId) })
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = pSystemContext })
end

return m
