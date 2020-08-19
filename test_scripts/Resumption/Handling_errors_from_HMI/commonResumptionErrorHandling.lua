---------------------------------------------------------------------------------------------------
-- common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION", "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "MEDIA", "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.isMediaApplication = true
config.checkAllValidations = true

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local json = require("modules/json")
local atf_logger = require("atf_logger")
local SDL = require('SDL')
local color = require("user_modules/consts").color
local rc = require('user_modules/sequences/remote_control')

--[[ General configuration ]]
local state = rc.state.buildDefaultActualModuleState(rc.predefined.getRcCapabilities())
rc.state.initActualModuleStateOnHMI(state)

--[[ Override expectation's default timeout ]]
local expectations = require('expectations')
local expOrig = expectations.Expectation
expectations.Expectation = function(...)
  local f = expOrig(...)
  f.timeout = 12000
  return f
end

--[[ Common Variables ]]
local m = actions
m.cloneTable = utils.cloneTable
m.wait = utils.wait
m.tableToString = utils.tableToString
m.connectMobile = actions.mobile.connect
m.pairs = utils.spairs
m.getModuleControlData = rc.predefined.getModuleControlData
m.isTableEqual = utils.isTableEqual
m.getActualModuleStateOnHMI = rc.state.getActualModuleStateOnHMI
m.getActualModuleIVData = rc.state.getActualModuleIVData

m.hashId = {}
m.resumptionData = {
  [1] = {},
  [2] = {}
}

m.rcModuleTypes = rc.data.getRcModuleTypes()
m.defaultModuleType = m.rcModuleTypes[1]

m.rpcs = {
  addCommand = { "UI", "VR" },
  addSubMenu = { "UI" },
  createIntrerationChoiceSet = { "VR" },
  setGlobalProperties = { "UI", "TTS" },
  subscribeVehicleData = { "VehicleInfo" },
  subscribeWayPoints = { "Navigation" },
  createWindow = { "UI" },
  getInteriorVehicleData = { "RC" }
}

m.timeToRegApp2 = {
  BEFORE_REQUEST = 1,
  BEFORE_ERRONEOUS_RESPONSE = 2,
  AFTER_ERRONEOUS_RESPONSE = 3,
}

--[[ Local Functions ]]

--[[ @getOnSCUParams: return parameters for OnSystemCapabilityUpdated
--! @parameters:
--! pWinArray - table with window identifiers (e.g. { 0, 1 })
--! @return: table with parameters
--]]
local function getOnSCUParams(pWinArray)
  local params = {
    systemCapability = {
      systemCapabilityType = "DISPLAYS",
      displayCapabilities = {
        {
          displayName = "displayName",
          windowTypeSupported = {
            {
              type = "MAIN",
              maximumNumberOfWindows = 1
            },
            {
              type = "WIDGET",
              maximumNumberOfWindows = 1
            }
          },
          windowCapabilities = { }
        }
      }
    }
  }
  for _, winId in pairs(pWinArray) do
    local winCap = {
      windowID = winId,
      templatesAvailable = { "Template_" .. winId }
    }
    table.insert(params.systemCapability.displayCapabilities[1].windowCapabilities, winCap)
  end
  return params
end

--[[ @getSuccessHMIResponseData: return data for HMI successful response
--! @parameters:
--! pData - data from request from SDL to HMI
--! @return: data for the response from HMI to SDL
--]]
function m.getSuccessHMIResponseData(pData)
  local dataTypes = {
    gps = "VEHICLEDATA_GPS",
    speed = "VEHICLEDATA_SPEED",
    rpm = "VEHICLEDATA_RPM",
    fuelRange = "VEHICLEDATA_FUELRANGE"
  }
  local out = {}
  if pData.method == "VehicleInfo.SubscribeVehicleData" or pData.method == "VehicleInfo.UnsubscribeVehicleData"then
    for param in pairs(pData.params) do
      out[param] = { resultCode = "SUCCESS", dataType = dataTypes[param] }
    end
  elseif pData.method == "RC.GetInteriorVehicleData" then
    out.moduleData = m.getActualModuleIVData(m.defaultModuleType, m.getModuleControlData(m.defaultModuleType, 1).moduleId)
    out.isSubscribed = pData.params.subscribe
  end
  return out
end

--[[ @isResponseErroneous: define RPC for sending error response
--! @parameters:
--! pData - data from received request
--! pErrorRpc - RPC name for error response
--! pErrorInterface - interface of RPC for error response
--! @return: status of error response
--]]
local function isResponseErroneous(pData, pErrorRpc, pErrorInterface)
  local rpc = m.getRpcName(pErrorRpc, pErrorInterface)
  if pErrorRpc == "createIntrerationChoiceSet" then rpc = "VR.AddCommand" end
  if rpc == pData.method then
    if rpc ~= "VR.AddCommand" and pErrorRpc ~= "setGlobalProperties" then
      return true
    elseif pErrorRpc == "createIntrerationChoiceSet" and pData.params.type == "Choice" then
      return true
    elseif pErrorRpc == "addCommand" and pData.params.type == "Command" then
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

--[[ Common Functions ]]

--[[ @expOnHMIStatus: check OnHMIStatus notification
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pExpLevel - expected HMI level ('FULL' or 'LIMITED')
--! pErrorResponseRpc - RPC for response with errorCode
--! pTimeout - timeout to wait
--! @return: none
--]]
function m.expOnHMIStatus(pAppId, pExpLevel, pErrorResponseRpc, pTimeout)
  if not pTimeout then pTimeout = 10000 end
  local exp = {
    { hmiLevel = "NONE", windowID = 0 },
    { hmiLevel = "NONE", windowID = 2 },
    { hmiLevel = pExpLevel, windowID = 0 }
  }
  if m.resumptionData[pAppId].createWindow == nil or (pErrorResponseRpc ~= nil and pAppId == 1) then
    table.remove(exp, 2)
  end
  if pExpLevel == "FULL" then
    m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(pAppId) })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
      end)
    :Timeout(pTimeout)
  end
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",table.unpack(exp))
  :Times(#exp)
  :Timeout(pTimeout)
end

--[[ @getGlobalPropertiesResetData: construct data for reset SetGlobalProperties
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pInterface - name of RPC interface for reseting
--! @return: RPC with interface
--]]
function m.getGlobalPropertiesResetData(pAppId, pInterface)
  local resetData = {}
  resetData.appID = m.getHMIAppId(pAppId)
  if pInterface == "TTS" then
    resetData.helpPrompt = { }
    resetData.timeoutPrompt = { }
    local ttsDelimiter = SDL.INI.get("TTSDelimiter")
    local helpPromptString = SDL.INI.get("HelpPromt")
    local helpPromptList = m.splitString(helpPromptString, ttsDelimiter);

    for key,value in pairs(helpPromptList) do
      local data = {
        type = "TEXT",
        text = value .. ttsDelimiter
      }
      resetData.timeoutPrompt[key] = data
      resetData.helpPrompt[key] = data
    end
  else
    resetData.menuTitle = ""
    resetData.vrHelp = { [1] = { position = 1, text = m.getConfigAppParams(pAppId).appName }}
    resetData.vrHelpTitle = SDL.INI.get("HelpTitle")
  end
  return resetData
end

--[[ @waitUntilResumptionDataIsStored: wait some time until SDL saves resumption data
--! @parameters: none
--! @return: none
--]]
function m.waitUntilResumptionDataIsStored()
  utils.cprint(color.magenta, "Wait ...")
  local timeoutToSafe = SDL.INI.get("AppSavePersistentDataTimeout")
  local fileName = SDL.AppInfo.file()
  m.wait(timeoutToSafe + 1000)
  :Do(function()
      while not utils.isFileExist(fileName) do
        os.execute("sleep 1")
      end
    end)
end

--[[ @checkResumptionData: checks resumption data and answer with error to defined RPC
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseRpc - RPC for response with errorCode
--! pErrorResponseInterface - interface of RPC for response with errorCode
--! @return: none
--]]
function m.checkResumptionData(pAppId, pErrorResponseRpc, pErrorResponseInterface)
  for rpc in pairs(m.resumptionData[pAppId]) do
    if pErrorResponseRpc == rpc then
      m[rpc .. "Resumption"](pAppId, pErrorResponseInterface)
    else
      m[rpc .. "Resumption"](pAppId)
    end
  end
end

--[[ @resumptionFullHMILevel: checks resumption to full HMI level
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pTimeout - timeout to wait
--! @return: none
--]]
function m.resumptionFullHMILevel(pAppId, pErrorResponseRpc, pTimeout)
  if not pTimeout then pTimeout = 10000 end
  m.expOnHMIStatus(pAppId, "FULL", pErrorResponseRpc, pTimeout)
end

--[[ @getRpcName: construct RPC name for HMI messages
--! @parameters:
--! pRpcName - name of RPC
--! pInterfaceName - name of RPC interface
--! @return: RPC with interface
--]]
function m.getRpcName(pRpcName, pInterfaceName)
  local rpcName = pRpcName:gsub("^%l", string.upper)
  return pInterfaceName .. "." .. rpcName
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
    if pTimes == 1 then
      if pRequestType == "Choice" then
        deleteCommandRequestParams = m.cloneTable(m.resumptionData[pAppId].createIntrerationChoiceSet.VR)
      else
        deleteCommandRequestParams = m.cloneTable(m.resumptionData[pAppId].addCommand.VR)
      end
      deleteCommandRequestParams.vrCommands = nil
    else
      deleteCommandRequestParams = {}
      deleteCommandRequestParams[1] = m.cloneTable(m.resumptionData[pAppId].addCommand.VR)
      deleteCommandRequestParams[1].vrCommands = nil
      deleteCommandRequestParams[2] = m.cloneTable(m.resumptionData[pAppId].createIntrerationChoiceSet.VR)
      deleteCommandRequestParams[2].vrCommands = nil
    end
    deleteCommandRequestParams.vrCommands = nil
      m.getHMIConnection():ExpectRequest("VR.DeleteCommand", deleteCommandRequestParams[1], deleteCommandRequestParams[2])
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
  end,
  DeleteWindow = function(pAppId)
    local params = {
      appID = m.getHMIAppId(pAppId),
      windowID = m.resumptionData[pAppId].createWindow.UI.windowID
    }
    m.getHMIConnection():ExpectRequest("UI.DeleteWindow", params)
    :Do(function(_,deleteData)
        m.sendResponse(deleteData)
      end)
  end
}

m.rpcsRevert = {
  addCommand = {
    rpc = "DeleteCommand",
    iface = {
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
        :Do(function(exp, data)
            m.sendResponse(data)
            if pTimes == 2 and exp.occurences == 1 then
              m.removeData.DeleteVRCommand(pAppId, nil, 2)
            elseif pTimes == 1 then
              m.removeData.DeleteVRCommand(pAppId, data.params.type)
            end
          end)
        :ValidIf(function(_, data)
            if data.params.type == "Choice" then
              if utils.isTableEqual(data.params, m.resumptionData[pAppId].createIntrerationChoiceSet.VR) == false then
                return false, "Params in VR.AddCommand with type = Choice are not match to expected result.\n" ..
                "Actual result:" .. m.tableToString(data.params) .. "\n" ..
                "Expected result:" .. m.tableToString(m.resumptionData[pAppId].createIntrerationChoiceSet.VR) .."\n"
              end
            else
              if utils.isTableEqual(data.params, m.resumptionData[pAppId].addCommand.VR) == false then
                return false, "Params in VR.AddCommand with type = Command are not match to expected result.\n" ..
                "Actual result:" .. m.tableToString(data.params) .. "\n" ..
                "Expected result:" .. m.tableToString(m.resumptionData[pAppId].addCommand.VR) .."\n"
              end
            end
            return true
          end)
        :Times(pTimes)
      end
    }
  },
  addSubMenu = {
    rpc = "DeleteSubMenu",
    iface = {
      UI = function(pAppId, pTimes)
        if not pTimes then pTimes = 1 end
        m.getHMIConnection():ExpectRequest("UI.AddSubMenu",m.resumptionData[pAppId].addSubMenu.UI)
        :Do(function(_, data)
            m.sendResponse(data)
            m.removeData.DeleteSubMenu(pAppId)
          end)
        :Times(pTimes)
      end
    }
  },
  createIntrerationChoiceSet = {
    rpc = "DeleteCommand",
    iface = {
      VR = function() end
    }
  },
  setGlobalProperties = {
    rpc = "SetGlobalProperties",
    iface = {
      TTS = function(pAppId, pTimes)
        if not pTimes then pTimes = 2 end
        m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties")
        :Do(function(_, data)
            m.sendResponse(data)
          end)
        :ValidIf(function(exp, data)
            if exp.occurences == 1 then
              if utils.isTableEqual(data.params, m.resumptionData[pAppId].setGlobalProperties.TTS) == true then
                return true
              else
                return false, "Params in TTS.SetGlobalProperties are not match to expected result.\n" ..
                "Actual result:" .. m.tableToString(data.params) .. "\n" ..
                "Expected result:" .. m.tableToString(m.resumptionData[pAppId].setGlobalProperties.TTS) .."\n"
              end
            else
              local resetData = m.getGlobalPropertiesResetData(pAppId, "TTS")
              if utils.isTableEqual(data.params, resetData) == true then
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
        :Do(function(_, data)
            m.sendResponse(data)
          end)
        :ValidIf(function(exp, data)
            if exp.occurences == 1 then
              if utils.isTableEqual(data.params, m.resumptionData[pAppId].setGlobalProperties.UI) == true then
                return true
              else
                return false, "Params in UI.SetGlobalProperties are not match to expected result.\n" ..
                "Actual result:" .. m.tableToString(data.params) .. "\n" ..
                "Expected result:" .. m.tableToString(m.resumptionData[pAppId].setGlobalProperties.UI) .."\n"
              end
            else
              local resetData = m.getGlobalPropertiesResetData(pAppId, "UI")
              if utils.isTableEqual(data.params, resetData) == true then
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
    }
  },
  subscribeVehicleData = {
    rpc = "UnsubscribeVehicleData",
    iface = {
      VehicleInfo = function(pAppId,pTimes)
        if not pTimes then pTimes = 1 end
        m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData",m.resumptionData[pAppId].subscribeVehicleData.VehicleInfo)
        :Do(function(_, data)
            m.sendResponse(data)
            m.removeData.UnsubscribeVehicleData(pAppId)
          end)
        :Times(pTimes)
      end
    }
  },
  subscribeWayPoints = {
    rpc = "UnsubscribeWayPoints",
    iface = {
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
  },
  createWindow = {
    rpc = "DeleteWindow",
    iface = {
      UI = function(pAppId, pTimes)
        if not pTimes then pTimes = 1 end
        m.getHMIConnection():ExpectRequest("UI.CreateWindow",m.resumptionData[pAppId].createWindow.UI)
        :Do(function(_, data)
            m.sendResponse(data)
            m.sendOnSCU(2, pAppId)
            m.removeData.DeleteWindow(pAppId)
          end)
        :Times(pTimes)
      end
    }
  },
  getInteriorVehicleData = {
    rpc = "GetInteriorVehicleData",
    iface = {
      RC = function(pAppId, pTimes)
        if not pTimes then pTimes = 2 end
        local dataForResumption = m.resumptionData[pAppId].getInteriorVehicleData.RC
        local dataForRevert = m.cloneTable(dataForResumption)
        dataForRevert.subscribe = false
        m.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData", dataForResumption, dataForRevert)
        :Do(function(_, data)
            m.sendResponse(data)
          end)
        :Times(pTimes)
      end
    }
  }
}

--[[ @checkResumptionDataWithErrorResponse: check resumption data with error response to defined rpc and
--! checking reverting already added data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseRpc - RPC name for error response
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
]]
function m.checkResumptionDataWithErrorResponse(pAppId, pErrorResponseRpc, pErrorResponseInterface)
  local rpcsRevertLocal = m.cloneTable(m.rpcsRevert)
  if pErrorResponseRpc == "addCommand" and pErrorResponseInterface == "VR" then
    rpcsRevertLocal.addCommand.iface.VR = nil
    m.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        if data.params.type == "Command" then
          m.errorResponse(data)
        else
          m.sendResponse(data)
          m.removeData.DeleteVRCommand(pAppId, data.params.type, 1)
        end
      end)
    :Times(2)
  elseif pErrorResponseRpc == "createIntrerationChoiceSet" then
    rpcsRevertLocal.addCommand.iface.VR = nil
    m.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        if data.params.type == "Choice" then
          m.errorResponse(data)
        else
          m.sendResponse(data)
          m.removeData.DeleteVRCommand(pAppId, data.params.type, 1)
        end
      end)
    :Times(2)
  else
    local errorResponseRpc = m.getRpcName(pErrorResponseRpc, pErrorResponseInterface)
    local revertRpc = rpcsRevertLocal[pErrorResponseRpc].rpc
    local notExpRevertRpc = m.getRpcName(revertRpc, pErrorResponseInterface)
    rpcsRevertLocal[pErrorResponseRpc].iface[pErrorResponseInterface] = nil
    if pErrorResponseRpc:gsub("^%l", string.upper) ~= revertRpc then
      m.getHMIConnection():ExpectRequest(notExpRevertRpc)
      :Times(0)
    end
    m.getHMIConnection():ExpectRequest(errorResponseRpc)
    :Do(function(_, data)
        m.errorResponse(data)
      end)
  end
  for rpc, data in pairs(rpcsRevertLocal) do
    if m.resumptionData[pAppId][rpc] then
      for interface in pairs(data.iface) do
        rpcsRevertLocal[rpc].iface[interface](pAppId)
      end
    end
  end

  local isCustomButtonSubscribed = false
  local isOkButtonSubscribed = false
  local isOkButtonUnsubscribed = false
  m.getHMIConnection():ExpectNotification("Buttons.OnButtonSubscription")
  :ValidIf(function(_, data)
      local params = data.params
      if params.name == "CUSTOM_BUTTON" and params.isSubscribed == true and isCustomButtonSubscribed == false then
        isCustomButtonSubscribed = true
      elseif params.name == "OK" and params.isSubscribed == true and isOkButtonSubscribed == false then
        isOkButtonSubscribed = true
      elseif params.name == "OK" and params.isSubscribed == false and isOkButtonUnsubscribed == false then
        isOkButtonUnsubscribed = true
      else
        return false, "Came unexpected Buttons.OnButtonSubscription notification"
      end
      return true
    end)
  :Times(3)
end

--[[ @reRegisterApp: re-register application with RESUME_FAILED resultCode
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pCheckResumptionData - verification function for resumption data
--! pCheckResumptionHMILevel - verification function for resumption HMI level
--! pErrorResponseRpc - RPC name for error response
--! pErrorResponseInterface - interface of RPC for error response
--! pTimeout - time for expectation of RAI response and OnHMIStatus notifications
--! @return: none
--]]
function m.reRegisterApp(pAppId, pCheckResumptionData, pCheckResumptionHMILevel, pErrorResponseRpc, pErrorResponseInterface, pTimeout)
  if not pAppId then pAppId = 1 end
  if not pTimeout then pTimeout = 10000 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = m.cloneTable(m.getConfigAppParams(pAppId))
      params.hashID = m.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = m.getConfigAppParams(pAppId).appName }
        })
      :Do(function()
          m.sendOnSCU(0, pAppId)
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "RESUME_FAILED" })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
          mobSession:ExpectNotification("OnSystemCapabilityUpdated")
        end)
      :Timeout(pTimeout)
    end)
  pCheckResumptionData(pAppId, pErrorResponseRpc, pErrorResponseInterface)
  pCheckResumptionHMILevel(pAppId, pErrorResponseRpc, pTimeout)
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
      local params = m.cloneTable(m.getConfigAppParams(pAppId))
      params.hashID = m.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = m.getConfigAppParams(pAppId).appName }
        })
      :Do(function()
          m.sendOnSCU(0, pAppId)
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
          mobSession:ExpectNotification("OnSystemCapabilityUpdated")
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
    m.getHMIConnection():SendResponse(pData.id, pData.method, "SUCCESS", m.getSuccessHMIResponseData(pData))
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
  m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties")
  :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].setGlobalProperties.UI = data.params
    end)

  m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties")
  :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].setGlobalProperties.TTS = data.params
    end)

  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @subscribeVehicleData: adding subscribeVehicleData
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pParams - parameters for SubscribeVehicleData mobile request
--! pHMIrequest - number of expected VI.SubscribeVehicleData HMI requests
--! @return: none
--]]
function m.subscribeVehicleData(pAppId, pParams, pHMIrequest)
  if not pAppId then pAppId = 1 end
  if not pParams then
    pParams = {
      requestParams = { gps = true },
      responseParams = { gps = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS" } }
    }
  end
  if not pHMIrequest then pHMIrequest = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("SubscribeVehicleData", pParams.requestParams)
  m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", m.getSuccessHMIResponseData(data))
      m.resumptionData[pAppId].subscribeVehicleData = { VehicleInfo = data.params }
    end)
  :Times(pHMIrequest)
  local MobResp = m.cloneTable(pParams.responseParams)
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
--! pHMIrequest - number of expected Navigation.SubscribeWayPoints HMI requests
--! @return: none
--]]
function m.subscribeWayPoints(pAppId, pHMIrequest)
  if not pAppId then pAppId = 1 end
  if not pHMIrequest then pHMIrequest = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("SubscribeWayPoints", {})
  m.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].subscribeWayPoints = { Navigation = data.params }
    end)
  :Times(pHMIrequest)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
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
  local cid = m.getMobileSession(pAppId):SendRPC("SubscribeButton", { buttonName = "OK" })
  m.getHMIConnection():ExpectNotification("Buttons.OnButtonSubscription")
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @getInteriorVehicleData: adding subscription for interior vehicle data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! isIVDCashed - false (default), true - if InteriorVehicleData is cached on SDL, it is no request performed to HMI
--! pModuleType - module type to subscribe for
--! pModuleId - module id to subscribe for
--! @return: none
--]]
function m.getInteriorVehicleData(pAppId, isIVDCashed, pModuleType, pModuleId)
  if not pAppId then pAppId = 1 end
  pModuleType = pModuleType or m.defaultModuleType
  pModuleId = pModuleId or m.getModuleControlData(pModuleType, 1).moduleId
  isIVDCashed = isIVDCashed or false
  rc.rc.subscribeToModule(pModuleType, pModuleId, pAppId, isIVDCashed)
  m.resumptionData[pAppId].getInteriorVehicleData = {
    RC = { moduleType = pModuleType, moduleId = pModuleId, subscribe = true } }
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
  if pErrorResponseInterface == "VR" then
    m.removeData.DeleteUICommand(pAppId)
  elseif pErrorResponseInterface == "UI" then
    m.removeData.DeleteVRCommand(pAppId, "Command", 1)
  end
  m.getHMIConnection():ExpectRequest("VR.AddCommand", m.resumptionData[pAppId].addCommand.VR)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "VR")
    end)
  m.getHMIConnection():ExpectRequest("UI.AddCommand", m.resumptionData[pAppId].addCommand.UI)
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
  m.getHMIConnection():ExpectRequest("UI.AddSubMenu", m.resumptionData[pAppId].addSubMenu.UI)
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
  local timesTTS = 1
  local timesUI  = 1
  local restoreData = {}
  if pErrorResponseInterface == "TTS" then
    timesUI  = 2
    restoreData = m.getGlobalPropertiesResetData(pAppId, "UI")
  elseif pErrorResponseInterface == "UI" then
    timesTTS = 2
    restoreData = m.getGlobalPropertiesResetData(pAppId, "TTS")
  end
  m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties",
    m.resumptionData[pAppId].setGlobalProperties.UI,
    restoreData)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "UI")
    end)
  :Times(timesUI)
  m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties",
    m.resumptionData[pAppId].setGlobalProperties.TTS,
    restoreData)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "TTS")
    end)
  :Times(timesTTS)
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

--[[ @createWindowResumption: check resumption of createWindow data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.createWindowResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("UI.CreateWindow",m.resumptionData[pAppId].createWindow.UI)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "UI")
      if not pErrorResponseInterface then
        m.sendOnSCU(2)
      end
    end)
end

--[[ @getInteriorVehicleDataResumption: check resumption of interior vehicle data subscription
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pErrorResponseInterface - interface of RPC for error response
--! @return: none
--]]
function m.getInteriorVehicleDataResumption(pAppId, pErrorResponseInterface)
  m.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData", m.resumptionData[pAppId].getInteriorVehicleData.RC)
  :Do(function(_, data)
      m.sendResponse(data, pErrorResponseInterface, "RC")
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
      actions.mobile.closeSession(pAppId)
      m.resumptionData[pAppId] = {}
    end)
end

--[[ @unexpectedDisconnect: Unexpected disconnect sequence
--! @parameters:
--! pExpGIVD - count of expected RC.GetInteriorVehicleData requests from SDL to HMI
--! @return: none
--]]
function m.unexpectedDisconnect(pExpGIVD)
  if not pExpGIVD then
    pExpGIVD = 0
    if m.resumptionData[1].getInteriorVehicleData then pExpGIVD = 1 end
  end

  m.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData")
  :Do(function(_, data)
      local resParams = {
        moduleData = m.getActualModuleIVData(data.params.moduleType, data.params.moduleId),
        isSubscribed = false
      }
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", resParams)
    end)
  :Times(pExpGIVD)

  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(actions.mobile.getAppsCount())
  actions.mobile.disconnect()
  utils.wait(1000)
end

local preconditions_Orig = actions.preconditions
--[[ @preconditions: delete logs, backup preloaded file, update preloaded
--! @parameters: none
--! @return: none
--]]
function m.preconditions()
  preconditions_Orig()
  m.updatePreloadedPT()
end

--[[ @updatePreloadedPT: update preloaded file with permissions for additional RPCs
--! @parameters: none
--! @return: none
--]]
function m.updatePreloadedPT()
  local pt = actions.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  local additionalRPCs = {
    "SubscribeVehicleData", "UnsubscribeVehicleData", "SubscribeWayPoints", "UnsubscribeWayPoints",
    "OnVehicleData", "OnWayPointChange", "CreateWindow", "GetAppServiceData", "OnAppServiceData",
    "GetInteriorVehicleData", "OnInteriorVehicleData"
  }
  pt.policy_table.functional_groupings.NewTestCaseGroup = { rpcs = { } }
  for _, v in pairs(additionalRPCs) do
    pt.policy_table.functional_groupings.NewTestCaseGroup.rpcs[v] = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
    }
  end
  pt.policy_table.app_policies.default.groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.app_policies.default.moduleType = m.rcModuleTypes
  actions.sdl.setPreloadedPT(pt)
end

--[[ @ignitionOff: Ignition Off sequence
--! @parameters:
--! pParam: name of the VD parameter
--! @return: none
--]]
function m.ignitionOff()
  local isOnSDLCloseSent = false
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  end)
  m.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then utils.cprint(color.magenta, "BC.OnSDLClose was not sent") end
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.deleteSession(i)
    end
    StopSDL()
  end)
end

--[[ @openRPCservice: open RPC service
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.openRPCservice(pAppId)
  return m.getMobileSession(pAppId):StartService(7)
end

--[[ @registerAppCustom: re-register app
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pResultCode - expected result code in RAI response
--! pDelay - delay before send of RAI request
--! pTimeout - timeout to wait RAI response
--! @return: expectation on RAI response
--]]
function m.reRegisterAppCustom(pAppId, pResultCode, pDelay, pTimeout)
  local event = m.run.createEvent()
  if pAppId == nil then pAppId = 1 end
  if pTimeout == nil then pTimeout = 5000 end
  local params = m.cloneTable(m.getConfigAppParams(pAppId))
  params.hashID = m.hashId[pAppId]
  local function rai()
    local corId1 = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface", params)
    m.log("RAI " .. pAppId)
    m.getMobileSession(pAppId):ExpectResponse(corId1, { success = true, resultCode = pResultCode })
    :Do(function(_, data)
         m.log("RAI " .. pAppId .. ": " .. data.payload.resultCode)
         m.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated")
         m.hmi.getConnection():RaiseEvent(event, "RAI event")
      end)
    :Timeout(pTimeout)
  end
  m.run.runAfter(rai, pDelay)
  return m.hmi.getConnection():ExpectEvent(event, "RAI event"):Timeout(pTimeout)
end

--[[ @reRegisterApps: re-register 2 apps
--! @parameters:
--! pCheckResumptionData - verification function for resumption data
--! pErrorRpc - RPC name for error response
--! pErrorInterface - interface of RPC for error response
--! pTimeout - time for expectation of RAI response
--! @return: none
--]]
function m.reRegisterApps(pCheckResumptionData, pErrorRpc, pErrorInterface, pTimeout)
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Do(function(exp, data)
      m.log("BC.OnAppRegistered " .. exp.occurences)
      m.setHMIAppId(data.params.application.appID, exp.occurences)
      m.sendOnSCU(0, exp.occurences)
      if exp.occurences == 1 then m.reRegisterAppCustom(2, "SUCCESS", 0, pTimeout) end
    end)
  :Times(2)

  m.expOnHMIStatus(1, "LIMITED", pErrorRpc, pTimeout)
  m.expOnHMIStatus(2, "FULL", pErrorRpc, pTimeout)

  m.reRegisterAppCustom(1, "RESUME_FAILED", 0, pTimeout)

  pCheckResumptionData(pErrorRpc, pErrorInterface)
end

--[[ @checkResumptionData2Apps: check resumption data for 2 apps
--! @parameters:
--! pErrorRpc - RPC name for error response
--! pErrorInterface - interface of RPC for error response
--! @return: none
--]]
function m.checkResumptionData2Apps(pErrorRpc, pErrorInterface)
  local uiSetGPtimes = 3
  local ttsSetGPtimes = 3
  if pErrorRpc == "setGlobalProperties" then
    if pErrorInterface == "UI" then
      uiSetGPtimes = 2
    else
      ttsSetGPtimes = 2
    end
  end

  local revertRpcToUpdate = m.cloneTable(m.removeData)
  revertRpcToUpdate.UnsubscribeWayPoints = nil

  if pErrorRpc == "addCommand" and pErrorInterface == "VR" then
    revertRpcToUpdate.DeleteVRCommand = nil
    m.removeData.DeleteVRCommand(1, "Choice", 1 )
  elseif pErrorRpc == "createIntrerationChoiceSet" then
    revertRpcToUpdate.DeleteVRCommand = nil
    m.removeData.DeleteVRCommand(1, "Command", 1 )
  elseif pErrorRpc == "addCommand" and pErrorInterface == "UI" then
    revertRpcToUpdate.DeleteUICommand = nil
  elseif pErrorRpc == "addSubMenu" then
      revertRpcToUpdate.DeleteSubMenu = nil
  elseif pErrorRpc == "subscribeVehicleData" then
      revertRpcToUpdate.UnsubscribeVehicleData = nil
  elseif pErrorRpc == "createWindow" then
    revertRpcToUpdate.DeleteWindow = nil
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

  m.getHMIConnection():ExpectRequest("UI.CreateWindow")
  :Do(function(exp, data)
      m.sendOnSCU(2, exp.occurences)
      m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
    end)
  :Times(2)

  m.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData")
  :Do(function(_, data)
      m.sendResponse2Apps(data, pErrorRpc, pErrorInterface)
    end)
  :Times(2)
end

--[[ @errorResponse: sending error response
--! @parameters:
--! pData - data from received request
--! pDelay - delay for the response
--! @return: none
--]]
function m.errorResponse(pData, pDelay)
  if pDelay == nil then pDelay = 0 end
  local function response()
    m.log(pData.method .. ": GENERIC_ERROR")
    m.getHMIConnection():SendError(pData.id, pData.method, "GENERIC_ERROR", "info message")
  end
  m.run.runAfter(response, pDelay)
end

--[[ @sendResponse2Apps: sending error response
--! @parameters:
--! pData - data from received request
--! pErrorRpc - RPC name for error response
--! pErrorInterface - interface of RPC for error response
--! @return: none
--]]
function m.sendResponse2Apps(pData, pErrorRpc, pErrorInterface)
  local isErrorResponse = isResponseErroneous(pData, pErrorRpc, pErrorInterface)
  if pData.method == "VehicleInfo.SubscribeVehicleData" and pErrorRpc == "subscribeVehicleData" and pData.params.gps then
    m.errorResponse(pData, 300)
  elseif pData.params.appID == m.getHMIAppId(1) and isErrorResponse == true then
    m.errorResponse(pData, 300)
  else
    m.getHMIConnection():SendResponse(pData.id, pData.method, "SUCCESS", m.getSuccessHMIResponseData(pData))
  end
end

--[[ @activateNotAudibleApp: activation of non-media app
--! @parameters:none
--! @return: none
--]]
function m.activateNotAudibleApp()
  local requestId = m.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = m.getHMIAppId() })
  m.getHMIConnection():ExpectResponse(requestId)
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ @deactivateAppToLimited: deactivate app to LIMITED HMI level
--! @parameters:none
--! @return: none
--]]
function m.deactivateAppToLimited()
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", {
      appID = m.getHMIAppId()
    })
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ @deactivateAppToBackground: deactivate app to BACKGROUND HMI level
--! @parameters:none
--! @return: none
--]]
function m.deactivateAppToBackground()
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", {
      appID = m.getHMIAppId()
    })
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ @splitString: split string with separator
--! @parameters:
--! pInputStr - string
--! pSep - separator
--! @return: none
--]]
function m.splitString(pInputStr, pSep)
  if pSep == nil then
    pSep = "%s"
  end
  local splitted, i = {}, 1
  for str in string.gmatch(pInputStr, "([^"..pSep.."]+)") do
    splitted[i] = str
    i = i + 1
  end
  return splitted
end

--[[ @log: print text to console
--! @parameters:
--! ... - set of strings to print (e.g. 'aaa', 'bbb' etc.)
--! @return: none
--]]
function m.log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  utils.cprint(color.magenta, str)
end

--[[ @sendOnSCU: Send BC.OnSystemCapabilityUpdated for window
--! @parameters:
--! pWinId - window identifier (0, 1, etc.)
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.sendOnSCU(pWinId, pAppId)
  if not pAppId then pAppId = 1 end
  local params = getOnSCUParams({ pWinId })
  params.appID = m.getHMIAppId(pAppId)
  m.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", params)
end

--[[ @createWindow: adding of window
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.createWindow(pAppId)
  if not pAppId then pAppId = 1 end
  local params = {
    windowID = 2,
    windowName = "Name",
    type = "WIDGET",
    associatedServiceType = "MEDIA"
  }
  local cid = m.getMobileSession(pAppId):SendRPC("CreateWindow", params)
  m.getHMIConnection():ExpectRequest("UI.CreateWindow")
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.resumptionData[pAppId].createWindow = { UI = data.params }
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ @sendOnButtonPress: send OnButtonEvent and OnButtonPress
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pIsExp - true (default) - if it's expected notification on mobile app
--! @return: none
--]]
function m.sendOnButtonPress(pAppId, pIsExp)
  if pAppId == nil then pAppId = 1 end
  local occurences = pIsExp == true and 1 or 0
  local btnName = "OK"
  local btnEventMode = "BUTTONDOWN"
  local btnPressMode = "SHORT"
  m.getMobileSession(pAppId):ExpectNotification("OnButtonEvent",
    { buttonName = btnName, buttonEventMode = btnEventMode })
  :Times(occurences)
  m.getMobileSession(pAppId):ExpectNotification("OnButtonPress",
    { buttonName = btnName, buttonPressMode = btnPressMode })
  :Times(occurences)
  m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = btnName, appID = m.getHMIAppId(pAppId), mode = btnEventMode })
  m.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = btnName, appID = m.getHMIAppId(pAppId), mode = btnPressMode })
end

--[[ @sendOnWayPointChange: send OnWayPointChange
--! @parameters:
--! pIsExpApp1 - true - if it's expected notification on mobile app1
--! pIsExpApp2 - true - if it's expected notification on mobile app2
--! @return: none
--]]
function m.sendOnWayPointChange(pIsExpApp1, pIsExpApp2)
  local occurences1 = pIsExpApp1 == true and 1 or 0
  local occurences2 = pIsExpApp2 == true and 1 or 0
  local params = {
    wayPoints = {
      {
        coordinate = {
          latitudeDegrees = -90,
          longitudeDegrees = -180
        }
      }
    }
  }
  m.getHMIConnection():SendNotification("Navigation.OnWayPointChange", params)
  m.getMobileSession(1):ExpectNotification("OnWayPointChange", params):Times(occurences1)
  m.getMobileSession(2):ExpectNotification("OnWayPointChange", params):Times(occurences2)
end

--[[ @sendOnVehicleData: send OnVehicleData
--! @parameters:
--! pVDParam - VD parameter ('gps', 'speed', etc.)
--! pIsExpApp1 - true - if it's expected notification on mobile app1
--! pIsExpApp2 - true - if it's expected notification on mobile app2
--! @return: none
--]]
function m.sendOnVehicleData(pVDParam, pIsExpApp1, pIsExpApp2)
  local occurences1 = pIsExpApp1 == true and 1 or 0
  local occurences2 = pIsExpApp2 == true and 1 or 0
  local params = { }
  if pVDParam == "gps" then
    params.gps = { longitudeDegrees = 10, latitudeDegrees = 10 }
  elseif pVDParam == "speed" then
    params.speed = 5
  elseif pVDParam == "rpm" then
    params.rpm = 123
  elseif pVDParam == "fuelRange" then
    params.fuelRange = { type = "GASOLINE", range = 11.22 }
  end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", params)
  if pIsExpApp1 ~= nil then
    m.getMobileSession(1):ExpectNotification("OnVehicleData", params):Times(occurences1)
  end
  if pIsExpApp2 ~= nil then
    m.getMobileSession(2):ExpectNotification("OnVehicleData", params):Times(occurences2)
  end
end

--[[ @checkResumptionDataSuccess: verify resumption for successful scenario
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.checkResumptionDataSuccess(pAppId)
  m.addSubMenuResumption(pAppId)
  m.setGlobalPropertiesResumption(pAppId)
  m.subscribeVehicleDataResumption(pAppId)
  m.subscribeWayPointsResumption(pAppId)
  m.createWindowResumption(pAppId)
  m.getInteriorVehicleDataResumption(pAppId)
  m.getHMIConnection():ExpectRequest("UI.AddCommand",
    m.resumptionData[pAppId].addCommand.UI)
  :Do(function(_, data)
      m.sendResponse(data)
    end)
  m.getHMIConnection():ExpectRequest("VR.AddCommand",
    m.resumptionData[pAppId].addCommand.VR,
    m.resumptionData[pAppId].createIntrerationChoiceSet.VR)
  :Do(function(_, data)
      m.sendResponse(data)
    end)
  :Times(2)

  local isCustomButtonSubscribed = false
  local isOkButtonSubscribed = false
  m.getHMIConnection():ExpectNotification("Buttons.OnButtonSubscription")
  :ValidIf(function(_, data)
      if data.params.name == "CUSTOM_BUTTON" and isCustomButtonSubscribed == false then
        isCustomButtonSubscribed = true
      elseif data.params.name == "OK" and data.params.isSubscribed == true and isOkButtonSubscribed == false then
        isOkButtonSubscribed = true
      else
        return false, "Came unexpected Buttons.OnButtonSubscription notification"
      end
      return true
    end)
  :Times(2)
end

--[[ @checkSubscriptions: verify subscriptions to Button events and Vehicle data, Interior Vehicle Data
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pIsExp - true (default) - if it's expected notification on mobile app
--! @return: none
--]]
function m.checkSubscriptions(pIsExp, pAppId)
  m.sendOnButtonPress(pAppId, pIsExp)
  m.sendOnVehicleData("gps", pIsExp)
  m.isSubscribed(pIsExp)
end

--[[ @isRevertRpc: checks - is the RC.GetInteriorVehicleData request for reverting or not
--! @parameters:
--! pData - data received in request
--! @return: result - is revert request or not
--]]
local function isRevertRpc(pData)
  if pData.method == "RC.GetInteriorVehicleData" then
    return not pData.params.subscribe
  end
end

--[[ @reRegisterAppsCustom_SameRPC: re-register 2 apps and check data resumption
-- in case erroneous response is sent by HMI to the same RPC
--! @parameters:
--! pTimeToRegApp2 - option defines when 2nd app will be re-registered, see 'm.timeToRegApp2' enum
--! pRPC - name of other RPC: 'subscribeVehicleData' or 'subscribeWayPoints' or "getInteriorVehicleData"
--! @return: none
--]]
function m.reRegisterAppsCustom_SameRPC(pTimeToRegApp2, pRPC)
  local isRAIResponseSent = {
    [1] = false,
    [2] = false
  }
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Do(function(exp, data)
      m.log("BC.OnAppRegistered " .. exp.occurences)
      m.setHMIAppId(data.params.application.appID, exp.occurences)
      m.sendOnSCU(0, exp.occurences)
    end)
  :Times(2)

  local iface = m.rpcs[pRPC][1]
  local rpc = pRPC:gsub("^%l", string.upper)
  local revert_rpc = m.rpcsRevert[pRPC].rpc
  m.getHMIConnection():ExpectRequest(iface .. "." .. rpc)
  :Do(function(exp, data)
      m.log(data.method)
      if exp.occurences == 1 then
        if pTimeToRegApp2 == m.timeToRegApp2.BEFORE_ERRONEOUS_RESPONSE then
          m.reRegisterAppCustom(2, "SUCCESS", 0):Do(function() isRAIResponseSent[2] = true end)
          m.errorResponse(data, 300)
        elseif pTimeToRegApp2 == m.timeToRegApp2.AFTER_ERRONEOUS_RESPONSE then
          m.errorResponse(data, 0)
          m.reRegisterAppCustom(2, "SUCCESS", 300):Do(function() isRAIResponseSent[2] = true end)
        else
          m.errorResponse(data, 0)
        end
      else
        m.log(data.method .. ": SUCCESS")
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", m.getSuccessHMIResponseData(data))
      end
    end)
  :ValidIf(function(exp)
      if exp.occurences == 1 and isRAIResponseSent[1] then
        return false, "Response for RAI1 is sent earlier than " .. rpc .. " request to HMI"
      end
      return true
    end)
  :ValidIf(function(exp)
      if exp.occurences == 2 and isRAIResponseSent[2] then
        return false, "Response for RAI2 is sent earlier than " .. rpc .. " request to HMI"
      end
      return true
    end)
  :ValidIf(function(_, data)
      if revert_rpc == rpc then
        if isRevertRpc(data) then
          return false, "Received revert RPC on HMI for " .. rpc .. " RPC"
        end
      end
      return true
    end)
  :Times(2)

  if rpc ~= revert_rpc then
    m.getHMIConnection():ExpectRequest(iface .. "." .. revert_rpc)
    :Do(function(_, data) m.log(data.method) end)
    :Times(0)
  end

  m.expOnHMIStatus(1, "LIMITED")
  m.expOnHMIStatus(2, "FULL")

  m.reRegisterAppCustom(1, "RESUME_FAILED", 0):Do(function() isRAIResponseSent[1] = true end)
  if pTimeToRegApp2 == m.timeToRegApp2.BEFORE_REQUEST then
    m.reRegisterAppCustom(2, "SUCCESS", 10):Do(function() isRAIResponseSent[2] = true end)
  end
end

--[[ @reRegisterAppsCustom_AnotherRPC: re-register 2 apps and check data resumption
-- in case erroneous response is sent by HMI to another RPC
--! @parameters:
--! pTimeToRegApp2 - option defines when 2nd app will be re-registered, see 'm.timeToRegApp2' enum
--! pRPC - name of other RPC: 'subscribeVehicleData' or 'subscribeWayPoints' or "getInteriorVehicleData"
--! @return: none
--]]
function m.reRegisterAppsCustom_AnotherRPC(pTimeToRegApp2, pRPC)
  local isRAIResponseSent = {
    [1] = false,
    [2] = false
  }
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Do(function(exp, data)
      m.log("BC.OnAppRegistered " .. exp.occurences)
      m.setHMIAppId(data.params.application.appID, exp.occurences)
      m.sendOnSCU(0, exp.occurences)
    end)
  :Times(2)

  m.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      m.log(data.method)
      if pTimeToRegApp2 == m.timeToRegApp2.BEFORE_ERRONEOUS_RESPONSE then
        m.reRegisterAppCustom(2, "SUCCESS", 0):Do(function() isRAIResponseSent[2] = true end)
        m.errorResponse(data, 300)
      elseif pTimeToRegApp2 == m.timeToRegApp2.AFTER_ERRONEOUS_RESPONSE then
        m.errorResponse(data, 0)
        m.reRegisterAppCustom(2, "SUCCESS", 300):Do(function() isRAIResponseSent[2] = true end)
      else
        m.errorResponse(data, 0)
      end
    end)

  local iface = m.rpcs[pRPC][1]
  local rpc = pRPC:gsub("^%l", string.upper)
  local revert_rpc = m.rpcsRevert[pRPC].rpc
  local numOfRequests = 1
  local numOfRevertRequests = 0
  if pTimeToRegApp2 == m.timeToRegApp2.AFTER_ERRONEOUS_RESPONSE then
    if rpc ~= revert_rpc then
      numOfRequests = 2
      numOfRevertRequests = 1
    else
      numOfRequests = 3
    end
  end
  m.getHMIConnection():ExpectRequest(iface .. "." .. rpc)
  :Do(function(_, data)
      m.log(data.method)
      m.log(data.method .. ": SUCCESS")
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", m.getSuccessHMIResponseData(data))
    end)
  :ValidIf(function(exp)
      if exp.occurences == 1 and isRAIResponseSent[1] then
        return false, "Response for RAI1 is sent earlier than " .. rpc .. " request to HMI"
      end
      return true
    end)
  :ValidIf(function(exp)
      if exp.occurences == numOfRequests and isRAIResponseSent[2] then
        return false, "Response for RAI2 is sent earlier than " .. rpc .. " request to HMI"
      end
      return true
    end)
    :ValidIf(function(exp, data)
      if revert_rpc == rpc then
        if isRevertRpc(data) and exp.occurences ~= 3 then
          return false, "Revert RPC on HMI for " .. rpc .. " RPC is received earlier than expected"
        elseif not isRevertRpc(data) and exp.occurences == 3 then
          return false, "Revert RPC on HMI for " .. rpc .. " RPC is not received"
        end
      end
      return true
    end)
  :Times(numOfRequests)

  if rpc ~= revert_rpc then
    m.getHMIConnection():ExpectRequest(iface .. "." .. revert_rpc)
    :Do(function(_, data)
        m.log(data.method)
        m.log(data.method .. ": SUCCESS")
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", m.getSuccessHMIResponseData(data))
      end)
    :Times(numOfRevertRequests)
  end

  m.expOnHMIStatus(1, "LIMITED")
  m.expOnHMIStatus(2, "FULL")

  m.reRegisterAppCustom(1, "RESUME_FAILED", 0):Do(function() isRAIResponseSent[1] = true end)
  if pTimeToRegApp2 == m.timeToRegApp2.BEFORE_REQUEST then
    m.reRegisterAppCustom(2, "SUCCESS", 10):Do(function() isRAIResponseSent[2] = true end)
  end
end

--[[ @isSubscribed: send OnInteriorVehicleData
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pIsExpApp1 - true(default) - if it's expected notification on mobile app1
--! pIsExpApp2 - true - if it's expected notification on mobile app2
--! pModuleType - module type to subscribe for
--! pModuleId - module id to subscribe for
--! @return: none
--]]
function m.isSubscribed(pIsExpApp1, pIsExpApp2, pModuleType, pModuleId)
  if pIsExpApp1 == nil then pIsExpApp1 = true end
  pModuleType = pModuleType or m.defaultModuleType
  pModuleId = pModuleId or m.getModuleControlData(pModuleType,1).moduleId
  rc.rc.isSubscribed(pModuleType, pModuleId, 1, pIsExpApp1)
  if pIsExpApp2 ~= nil then
    local occurences2 = pIsExpApp2 == true and 1 or 0
    local params = m.getActualModuleIVData(pModuleType, pModuleId)
    m.getMobileSession(2):ExpectNotification("OnInteriorVehicleData", { moduleData = params }):Times(occurences2)
  end
end

--[[ @geInteriorVDvalue: get value for interior vehicle data with moduleType, moduleId, subscribe parameters
--! @parameters:
--! pModuleType - module type value to define in structure
--! pSubscribe - subscribe value to define in structure
--! pModuleId - module id value to define in structure
--! @return: built structure
--]]
function m.geInteriorVDvalue(pModuleType, pSubscribe, pModuleId)
  pModuleId = pModuleId or m.getModuleControlData(pModuleType, 1).moduleId
  return { moduleType = pModuleType, moduleId = pModuleId, subscribe = pSubscribe }
end

--[[ @interiorVDvalidation: validation function for GetInteriorVehicleData request
--! @parameters:
--! pOccurences - actual occurrence of GetInteriorVehicleData requests
--! pExpectedNumber - expected number of GetInteriorVehicleData requests
--! pActualData - actual data to compare
--! pExpectedData - expected data to compare
--! @return: validation result
--]]
function m.interiorVDvalidation(pOccurences, pExpectedNumber, pActualData, pExpectedData)
  if pOccurences == pExpectedNumber then
    if m.isTableEqual(pExpectedData, pActualData) == false then
      local errorMessage = "Wrong expected requests are received\n" ..
      "Actual result:" .. m.tableToString(pActualData) .. "\n" ..
      "Expected result:" .. m.tableToString(pExpectedData) .."\n"
    return false, errorMessage
    end
  end
  return true
end

return m
