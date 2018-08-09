---------------------------------------------------------------------------------------------------
-- common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local test = require("user_modules/dummy_connecttest")
local events = require('events')
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local json = require("modules/json")
local sdl = require("SDL")

--[[ Common Variables ]]
local m = actions
m.cloneTable = utils.cloneTable
m.wait = utils.wait

m.hashId = {}
m.resumptionData = {
  [1] = {},
  [2] = {}
}

local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

m.rpcs = {
  addCommand = { "UI", "VR" },
  addSubMenu = { "UI" },
  createIntrerationChoiceSet = { "VR" },
  setGlobalProperties = { "UI", "TTS" },
  subscribeVehicleData = { "VehicleInfo" },
  subscribeWayPoints = { "Navigation" }
}

--[[ Common Functions ]]

--[[ @waitUntilResumptionDataIsStored: wait some time until SDL saves resumption data
--! @parameters: none
--! @return: none
--]]
function m.waitUntilResumptionDataIsStored()
  utils.cprint(35, "Wait ...")
  local timeoutToSafe = commonFunctions:read_parameter_from_smart_device_link_ini("AppSavePersistentDataTimeout")
  local fileName = commonPreconditions:GetPathToSDL()
  .. commonFunctions:read_parameter_from_smart_device_link_ini("AppInfoStorage")
  local function isFileExist()
    local f = io.open(fileName, "r")
    if f ~= nil then
      io.close(f)
      m.wait(timeoutToSafe + 1000)
      return true
    else
      return false
    end
  end
  while not isFileExist() do
    os.execute("sleep 1")
  end
end

--[[ @checkResumptionData: checks resumption data and answer with error to defined RPC
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponceRpc - RPC for response with errorCode
--! pErrorResponseInterface - interface of RPC for response with errorCode
--! @return: none
--]]
function m.checkResumptionData(pAppId, pErrorResponceRpc, pErrorResponseInterface)
  for rpc in pairs(m.resumptionData[pAppId]) do
    if pErrorResponceRpc == rpc then
      m[rpc .. "Resumption"](pAppId, pErrorResponseInterface)
    else
      m[rpc .. "Resumption"](pAppId)
    end
  end
end

--[[ @resumptionFullHMILevel: checks resumption to full HMI level
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.resumptionFullHMILevel(pAppId)
  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
  :Times(2)
end

--[[ @getRpcName: construct RPC name for HMI messages
--! @parameters:
--! pRpcName - name of RPC
--! pInterfaceName - name of RPC interface
--! @return: none
--]]
function m.getRpcName(pRpcName, pInterfaceName)
  local rpcName = pRpcName:gsub("^%l", string.upper)
  return pInterfaceName .. "." .. rpcName
end

--[[ @sendResponseWithDelay: sending error response with delay
--! @parameters:
--! pData - data from received request
--! @return: none
--]]
function m.sendResponseWithDelay(pData)
  local function resp()
    m.getHMIConnection():SendError(pData.id, pData.method, "GENERIC_ERROR", "info message")
  end
  RUN_AFTER(resp, 1500)
end

m.removeData = {
  DeleteUICommand = function(pAppId)
    local deleteCommandRequestParams = { }
    deleteCommandRequestParams.cmdID = m.resumptionData[pAppId].addCommand.UI.cmdID
    deleteCommandRequestParams.appID = m.resumptionData[pAppId].addCommand.UI.appID
    m.getHMIConnection():ExpectRequest("UI.DeleteCommand", deleteCommandRequestParams)
    :Do(function(_,deleteData)
        m.sendResponse(deleteData)
      end)
  end,
  DeleteVRCommand = function(pAppId, pRequestType, pTimes)
    if not pTimes then pTimes = 2 end
    local deleteCommandRequestParams
    if pRequestType == "Choice" then
      deleteCommandRequestParams = m.cloneTable(m.resumptionData[pAppId].createIntrerationChoiceSet.VR)
    else
      deleteCommandRequestParams = m.cloneTable(m.resumptionData[pAppId].addCommand.VR)
    end
    deleteCommandRequestParams.vrCommands = nil
    m.getHMIConnection():ExpectRequest("VR.DeleteCommand", deleteCommandRequestParams)
    :Do(function(_,deleteData)
        m.sendResponse(deleteData)
      end)
    :Times(pTimes)
  end,
  DeleteSubMenu = function(pAppId)
    local deleteSubMenuRequestParams = {}
    deleteSubMenuRequestParams.menuID = m.resumptionData[pAppId].addSubMenu.UI.menuID
    deleteSubMenuRequestParams.appID = m.resumptionData[pAppId].addSubMenu.UI.appID
    m.getHMIConnection():ExpectRequest("UI.DeleteSubMenu", deleteSubMenuRequestParams)
    :Do(function(_,deleteData)
        m.sendResponse(deleteData)
      end)
  end,
  UnsubscribeVehicleData = function(pAppId)
    m.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", m.resumptionData[pAppId].subscribeVehicleData.VehicleInfo)
    :Do(function(_,deleteData)
        m.sendResponse(deleteData)
      end)
  end,
  UnsubscribeWayPoints = function(pAppId, pTimes)
    if not pTimes then pTimes = 1 end
    m.getHMIConnection():ExpectRequest("Navigation.UnsubscribeWayPoints", m.resumptionData[pAppId].subscribeWayPoints.Navigation)
    :Do(function(_,deleteData)
        m.sendResponse(deleteData)
      end)
    :Times(pTimes)
  end
}

m.rpcsRevert = {
  addCommand = {
    UI = function(pAppId, pTimes)
      if not pTimes then pTimes = 1 end
      m.getHMIConnection():ExpectRequest("UI.AddCommand",m.resumptionData[pAppId].addCommand.UI)
      :Do(function(_, data)
          m.sendResponse(data)
          m.removeData.DeleteUICommand(pAppId)
        end)
      :Times(pTimes)
    end,
    VR = function(pAppId, pTimes)
      if not pTimes then pTimes = 2 end
      m.getHMIConnection():ExpectRequest("VR.AddCommand")
      :Do(function(_, data)
          m.sendResponse(data)
          m.removeData.DeleteVRCommand(pAppId, data.params.type)
        end)
      :ValidIf(function(_, data)
          if data.params.type == "Choice" then
            if commonFunctions:is_table_equal(data.params, m.resumptionData[pAppId].createIntrerationChoiceSet.VR) == false then
              return false, "Params in VR.AddCommand with type = Choice are not match to expected result.\n" ..
              "Actual result:" .. m.tableToString(data.params) .. "\n" ..
              "Expected result:" .. m.tableToString(m.resumptionData[pAppId].createIntrerationChoiceSet.VR) .."\n"
            end
          else
            if commonFunctions:is_table_equal(data.params, m.resumptionData[pAppId].addCommand.VR) == false then
              return false, "Params in VR.AddCommand with type = Command are not match to expected result.\n" ..
              "Actual result:" .. m.tableToString(data.params) .. "\n" ..
              "Expected result:" .. m.tableToString(m.resumptionData[pAppId].addCommand.VR) .."\n"
            end
          end
          return true
        end)
      :Times(pTimes)
    end,
  },
  addSubMenu = {
    UI = function(pAppId, pTimes)
      if not pTimes then pTimes = 1 end
      m.getHMIConnection():ExpectRequest("UI.AddSubMenu",m.resumptionData[pAppId].addSubMenu.UI)
      :Do(function(_, data)
          m.sendResponse(data)
          m.removeData.DeleteSubMenu(pAppId)
        end)
      :Times(pTimes)
    end
  },
  setGlobalProperties = {
    TTS = function(pAppId, pTimes)
      if not pTimes then pTimes = 2 end
      m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties")
      :Do(function(data)
          m.sendResponse(data)
        end)
      :ValidIf(function(exp, data)
          if exp.occurences == 1 then
            if commonFunctions:is_table_equal(data.params, m.resumptionData[pAppId].setGlobalProperties.TTS) == true then
              return true
            else
              return false, "Params in TTS.SetGlobalProperties are not match to expected result.\n" ..
              "Actual result:" .. m.tableToString(data.params) .. "\n" ..
              "Expected result:" .. m.tableToString(m.resumptionData[pAppId].setGlobalProperties.TTS) .."\n"
            end
          else
            local resetData = {}
            if commonFunctions:is_table_equal(data.params, resetData) == true then
              return true
            else
              return false, "Params in TTS.SetGlobalProperties are not match to expected result.\n" ..
              "Actual result:" .. m.tableToString(data.params) .. "\n" ..
              "Expected result:" .. m.tableToString(resetData) .."\n"
            end
          end
        end)
      :Times(pTimes)
    end,
    UI = function(pAppId, pTimes)
      if not pTimes then pTimes = 2 end
      m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties")
      :Do(function(data)
          m.sendResponse(data)
        end)
      :ValidIf(function(exp, data)
          if exp.occurences == 1 then
            if commonFunctions:is_table_equal(data.params, m.resumptionData[pAppId].setGlobalProperties.UI) == true then
              return true
            else
              return false, "Params in UI.SetGlobalProperties are not match to expected result.\n" ..
              "Actual result:" .. m.tableToString(data.params) .. "\n" ..
              "Expected result:" .. m.tableToString(m.resumptionData[pAppId].setGlobalProperties.UI) .."\n"
            end
          else
            local resetData = {}
            if commonFunctions:is_table_equal(data.params, resetData) == true then
              return true
            else
              return false, "Params in UI.SetGlobalProperties are not match to expected result.\n" ..
              "Actual result:" .. m.tableToString(data.params) .. "\n" ..
              "Expected result:" .. m.tableToString(resetData) .."\n"
            end
          end
        end)
      :Times(pTimes)
    end
  },
  subscribeVehicleData = {
    VehicleInfo = function(pAppId,pTimes)
      if not pTimes then pTimes = 1 end
      m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData",m.resumptionData[pAppId].subscribeVehicleData.VehicleInfo)
      :Do(function(_, data)
          m.sendResponse(data)
          m.removeData.UnsubscribeVehicleData(pAppId)
        end)
      :Times(pTimes)
    end
  },
  subscribeWayPoints = {
    Navigation = function(pAppId, pTimes)
      if not pTimes then pTimes = 1 end
      m.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints",m.resumptionData[pAppId].subscribeWayPoints.Navigation)
      :Do(function(_, data)
          m.sendResponse(data)
          m.removeData.UnsubscribeWayPoints(pAppId)
        end)
      :Times(pTimes)
    end
  }
}

--[[ @checkResumptionDataWithErrorResponse: check resumption data for with error response to defined rpc and
--! checking reverting already added data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponceRpc - RPC name for error response
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
]]
function m.checkResumptionDataWithErrorResponse(pAppId, pErrorResponceRpc, pErrorResponseInterface)

  local rpcsRevertLocal = m.cloneTable(m.rpcsRevert)
  if pErrorResponceRpc == "addCommand" and pErrorResponseInterface == "VR" then
    rpcsRevertLocal.addCommand.VR = nil
    m.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        if data.params.type == "Command" then
          m.sendResponseWithDelay(data)
        else
          m.sendResponse(data)
        end
        if data.params.type == "Choice" then
          m.removeData.DeleteVRCommand(pAppId, data.params.type, 1)
        end
      end)
    :Times(2)
  elseif pErrorResponceRpc == "createIntrerationChoiceSet" then
    rpcsRevertLocal.addCommand.VR = nil
    m.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        if data.params.type == "Choice" then
          m.sendResponseWithDelay(data)
        else
          m.sendResponse(data)
        end
        if data.params.type == "Command" then
          m.removeData.DeleteVRCommand(pAppId, data.params.type, 1)
        end
      end)
    :Times(2)
  else
    rpcsRevertLocal[pErrorResponceRpc][pErrorResponseInterface] = nil
    m.getHMIConnection():ExpectRequest(m.getRpcName(pErrorResponceRpc, pErrorResponseInterface))
    :Do(function(_, data)
        m.sendResponseWithDelay(data, pErrorResponseInterface, pErrorResponseInterface)
      end)
  end

  for k, value in pairs (rpcsRevertLocal) do
    if m.resumptionData[pAppId][k] then
      for interface in pairs (value) do
        rpcsRevertLocal[k][interface](pAppId)
      end
    end
  end

end

--[[ @reRegisterApp: re-register application with RESUME_FAILED resultCode
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pCheckResumptionData - verification function for resumption data
--! pCheckResumptionHMILevel - verification function for resumption HMI level
--! pErrorResponceRpc - RPC name for error response
--! pErrorResponseInterface - interface of RPC for error response
--! pRAIResponseExp - time for expectation of RAI response
--! @return: none
--]]
function m.reRegisterApp(pAppId, pCheckResumptionData, pCheckResumptionHMILevel, pErrorResponceRpc, pErrorResponseInterface, pRAIResponseExp)
  if not pAppId then pAppId = 1 end
  if not pRAIResponseExp then pRAIResponseExp = 5000 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = m.cloneTable(config["application" .. pAppId].registerAppInterfaceParams)
      params.hashID = m.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName }
        })
      mobSession:ExpectResponse(corId, { success = true, resultCode = "RESUME_FAILED" })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
      :Timeout(pRAIResponseExp)
    end)
  pCheckResumptionData(pAppId, pErrorResponceRpc, pErrorResponseInterface)
  pCheckResumptionHMILevel(pAppId)
end

--[[ @reRegisterAppSuccess: re-register application with SUCCESS resultCode
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pCheckResumptionData - verification function for resumption data
--! pCheckResumptionHMILevel - verification function for resumption HMI level
--! @return: none
--]]
function m.reRegisterAppSuccess(pAppId, pCheckResumptionData, pCheckResumptionHMILevel)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = m.cloneTable(config["application" .. pAppId].registerAppInterfaceParams)
      params.hashID = m.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName }
        })
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
  pCheckResumptionData(pAppId)
  pCheckResumptionHMILevel(pAppId)
end

--[[ @sendResponse: sending success and error resultCode to defined RPCs
--! @parameters:
--! pData - data from received request
--! pErrorRespInterface - interface of RPC for error response
--! pCurrentInterface - current interface of RPC
--! @return: none
--]]
function m.sendResponse(pData, pErrorRespInterface, pCurrentInterface)
  if pErrorRespInterface ~= nil and pErrorRespInterface == pCurrentInterface then
    m.getHMIConnection():SendError(pData.id, pData.method, "GENERIC_ERROR", "info message")
  else
    m.getHMIConnection():SendResponse(pData.id, pData.method, "SUCCESS", {})
  end
end

--[[ @addCommand: adding command
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.addCommand(pAppId)
  if not pAppId then pAppId = 1 end
  local params = {
    cmdID = pAppId,
    vrCommands = { "vr" .. m.getConfigAppParams(pAppId).appName },
    menuParams = { menuName = "command" .. m.getConfigAppParams(pAppId).appName}

  }
  m.resumptionData[pAppId]["addCommand"] = {}
  local cid = m.getMobileSession(pAppId):SendRPC("AddCommand", params)
  m.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].addCommand.VR = data.params
    end)
  m.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].addCommand.UI = data.params
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
  -- wait for SetGlobalproperties requests from SDL during AddCommand to not affect another case with SetGP
  m.wait(300)
end

--[[ @addSubMenu: adding subMenu
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.addSubMenu(pAppId)
  if not pAppId then pAppId = 1 end
  local params = {
    menuID = pAppId,
    position = 500,
    menuName = "SubMenu" .. m.getConfigAppParams(pAppId).appName
  }
  local cid = m.getMobileSession(pAppId):SendRPC("AddSubMenu", params)
  m.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].addSubMenu = { UI = data.params }
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @createIntrerationChoiceSet: adding createIntrerationChoiceSet
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.createIntrerationChoiceSet(pAppId)
  if not pAppId then pAppId = 1 end
  local choice = {
    choiceID = pAppId,
    menuName = "Choice" .. m.getConfigAppParams(pAppId).appName,
    vrCommands = { "VrChoice" ..m.getConfigAppParams(pAppId).appName }
  }
  local cid = m.getMobileSession(pAppId):SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = pAppId,
      choiceSet = { choice }
    })
  m.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].createIntrerationChoiceSet = { VR = data.params }
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @setGlobalProperties: adding setGlobalProperties
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.setGlobalProperties(pAppId)
  if not pAppId then pAppId = 1 end
  local params = {
    helpPrompt = {
      {
        text = "Help prompt" .. pAppId,
        type = "TEXT"
      }
    },
    timeoutPrompt = {
      {
        text = "Timeout prompt" .. pAppId,
        type = "TEXT"
      }
    },
    vrHelpTitle = "VR help title" .. pAppId,
    vrHelp = {
      {
        position = 1,
        text = "VR help item" .. pAppId
      }
    },
    menuTitle = "Menu Title" .. pAppId,
  }
  local cid = m.getMobileSession(pAppId):SendRPC("SetGlobalProperties", params)
  m.resumptionData[pAppId].setGlobalProperties = {}
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].setGlobalProperties.UI = data.params
    end)

  EXPECT_HMICALL("TTS.SetGlobalProperties")
  :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].setGlobalProperties.TTS = data.params
    end)

  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @subscribeVehicleData: adding subscribeVehicleData
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.subscribeVehicleData(pAppId, pParams, pHMIrequest)
  if not pAppId then pAppId = 1 end
  if not pParams then
    pParams = {
      requestParams = { gps = true },
      responseParams = { gps = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"} }
    }
  end
  if not pHMIrequest then pHMIrequest = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("SubscribeVehicleData", pParams.requestParams)
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", pParams.responseParams)
      m.resumptionData[pAppId].subscribeVehicleData = { VehicleInfo = data.params }
    end)
  :Times(pHMIrequest)
  local MobResp = pParams.responseParams
  MobResp.success = true
  MobResp.resultCode = "SUCCESS"
  m.getMobileSession(pAppId):ExpectResponse(cid, MobResp)
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @subscribeWayPoints: adding subscribeWayPoints
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.subscribeWayPoints(pAppId, pHMIrequest)
  if not pAppId then pAppId = 1 end
  if not pHMIrequest then pHMIrequest = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].subscribeWayPoints = { Navigation = data.params }
    end)
  :Times(pHMIrequest)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @buttonSubscription: adding buttonSubscription
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.buttonSubscription(pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("SubscribeButton", {buttonName = "OK"})
  EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @addCommandResumption: check resumption of addCommand data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.addCommandResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("VR.AddCommand", m.resumptionData[pAppId].addCommand.VR)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "VR")
    end)
  m.getHMIConnection():ExpectRequest("UI.AddCommand",m.resumptionData[pAppId].addCommand.UI)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "UI")
    end)
end

--[[ @addSubMenuResumption: check resumption of subMenu data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.addSubMenuResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("UI.AddSubMenu",m.resumptionData[pAppId].addSubMenu.UI)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "UI")
    end)
end

--[[ @createIntrerationChoiceSetResumption: check resumption of choiceSet data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.createIntrerationChoiceSetResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("VR.AddCommand", m.resumptionData[pAppId].createIntrerationChoiceSet.VR)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "VR")
    end)
end

--[[ @setGlobalPropertiesResumption: check resumption of globalProperties data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.setGlobalPropertiesResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", m.resumptionData[pAppId].setGlobalProperties.UI)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "UI")
    end)
  m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties",m.resumptionData[pAppId].setGlobalProperties.TTS)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "TTS")
    end)
end

--[[ @subscribeVehicleDataResumption: check resumption of subscribeVehicleDat data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.subscribeVehicleDataResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", m.resumptionData[pAppId].subscribeVehicleData.VehicleInfo)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "VehicleInfo")
    end)
end

--[[ @subscribeWayPointsResumption: check resumption of subscribeWayPoints data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.subscribeWayPointsResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints", m.resumptionData[pAppId].subscribeWayPoints.Navigation)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "Navigation")
    end)
end

--[[ @unregisterAppInterface: unregister app
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.unregisterAppInterface(pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("UnregisterAppInterface",{})
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  :Do(function()
      m.cleanSessions(pAppId)
      m.resumptionData[pAppId] = {}
    end)
end

--[[ @unexpectedDisconnect: closing connection
--! @parameters: none
--! @return: none
--]]
function m.unexpectedDisconnect()
  test.mobileConnection:Close()
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Do(function()
      for i = 1, m.getAppsCount() do
        test.mobileSession[i] = nil
      end
    end)
end

--[[ @connectMobile: create connection
--! @parameters: none
--! @return: none
--]]
function m.connectMobile()
  test.mobileConnection:Connect()
  EXPECT_EVENT(events.connectedEvent, "Connected")
  :Do(function()
      utils.cprint(35, "Mobile connected")
    end)
end

--[[ @cleanSessions: stop sessions and remove them
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.cleanSessions(pAppId)
  if pAppId then
    test.mobileSession[pAppId]:Stop()
    test.mobileSession[pAppId] = nil
  else
    for i = 1, m.getAppsCount() do
      test.mobileSession[i]:Stop()
      test.mobileSession[i] = nil
    end
  end
  utils.wait()
end

--[[ @preconditions: delete logs, backup preloaded file, update preloaded
--! @parameters: none
--! @return: none
--]]
function m.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
  commonPreconditions:BackupFile(preloadedPT)
  m.updatePreloadedPT()
end

--[[ @updatePreloadedPT: update preloaded file with permissions for "SubscribeVehicleData", "UnsubscribeVehicleData", "SubscribeWayPoints", "UnsubscribeWayPoints"
--! @parameters: none
--! @return: none
--]]
function m.updatePreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  local additionalRPCs = {
    "SubscribeVehicleData", "UnsubscribeVehicleData", "SubscribeWayPoints", "UnsubscribeWayPoints"
  }
  pt.policy_table.functional_groupings.NewTestCaseGroup = { rpcs = { } }
  for _, v in pairs(additionalRPCs) do
    pt.policy_table.functional_groupings.NewTestCaseGroup.rpcs[v] = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
    }
  end
  pt.policy_table.app_policies.default.groups = { "Base-4", "NewTestCaseGroup" }
  utils.tableToJsonFile(pt, preloadedFile)
end

--[[ @postconditions: stop SDL, restore preloaded file
--! @parameters: none
--! @return: none
--]]
function m.postconditions()
  StopSDL()
  commonPreconditions:RestoreFile(preloadedPT)
end

--[[ @ignitionOff: perform ignition off
--! @parameters: none
--! @return: none
--]]
function m.ignitionOff()
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete"):Do(function()
      sdl:DeleteFile()
      m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      for i=1, m.getAppsCount() do
        m.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      end
    end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(m.getAppsCount())
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
      m.cleanSessions()
      StopSDL()
    end)
end

--[[ @openRPCservice: open RPC service
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.openRPCservice(pAppId)
  m.getMobileSession(pAppId):StartService(7)
end

--[[ @reRegisterApps: reregister 2 apps
--! @parameters:
--! pCheckResumptionData - verification function for resumption data
--! pErrorRpc - RPC name for error response
--! pErrorInterface - interface of RPC for error response
--! pRAIResponseExp - time for expectation of RAI response
--! @return: none
--]]
function m.reRegisterApps(pCheckResumptionData, pErrorRpc, pErrorInterface, pRAIResponseExp)
  local requestParams1 = m.cloneTable(m.getConfigAppParams(1))
  requestParams1.hashID = m.hashId[1]

  local requestParams2 = m.cloneTable(m.getConfigAppParams(2))
  requestParams2.hashID = m.hashId[2]

  if not pRAIResponseExp then pRAIResponseExp = 5000 end

  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Do(function(exp, d1)
      if d1.params.appName == m.getConfigAppParams(1).appName then
        m.setHMIAppId(d1.params.application.appID, 1)
      else
        m.setHMIAppId(d1.params.application.appID, 2)
      end
      if exp.occurences == 1 then
        local corId2 = m.getMobileSession(2):SendRPC("RegisterAppInterface", requestParams2)
        m.getMobileSession(2):ExpectResponse(corId2, { success = true, resultCode = "SUCCESS" })
      end
    end)
  :Times(2)

  local corId1 = m.getMobileSession(1):SendRPC("RegisterAppInterface", requestParams1)
  m.getMobileSession(1):ExpectResponse(corId1, { success = true, resultCode = "RESUME_FAILED" })
  :Timeout(pRAIResponseExp)

  pCheckResumptionData(pErrorRpc, pErrorInterface)
end

--[[ @checkResumptionData2Apps: check resumption data for 2 apps
--! @parameters:
--! pErrorRpc - RPC name for error response
--! pErrorInterface - interface of RPC for error response
--! @return: none
--]]
function m.checkResumptionData2Apps(pErrorRpc, pErrorInterface)
  local uiSetGPtimes = 2
  local ttsSetGPtimes = 2
  if pErrorRpc == "setGlobalProperties" then
    if pErrorInterface == "UI" then
      ttsSetGPtimes = 3
    else
      uiSetGPtimes = 3
    end
  end

  local revertRpcToUpdate = m.cloneTable(m.removeData)
  revertRpcToUpdate.UnsubscribeWayPoints = nil

  if (pErrorRpc == "addCommand" and pErrorInterface == "VR") or
  pErrorRpc == "createIntrerationChoiceSet" then
    revertRpcToUpdate.DeleteVRCommand = nil
  elseif pErrorRpc == "addCommand" and pErrorInterface == "UI" then
    revertRpcToUpdate.DeleteUICommand = nil
  elseif
    pErrorRpc == "addSubMenu" then
      revertRpcToUpdate.DeleteSubMenu = nil
    elseif
      pErrorRpc == "subscribeVehicleData" then
        revertRpcToUpdate.UnsubscribeVehicleData = nil
      end

      for k in pairs(revertRpcToUpdate) do
        revertRpcToUpdate[k](1)
      end

      m.getHMIConnection():ExpectRequest("VR.AddCommand")
      :Do(function(_, data)
          m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
        end)
      :Times(4)

      m.getHMIConnection():ExpectRequest("UI.AddCommand")
      :Do(function(_, data)
          m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
        end)
      :Times(2)

      m.getHMIConnection():ExpectRequest("UI.AddSubMenu")
      :Do(function(_, data)
          m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
        end)
      :Times(2)

      m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties")
      :Do(function(_, data)
          m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
        end)
      :Times(uiSetGPtimes)

      m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties")
      :Do(function(_, data)
          m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
        end)
      :Times(ttsSetGPtimes)

      m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData")
      :Do(function(_, data)
          m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
        end)
      :Times(2)
    end

    --[[ @getErrorResponseStatus: define RPC for sending error response
    --! @parameters:
    --! pData - data from received request
    --! pErrorRpc - RPC name for error response
    --! pErrorInterface - interface of RPC for error response
    --! @return: none
    --]]
    local function getErrorResponseStatus(pData, pErrorRpc, pErrorInterface)
      local rpc = m.getRpcName(pErrorRpc, pErrorInterface)
      if pErrorRpc == "createIntrerationChoiceSet" then rpc = "VR.AddCommand" end
      if rpc == pData.method then
        if rpc ~= "VR.AddCommand" and pErrorRpc ~= "setGlobalProperties" then
          return true
        elseif pErrorRpc == "createIntrerationChoiceSet" and pData.params.type == "Choice" then
          m.removeData.DeleteVRCommand(1, "Command", 1 )
          return true
        elseif pErrorRpc == "addCommand" and pData.params.type == "Command" then
          m.removeData.DeleteVRCommand(1, "Choice", 1 )
          return true
        elseif pErrorRpc == "setGlobalProperties" then
          local helpPromptText = "Help prompt1"
          local vrHelpTitle ="VR help title1"
          if pData.method == "TTS.SetGlobalProperties" then
            if pErrorInterface == "TTS" and pData.params.helpPrompt[1].text == helpPromptText then
              return true
            end
          else
            if pErrorInterface == "UI" and pData.params.vrHelpTitle == vrHelpTitle then
              return true
            end
          end
        end
      end
      return false
    end

    --[[ @errorResponse: sending error response
    --! @parameters:
    --! pData - data from received request
    --! @return: none
    --]]
    function m.errorResponse(pData)
      m.getHMIConnection():SendError(pData.id, pData.method, "GENERIC_ERROR", "info message")
    end

    --[[ @sendResponse2Apps: sending error response
    --! @parameters:
    --! pData - data from received request
    --! pErrorRpc - RPC name for error response
    --! pErrorInterface - interface of RPC for error response
    --! @return: none
    --]]
    function m.sendResponse2Apps(pData, pErrorRpc, pErrorInterface)
      local function ErrorResp()
        m.errorResponse(pData)
      end

      if pData.method == "VehicleInfo.SubscribeVehicleData" then
        if pErrorRpc == "subscribeVehicleData" and pData.params.gps then
          RUN_AFTER(ErrorResp, 1500)
        else
          m.getHMIConnection():SendResponse(pData.id, pData.method, "SUCCESS", {})
        end
      elseif pData.params.appID == m.getHMIAppId(1) then
        local isErrorResponse = getErrorResponseStatus(pData, pErrorRpc, pErrorInterface)
        if isErrorResponse == true then
          RUN_AFTER(ErrorResp, 1500)
        else
          m.getHMIConnection():SendResponse(pData.id, pData.method, "SUCCESS", {})
        end
      else
        m.getHMIConnection():SendResponse(pData.id, pData.method, "SUCCESS", {})
      end
    end

    return m
