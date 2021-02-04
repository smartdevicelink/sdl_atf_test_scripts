---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local m = {}

--[[ Common Proxy Functions ]]
  m.Title = runner.Title
  m.Step = runner.Step
  m.preconditions = actions.preconditions
  m.postconditions = actions.postconditions
  m.start = actions.start
  m.registerApp = actions.app.register
  m.registerAppWOPTU = actions.app.registerNoPTU
  m.activateApp = actions.app.activate
  m.getMobileSession = actions.getMobileSession
  m.getHMIConnection = actions.hmi.getConnection
  m.policyTableUpdate = actions.policyTableUpdate
  m.getHMIAppId = actions.getHMIAppId
  m.cloneTable = utils.cloneTable
  m.connectMobile = actions.mobile.connect
  m.wait = utils.wait
  m.json = actions.json
  m.getPolicyAppId = actions.app.getPolicyAppId
  m.getParams = actions.app.getParams
  m.spairs = utils.spairs
  m.isTableEqual = utils.isTableEqual
  m.tableToString = utils.tableToString

--[[ Common Variables ]]
m.expected = {
  yes = 1,
  no = 0
}

m.result = {
  success = { success = true, resultCode = "SUCCESS" },
  data_not_available = { success = false, resultCode = "DATA_NOT_AVAILABLE" },
  invalid_data = { success = false, resultCode = "INVALID_DATA" }
}

m.hashId = ""

--[[ Common Functions ]]

--[[ @getDispCaps: Provide system capabilities with default keyboard capabilities
--! @parameters: none
--! @return: table with capabilities
--]]
function m.getDispCaps()
  return {
    systemCapability = {
      systemCapabilityType = "DISPLAYS",
      displayCapabilities = {
        {
          displayName = "MainDisplayName",
          windowCapabilities = {
            {
              windowID = 0,
              keyboardCapabilities = {
                maskInputCharactersSupported = true,
                supportedKeyboards = {
                  { keyboardLayout = "QWERTY", numConfigurableKeys = 4 },
                  { keyboardLayout = "QWERTZ", numConfigurableKeys = 3 },
                  { keyboardLayout = "AZERTY", numConfigurableKeys = 2 },
                  { keyboardLayout = "NUMERIC", numConfigurableKeys = 1 },
                }
              }
            }
          }
        }
      }
    }
  }
end

--[[ @getArrayValue: Generate array value
--! @parameters:
--! pPossibleValuesTbl - array of possible values
--! pNumOfElements - number of elements in array
--! @return: table with array value
--]]
function m.getArrayValue(pPossibleValuesTbl, pNumOfElements)
  local out = {}
  for i = 0, pNumOfElements-1 do
    table.insert(out, pPossibleValuesTbl[i%#pPossibleValuesTbl+1])
  end
  return out
end

--[[ @sendOnSystemCapabilityUpdated: Processing of 'OnSystemCapabilityUpdated' notification: HMI->SDL->App
--! @parameters:
--! pData - source/expected data for notification
--! pTimes - expected number of notifications (0, 1 or more)
--! pValidFunc - validation function
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.sendOnSystemCapabilityUpdated(pData, pTimes, pValidFunc, pAppId)
  if not pData then pData = m.getDispCaps() end
  if not pTimes then pTimes = 1 end
  if not pValidFunc then pValidFunc = function() return true end end
  local expDataToMobile = pData
  local dataFromHMI = utils.cloneTable(expDataToMobile)
  dataFromHMI.appID = m.getHMIAppId(pAppId)
  m.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", dataFromHMI)
  m.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated", expDataToMobile)
  :Times(pTimes)
  :ValidIf(pValidFunc)
end

--[[ @sendOnKeyboardInput: Processing of 'OnKeyboardInput' notification: HMI->SDL->App
--! @parameters:
--! pData - source/expected data for notification
--! pTimes - expected number of notifications (0, 1 or more)
--! pValidFunc - validation function
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.sendOnKeyboardInput(pData, pTimes, pValidFunc, pAppId)
  if not pTimes then pTimes = 1 end
  if not pValidFunc then pValidFunc = function() return true end end
  m.getHMIConnection():SendNotification("UI.OnKeyboardInput", pData)
  m.getMobileSession(pAppId):ExpectNotification("OnKeyboardInput", pData)
  :Times(pTimes)
  :ValidIf(pValidFunc)
end

--[[ @sendGetSystemCapability: Processing of 'GetSystemCapability' request: App->SDL->App
--! @parameters:
--! pData - expected data in response
--! pExpRes - expected result in response
--! pValidFunc - validation function
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.sendGetSystemCapability(pData, pExpRes, pValidFunc, pAppId)
  if not pData then pData = m.getDispCaps() end
  if not pExpRes then pExpRes = utils.cloneTable(m.result.success) end
  if pData.systemCapability then pExpRes.systemCapability = pData.systemCapability end
  if not pValidFunc then pValidFunc = function() return true end end
  local cid = m.getMobileSession(pAppId):SendRPC("GetSystemCapability", { systemCapabilityType = "DISPLAYS" })
  m.getMobileSession(pAppId):ExpectResponse(cid, pExpRes)
  :ValidIf(pValidFunc)
end

--[[ @sendSetGlobalProperties: Processing of 'SetGlobalProperties' request: App->SDL->HMI->SDL->App
--! @parameters:
--! pData - expected data in response
--! pExpRes - expected result in response
--! pValidFunc - validation function
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.sendSetGlobalProperties(pData, pExpRes, pValidFunc, pAppId)
  if not pExpRes then pExpRes = m.result.success end
  if not pValidFunc then pValidFunc = function() return true end end
  local dataToHMI = utils.cloneTable(pData)
  dataToHMI.appID = m.getHMIAppId(pAppId)
  local times = 1
  if pExpRes.success == false then times = 0 end
  local cid = m.getMobileSession(pAppId):SendRPC("SetGlobalProperties", pData)
  m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(times)
  m.getMobileSession(pAppId):ExpectResponse(cid, pExpRes)
  :ValidIf(pValidFunc)
end

--[[ @unexpectedDisconnect: Unexpected disconnect sequence
--! @parameters: none
--! @return: none
--]]
function m.unexpectedDisconnect()
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(actions.mobile.getAppsCount())
  actions.mobile.disconnect()
  utils.wait(1000)
end

--[[ @reRegisterApp: App registration with resumption of UI.SetGlobalProperties
--! @parameters:
--! pResumptionParams - parameters for UI.SetGlobalProperties
--! @return: none
--]]
function m.reRegisterApp(pResumptionParams)
  m.getMobileSession():StartService(7)
  :Do(function()
    local appParams = m.cloneTable(m.getParams())
    appParams.hashID = m.hashId
    local cid = m.getMobileSession():SendRPC("RegisterAppInterface", appParams)
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
    :Do(function()
        local dataToHMI = m.cloneTable(pResumptionParams)
        m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
        :Do(function(_, data)
            m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          end)
        :ValidIf(function(_, data)
            if not m.isTableEqual(data.params.keyboardProperties, dataToHMI.keyboardProperties) then
              return false, "Unexpected number of parameters or parameter values are received"
               .. " in UI.SetGlobalProperties request"
               .. "\n Expected data: " .. m.tableToString(dataToHMI.keyboardProperties)
               .. "\n Actual data: " .. m.tableToString(data.params.keyboardProperties)
            end
            return true
          end)
      end)
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  end)
end

--[[ @sendSetGlobalPropertiesWithHashId: Processing of 'SetGlobalProperties' request and OnHashChange notification
--! @parameters: some number of params for m.sendSetGlobalProperties function
--! @return: none
--]]
function m.sendSetGlobalPropertiesWithHashId(...)
  m.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId = data.payload.hashID
    end)
  m.sendSetGlobalProperties(...)
end


return m
