---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require('user_modules/utils')
local events = require("events")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Module ]]
local m = {}

--[[ Proxy Functions ]]
m.start = actions.start
m.preconditions = actions.preconditions
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.Title = runner.Title
m.Step = runner.Step
m.connectMobile = actions.mobile.connect
m.spairs = utils.spairs

--[[ Local Variables ]]
local hashId
local imageName = 'icon.png'
local fullPathToImage = actions.getPathToFileInStorage(imageName)
local imageStructureReq = {
  value = imageName,
  imageType = "DYNAMIC"
}

--[[ Common Variables ]]
m.reqAddSubMenuParams1 = {
  menuID = 1,
  position = 0,
  menuName ="SubMenupositive",
  menuLayout = "LIST"
}

m.reqAddSubMenuParams2 = {
  menuID = 2,
  menuName ="SubMenupositive",
  position = 1,
  secondaryText = "Secondary",
  tertiaryText = "Tertiary",
  menuIcon = imageStructureReq,
  secondaryImage = imageStructureReq,
  menuLayout = "TILES",
  parentID = 1
}

m.reqAddCommandParams = {
  cmdID = 1,
  vrCommands = { "vrCommand" },
  menuParams = {
    parentID = 1,
    position = 0,
    menuName = "Command",
    secondaryText = "Secondary",
    tertiaryText = "Tertiary"
  },
  cmdIcon = imageStructureReq,
  secondaryImage = imageStructureReq
}

--[[ Common Functions ]]
function m.postconditions()
  actions.mobile.closeSession()
  actions.postconditions()
end

function m.unexpectedDisconnect()
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(actions.mobile.getAppsCount())
  actions.mobile.disconnect()
  actions.run.wait(1000)
end

function m.putFile()
  local params = {
    requestParams = {
      syncFileName = imageName,
      fileType = "GRAPHIC_PNG",
      persistentFile = true,
      systemFile = false
    },
    filePath = "files/action.png"
  }
  local cid = actions.getMobileSession():SendRPC("PutFile", params.requestParams, params.filePath)
  actions.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function m.ignitionOff()
  config.ExitOnCrash = false
  local timeout = 5000
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "SDL shutdown")
  :Do(function()
      StopSDL()
      config.ExitOnCrash = true
    end)
  actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",
        { reason = "IGNITION_OFF" })
      actions.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      :Do(function()
          actions.mobile.closeSession()
        end)
    end)
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = false })
  local isSDLShutDownSuccessfully = false
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      utils.cprint(35, "SDL was shutdown successfully")
      isSDLShutDownSuccessfully = true
      RAISE_EVENT(event, event)
    end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      RAISE_EVENT(event, event)
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

function m.getParamsForUIsubMenu(pRequestParams)
  local menuParams = { "parentID", "position", "menuName", "secondaryText", "tertiaryText" }
  local out = { menuParams = {} }
  for param, value in pairs(utils.cloneTable(pRequestParams)) do
    if utils.isTableContains(menuParams, param) == true then
      out.menuParams[param] = value
    else
      out[param] = value
      if out[param] and (param == "menuIcon" or param == "secondaryImage") then
        out[param].value = fullPathToImage
      end
    end
  end
  return out
end

function m.getParamsUIcommand(pRequestParams)
  local uiParams = {}
  local vrParams
  for param, value in pairs(utils.cloneTable(pRequestParams)) do
    if param == "vrCommands" then
      vrParams = {
        cmdID = pRequestParams.cmdID,
        type = "Command",
        vrCommands = value
      }
    else
      uiParams[param] = value
      if param == "cmdIcon" or param == "secondaryImage" then
        uiParams[param].value = fullPathToImage
      end
    end
  end
  return uiParams, vrParams
end

function m.addSubMenu(pParams)
  local cid = actions.getMobileSession():SendRPC("AddSubMenu", pParams)
  local uiParams = m.getParamsForUIsubMenu(pParams)
  uiParams.appID = actions.getHMIAppId()
  actions.getHMIConnection():ExpectRequest("UI.AddSubMenu", uiParams)
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  actions.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  actions.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
end

function m.registerAppResumption(extendedFunc, pExpectedData)
  local params = utils.cloneTable(actions.getConfigAppParams())
  params.hashID = hashId
  local session = actions.mobile.createSession()
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", params)
      actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = params.appName } })
      :Do(function(_, d1)
          actions.app.setHMIId(d1.params.application.appID)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        end)
    end)
  extendedFunc(pExpectedData)
end

function m.addCommand(pParams)
  local cid = actions.getMobileSession():SendRPC("AddCommand", pParams)
  local uiParams, vrParams = m.getParamsUIcommand(pParams)
  uiParams.appID = actions.getHMIAppId()
  actions.getHMIConnection():ExpectRequest("UI.AddCommand", uiParams)
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  if vrParams then
    vrParams.appID = actions.getHMIAppId()
    actions.getHMIConnection():ExpectRequest("VR.AddCommand", vrParams)
    :Do(function(_, data)
        actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    :ValidIf(function(_, data)
        if data.params.grammarID ~= nil then
          return true
        else
          return false, "grammarID should not be empty"
        end
      end)
  end
  actions.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  actions.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
end

function m.sendWindowCapabilities()
  local onSysCaps = {
    systemCapability = {
      systemCapabilityType = "DISPLAYS",
      displayCapabilities = {
        {
          windowCapabilities = {
            {
              menuLayoutsAvailable = { "LIST", "TILES" }
            }
          }
        }
      }
    },
    appID = actions.app.getHMIId()
  }
  actions.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", onSysCaps)
end

function m.expectTwoSubMenus(pExpectedData)
  actions.getHMIConnection():ExpectRequest("UI.AddSubMenu",
    m.getParamsForUIsubMenu(m.reqAddSubMenuParams1), m.getParamsForUIsubMenu(pExpectedData))
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(2)
end

function m.expectSubMenuCommand(pExpectedData)
  actions.getHMIConnection():ExpectRequest("UI.AddSubMenu", m.getParamsForUIsubMenu(m.reqAddSubMenuParams1))
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  local uiParams, vrParams = m.getParamsUIcommand(pExpectedData)
  actions.getHMIConnection():ExpectRequest("UI.AddCommand", uiParams)
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  if vrParams then
    actions.getHMIConnection():ExpectRequest("VR.AddCommand", vrParams)
    :Do(function(_, data)
        actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
end

function m.getCommandReqParams(pParameter)
  local params = {
    cmdID = 1,
    menuParams = {
      menuName = "Command",
    }
  }
  local menuParams = { }
  for key in pairs(m.reqAddCommandParams.menuParams) do
    table.insert(menuParams, key)
  end
  if utils.isTableContains(menuParams, pParameter) then
    params.menuParams[pParameter] = m.reqAddCommandParams.menuParams[pParameter]
  else
    params[pParameter] = m.reqAddCommandParams[pParameter]
  end
  return params
end

function m.getCommandParamList(pTbl)
  local params = {}
  for key, value in pairs(pTbl) do
    if key == 'menuParams' then
      local sTbl = m.getCommandParamList(value)
      for _, skey in pairs(sTbl) do
        table.insert(params, skey)
      end
    elseif key ~= 'cmdID' and key ~= 'menuName' then
      table.insert(params, key)
    end
  end
  return params
end

function m.getSubMenuReqParams(pParam, pValue)
  local params = {
    menuID = 2,
    menuName ="SubMenu",
  }
  params[pParam] = pValue
  return params
end

return m
