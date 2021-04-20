---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local mobile_session = require('mobile_session')
local test = require("user_modules/dummy_connecttest")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Variables ]]
local m = actions
m.commandArray = {}
m.commandsLimit = 30

m.cloneTable = utils.cloneTable
m.tableToString = utils.tableToString
m.wait = utils.wait

function m.getGPParams()
  local params = {
    requestUiParams = {
      vrHelp = m.vrHelp(m.commandArray)
    },
    requestTtsParams = {
      helpPrompt = m.vrHelpPrompt(m.commandArray)
    }
  }
  return params
end

function m.customSetGPParams()
  local allParams = { }
  allParams.requestParams = {
    helpPrompt = {
      { text = "helpPrompt", type = "TEXT"}
    },
    vrHelpTitle = " Help title ",
    vrHelp = {
      { text = "vrHelp1",  position = 1 },
      { text = "vrHelp2",  position = 2 }
    }
  }

  allParams.requestUiParams = {
    vrHelp = allParams.requestParams.vrHelp,
    vrHelpTitle = allParams.requestParams.vrHelpTitle
  }

  allParams.requestTtsParams = {
    helpPrompt = allParams.requestParams.helpPrompt
  }
  return allParams
end

function m.getAddCommandParams(pN)
  local out = {
    cmdID = pN,
    vrCommands = { "vrCommand" .. pN},
    menuParams = {
      menuName = "Command" .. pN
    }
  }
  return out
end

function m.addCommand(pParams, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local hmiConnection = m.getHMIConnection()
  local cid = mobSession:SendRPC("AddCommand", pParams)
  local requestUiParams = {
    cmdID = pParams.cmdID,
    menuParams = pParams.menuParams,
    appID = m.getHMIAppId()
  }
  EXPECT_HMICALL("UI.AddCommand", requestUiParams)
  :Do(function(_,data)
    hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  if pParams.vrCommands then
    table.insert(m.commandArray, { cmdID = pParams.cmdID, vrCommand = pParams.vrCommands})
    local requestVrParams = {
      cmdID = pParams.cmdID,
      vrCommands = pParams.vrCommands,
      type = "Command",
      appID = m.getHMIAppId(pAppId)
    }
    EXPECT_HMICALL("VR.AddCommand", requestVrParams)
    :Do(function(_,data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  end
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function m.deleteCommand(pParams, pIsVRInterfaceEnabled)
  local mobSession = m.getMobileSession()
  local hmiConnection = m.getHMIConnection()
  local cid = mobSession:SendRPC("DeleteCommand", pParams)
  EXPECT_HMICALL("UI.DeleteCommand")
  :Do(function(_,data)
    hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  if pIsVRInterfaceEnabled then
    for k, v in pairs(m.commandArray) do
      if v.cmdID == pParams.cmdID then
        table.remove(m.commandArray, k)
      end
    end
    local requestVrParams = {
      cmdID = pParams.cmdID,
      type = "Command",
      appID = m.getHMIAppId()
    }
    EXPECT_HMICALL("VR.DeleteCommand", requestVrParams)
    :Do(function(_,data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  end
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function m.setGlobalProperties(pParams, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local hmiConnection = m.getHMIConnection()
  local cid = mobSession:SendRPC("SetGlobalProperties", pParams.requestParams)
  if pParams.requestParams.vrHelp or
    pParams.requestParams.keyboardProperties then
    EXPECT_HMICALL("UI.SetGlobalProperties", pParams.requestUiParams)
    :Do(function(_,data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  end
  if pParams.requestParams.helpPrompt or pParams.requestParams.timeoutPrompt then
    EXPECT_HMICALL("TTS.SetGlobalProperties", pParams.requestTtsParams)
    :Do(function(_,data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  end
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function m.setGlobalPropertiesFromSDL()
  local params = m.getGPParams()
  local hmiConnection = m.getHMIConnection()
  EXPECT_HMICALL("UI.SetGlobalProperties", params.requestUiParams)
  :Do(function(_,data)
    hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_HMICALL("TTS.SetGlobalProperties", params.requestTtsParams)
  :Do(function(_,data)
    hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

function m.activateApp(pAppId)
  if not pAppId then pAppId = 1 end
  local requestId = m.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  m.getHMIConnection():ExpectResponse(requestId)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  m.wait()
end

function m.vrHelp(pCommandArray)
  local out = {}
  local counter = 0
  for _, value in pairs(pCommandArray) do
    counter = counter + 1
    local item = {
      text = value.vrCommand[1],
      position = counter
    }
    table.insert(out, item)
    if counter == m.commandsLimit then return out end
  end
  return out
end

function m.vrHelpPrompt(pVrCommandArray)
  local out = {}
  local counter = 0
  for _, value in pairs(pVrCommandArray) do
    counter = counter + 1
    local item = {
      text = value.vrCommand[1],
      type = "TEXT"
    }
    table.insert(out, item)
    if counter == m.commandsLimit then return out end
  end
  return out
end

function m.setGlobalPropertiesDoesNotExpect()
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_HMICALL("TTS.SetGlobalProperties")
  :Times(0)
  commonTestCases:DelayedExp(11000)
end

function m.deleteCommandWithSetGP(pN)
  local params = {
    cmdID = pN
  }
  m.deleteCommand(params, true)
  m.setGlobalPropertiesFromSDL()
end

function m.deleteCommandWithoutSetGP(pN)
  local params = {
    cmdID = pN
  }
  m.deleteCommand(params, true)
  m.setGlobalPropertiesDoesNotExpect()
end

function m.addCommandWithSetGP(pN, pAddCommandParams)
  local AddCommandParams
  if not pAddCommandParams then
    AddCommandParams = m.getAddCommandParams(pN)
  else
    AddCommandParams = pAddCommandParams
  end
  m.addCommand(AddCommandParams)
  m.setGlobalPropertiesFromSDL()
end

function m.addCommandWithoutSetGP(pN, pAddCommandParams)
  local AddCommandParams
  if not pAddCommandParams then
    AddCommandParams = m.getAddCommandParams(pN)
  else
    AddCommandParams = pAddCommandParams
  end
  m.addCommand(AddCommandParams)
  m.setGlobalPropertiesDoesNotExpect()
end

function m.reconnect(pAppId)
  if not pAppId then pAppId = 1 end
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    {appID = m.getHMIAppId(pAppId), unexpectedDisconnect = true})
  actions.mobile.disconnect()
  actions.run.wait(1000)
  :Do(function()
    test.mobileSession[pAppId] = mobile_session.MobileSession(
      test,
      test.mobileConnection,
      config["application" .. pAppId].registerAppInterfaceParams)
    test.mobileConnection:Connect()
  end)
end

function m.registrationWithResumption(pAppId, pLevelResumpFunc, pDataResump)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
    local params = m.getConfigAppParams(pAppId)
    params.hashID = m.hashId
    local corId = mobSession:SendRPC("RegisterAppInterface", m.getConfigAppParams(pAppId))
    test.hmiConnection:ExpectNotification("BasicCommunication.OnAppRegistered",
      { application = { appName = m.getConfigAppParams(pAppId).appName } })
    :Do(function(_, d1)
      m.setHMIAppId(d1.params.application.appID, pAppId)
      pDataResump()
    end)
    mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      pLevelResumpFunc()
    end)
  end)
end

function m.pinOnHashChange(pAppId)
  if not pAppId then pAppId = 1 end
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Pin()
  :Times(AnyNumber())
  :Do(function(_, data)
    m.hashId = data.payload.hashID
  end)
end

function m.resumptionDataAddCommands()
  EXPECT_HMICALL("VR.AddCommand")
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    for _, value in pairs(m.commandArray) do
      if data.params.cmdID == value.cmdID then
        local vrCommandCompareResult = commonFunctions:is_table_equal(data.params.vrCommands, value.vrCommand)
        local Msg = ""
        if vrCommandCompareResult == false then
          Msg = "vrCommands in received VR.AddCommand are not match to expected result.\n" ..
          "Actual result:" .. m.tableToString(data.params.vrCommands) .. "\n" ..
          "Expected result:" .. m.tableToString(value.vrCommand) .."\n"
        end
        return vrCommandCompareResult, Msg
      end
    end
    return true
  end)
  :Times(#m.commandArray)

  EXPECT_HMICALL("TTS.SetGlobalProperties")
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_, data)
    local expectedHelpPrompt = m.vrHelpPrompt(m.commandArray)
    local vrCommandCompareResult = commonFunctions:is_table_equal(data.params.helpPrompt, expectedHelpPrompt)
    local Msg = ""
    if vrCommandCompareResult == false then
      Msg = "helpPrompt in received TTS.SetGlobalProperties is not match to expected result.\n" ..
      "Actual result:" .. m.tableToString(data.params.helpPrompt) .. "\n" ..
      "Expected result:" .. m.tableToString(expectedHelpPrompt) .."\n"
    end
    return vrCommandCompareResult, Msg
  end)

  EXPECT_HMICALL("UI.AddCommand")
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    for k, value in pairs(m.commandArray) do
      if data.params.cmdID == value.cmdID then
        return true
      elseif data.params.cmdID ~= value.cmdID and k == #m.commandArray then
        return false, "Received cmdID in UI.AddCommand was not added previously before resumption"
      end
    end
  end)
  :Times(#m.commandArray)

  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_, data)
    local expectedVrHelp = m.vrHelp(m.commandArray)
    local vrCommandCompareResult = commonFunctions:is_table_equal(data.params.vrHelp, expectedVrHelp)
    local Msg = ""
    if vrCommandCompareResult == false then
      Msg = "vrHelp in received TTS.SetGlobalProperties is not match to expected result.\n" ..
      "Actual result:" .. m.tableToString(data.params.vrHelp) .. "\n" ..
      "Expected result:" .. m.tableToString(expectedVrHelp) .."\n"
    end
    return vrCommandCompareResult, Msg
  end)
end

function m.resumptionLevelFull()
  m.getHMIConnection():ExpectNotification("BasicCommunication.ActivateApp", { appID = m.getHMIAppId() })
  :Do(function(_,data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(2)
end



return m
