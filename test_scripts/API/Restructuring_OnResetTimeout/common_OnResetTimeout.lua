---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.checkAllValidations = true

--[[ Required Shared libraries ]]
local json = require("modules/json")
local utils = require('user_modules/utils')
local actions = require("user_modules/sequences/actions")
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Tests Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Common Variables ]]
local c = {}
c.start = actions.start
c.registerAppWOPTU = actions.registerAppWOPTU
c.activateApp = actions.activateApp
c.postconditions = actions.postconditions
c.getMobileSession = actions.mobile.getSession
c.getHMIConnection = actions.hmi.getConnection
c.getHMIAppId = actions.app.getHMIId
c.defineRAMode = commonRC.defineRAMode
c.rpcAllowed = commonRC.rpcAllowed
c.getAppEventName = commonRC.getAppEventName
c.getAppRequestParams = commonRC.getAppRequestParams
c.getHMIEventName = commonRC.getHMIEventName
c.getHMIRequestParams = commonRC.getHMIRequestParams
c.getHMIResponseParams = commonRC.getHMIResponseParams
c.getConfigAppParams = actions.getConfigAppParams

c.notificationTime = 0
c.jsonFileToTable = utils.jsonFileToTable
c.tableToJsonFile = utils.tableToJsonFile
c.cloneTable = utils.cloneTable
c.Step = runner.Step
c.Title = runner.Title

c.modules = { "RADIO", "CLIMATE" }

c.rpcs = {}

c.rpcsArray = {
  "SendLocation",
  "Alert",
  "SubtleAlert",
  "PerformInteraction",
  "Slider",
  "Speak",
  "ScrollableMessage",
  "DiagnosticMessage",
  "SetInteriorVehicleData",
  "CreateInteractionChoiceSet",
  "DeleteInteractionChoiceSet",
  "DeleteSubMenu",
  "AlertManeuver",
  "AddCommand",
  "ChangeRegistration",
  "SetGlobalProperties",
  "AddSubMenu"
}

c.rpcsArrayWithCustomTimeout = {
  ["PerformInteraction"] = { timeout = 5000 },
  ["ScrollableMessage"] = { timeout = 1000 },
  ["Alert"] = { timeout = 3000 },
  ["SubtleAlert"] = { timeout = 3000 },
  ["Slider"] = { timeout = 1000 }
}

c.defaultTimeout = actions.sdl.getSDLIniParameter("DefaultTimeout")

--[[ Common Functions ]]

--[[ @updatePreloadedPT: Update preloaded file with additional permissions
--! @parameters: none
--! @return: none
--]]
local function updatePreloadedPT()
  local pt = actions.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  local additionalRPCs = {
    "SendLocation", "DialNumber", "DiagnosticMessage"
  }
  pt.policy_table.functional_groupings.NewTestCaseGroup = { rpcs = { } }
  for _, v in pairs(additionalRPCs) do
    pt.policy_table.functional_groupings.NewTestCaseGroup.rpcs[v] = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
    }
  end

  --insert applications into "app_policies"
  for i = 1, 2 do
    local policyAppId = c.getConfigAppParams(i).fullAppID
    pt.policy_table.app_policies[policyAppId] = c.cloneTable(pt.policy_table.app_policies.default)
    pt.policy_table.app_policies[policyAppId].groups = { "Base-4", "NewTestCaseGroup", "Navigation-1" }
    pt.policy_table.app_policies[policyAppId].moduleType = c.modules
    if c.getConfigAppParams(i).appHMIType[1] == "REMOTE_CONTROL" then
      pt.policy_table.app_policies[policyAppId].moduleType = c.modules
      pt.policy_table.app_policies[policyAppId].AppHMIType = { "REMOTE_CONTROL" }
      table.insert(pt.policy_table.app_policies[policyAppId].groups, "RemoteControl")
    end
  end

  actions.sdl.setPreloadedPT(pt)
end

--[[ @preconditions: Remove policy DB, Logs, create backup and update for preloaded file
--! @parameters: none
--! @return: none
--]]
function c.preconditions()
  actions.preconditions()
  updatePreloadedPT()
end

--[[ @onResetTimeoutNotification: Send OnResetTimeout notification from HMI
--! @parameters:
--! pRequestID - request id between HMI and SDL
--! pMethodName - RPC method name
--! pResetPeriod - timeout period in milliseconds, for the method for which timeout needs to be reset
--! @return: none
--]]
function c.onResetTimeoutNotification(pRequestID, pMethodName, pResetPeriod)
  c.getHMIConnection():SendNotification("BasicCommunication.OnResetTimeout",
    { requestID = pRequestID,
      methodName = pMethodName,
      resetPeriod = pResetPeriod
    })
  c.notificationTime = timestamp()
end

--[[ @responseWithOnResetTimeout: Send response and OnResetTimeout notification from HMI
--! @parameters:
--! pData - request data for sending response
--! pOnRTParams - parameters for BasicCommunication.OnResetTimeout
--! @return: none
--]]
function c.responseWithOnResetTimeout(pData, pOnRTParams)
  local function sendOnResetTimeout()
    c.onResetTimeoutNotification(pData.id, pData.method, pOnRTParams.resetPeriod)
  end
  local function sendresponse()
    c.getHMIConnection():SendResponse(pData.id, pData.method, "SUCCESS", pOnRTParams.respParams)
  end
  RUN_AFTER(sendresponse, pOnRTParams.respTime)
  RUN_AFTER(sendOnResetTimeout, pOnRTParams.notificationTime)
end

--[[ @onResetTimeoutOnly: Send OnResetTimeout notification from HMI
--! @parameters:
--! pData - request data for sending response
--! pOnRTParams - parameters for BasicCommunication.OnResetTimeout
--! @return: none
--]]
function c.onResetTimeoutOnly(pData, pOnRTParams)
  local function sendOnResetTimeout()
    c.onResetTimeoutNotification(pData.id, pData.method, pOnRTParams.resetPeriod)
  end
  RUN_AFTER(sendOnResetTimeout, pOnRTParams.notificationTime)
end

--[[ @CreateInteractionChoiceSet: Creation of Choice Set
--! @parameters:
--! pID - unique ID for interaction choice set
--! @return: none
--]]
function c.createInteractionChoiceSet(pID)
  local params = {
    interactionChoiceSetID = pID,
    choiceSet = {
      {
        choiceID = 111,
        menuName = "Choice111",
        vrCommands = { "Choice111" }
      }
    }
  }
  local corId = c.getMobileSession():SendRPC("CreateInteractionChoiceSet", params)
  c.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  c.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

--[[ @AddSubMenu: Add SubMenu
--! @parameters: none
--! @return: none
--]]
function c.addSubMenu()
  local params = {
    menuID = 1000,
    position = 500,
    menuName ="SubMenupositive"
  }
  local corId = c.getMobileSession():SendRPC("AddSubMenu", params)
  c.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  c.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

--[[ @SendLocation: Successful processing SendLocation RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.SendLocation( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local sendLocationRequestParams = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1,
    locationName = "location Name",
    locationDescription = "location Description",
    addressLines = {
      "line1",
      "line2",
    },
    phoneNumber = "phone Number"
  }
  local cid = c.getMobileSession():SendRPC("SendLocation", sendLocationRequestParams)
  local pRequestTime = timestamp()

  c.getHMIConnection():ExpectRequest("Navigation.SendLocation", { appID = c.getHMIAppId() })
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @Alert: Successful processing Alert RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.Alert( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local paramsAlert = {
    ttsChunks = {
      { type = "TEXT",
        text = "pathToFile"
      }
    },
    alertText1 = "alertText1",
    progressIndicator = true,
    duration = c.rpcsArrayWithCustomTimeout["Alert"].timeout
  }
  local cid = c.getMobileSession():SendRPC("Alert", paramsAlert)
  local pRequestTime = timestamp()

  c.getHMIConnection():ExpectRequest( "UI.Alert", {
      alertStrings = {
        { fieldName = "alertText1",
          fieldText = "alertText1"
        }
      },
      duration = c.rpcsArrayWithCustomTimeout["Alert"].timeout,
      alertType = "BOTH",
      appID = c.getHMIAppId()
    })
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)

  c.getHMIConnection():ExpectRequest("TTS.Speak", {
      ttsChunks = paramsAlert.ttsChunks,
      speakType = "ALERT",
      appID = c.getHMIAppId()
    })
  :Do(function(_, data)
      local function SpeakResponse()
        c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      RUN_AFTER(SpeakResponse, 2000)
    end)

  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @SubtleAlert: Successful processing SubtleAlert RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.SubtleAlert( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local paramsAlert = {
    ttsChunks = {
      { type = "TEXT",
        text = "pathToFile"
      }
    },
    alertText1 = "alertText1",
    duration = c.rpcsArrayWithCustomTimeout["SubtleAlert"].timeout
  }
  local cid = c.getMobileSession():SendRPC("SubtleAlert", paramsAlert)
  local pRequestTime = timestamp()

  c.getHMIConnection():ExpectRequest( "UI.SubtleAlert", {
      alertStrings = {
        { fieldName = "subtleAlertText1",
          fieldText = "alertText1"
        }
      },
      duration = c.rpcsArrayWithCustomTimeout["SubtleAlert"].timeout,
      alertType = "BOTH",
      appID = c.getHMIAppId()
    })
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)

  c.getHMIConnection():ExpectRequest("TTS.Speak", {
      ttsChunks = paramsAlert.ttsChunks,
      speakType = "SUBTLE_ALERT",
      appID = c.getHMIAppId()
    })
  :Do(function(_, data)
      local function SpeakResponse()
        c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      RUN_AFTER(SpeakResponse, 2000)
    end)

  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @PerformInteraction: Successful processing PerformInteraction RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.PerformInteraction( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local params = {
    initialText = "StartPerformInteraction",
    interactionMode = "VR_ONLY",
    interactionChoiceSetIDList = { 100 },
    initialPrompt = {
      { type = "TEXT", text = "pathToFile1" }
    },
    timeout = c.rpcsArrayWithCustomTimeout["PerformInteraction"].timeout
  }
  local corId = c.getMobileSession():SendRPC("PerformInteraction", params)
  local pRequestTime = timestamp()
  c.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Do(function(_, data)
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  c.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
      initialPrompt = params.initialPrompt
    })
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(corId, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @Slider: Successful processing Slider RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.Slider( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local cid = c.getMobileSession():SendRPC("Slider", {
      numTicks = 7,
      position = 1,
      sliderHeader ="sliderHeader",
      sliderFooter = { "sliderFooter" },
      timeout = c.rpcsArrayWithCustomTimeout["Slider"].timeout
    })
  local pRequestTime = timestamp()

  c.getHMIConnection():ExpectRequest("UI.Slider", { appID = c.getHMIAppId() })
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)

  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @Speak: Successful processing Speak RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.Speak( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local paramsSpeak = {
    ttsChunks = {
      { text ="a",
        type ="TEXT"
      }
    }
  }
  local cid = c.getMobileSession():SendRPC("Speak", paramsSpeak)
  local  pRequestTime = timestamp()
  c.getHMIConnection():ExpectRequest("TTS.Speak", { ttsChunks = paramsSpeak.ttsChunks })
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @DiagnosticMessage: Successful processing DiagnosticMessage RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.DiagnosticMessage( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local cid = c.getMobileSession():SendRPC("DiagnosticMessage",
    { targetID = 1,
      messageLength = 1,
      messageData = { 1 }
    })
  local pRequestTime = timestamp()
  c.getHMIConnection():ExpectRequest("VehicleInfo.DiagnosticMessage",
    { targetID = 1,
      messageLength = 1,
      messageData = { 1 }
    })
  :Do(function(_, data)
      pOnRTParams.respParams = { messageDataResult = {12} }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @ScrollableMessage: Successful processing ScrollableMessage RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.ScrollableMessage( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local requestParams = {
    scrollableMessageBody = "abc",
    timeout = c.rpcsArrayWithCustomTimeout["ScrollableMessage"].timeout
  }
  local cid = c.getMobileSession():SendRPC("ScrollableMessage", requestParams)
  local pRequestTime = timestamp()

  c.getHMIConnection():ExpectRequest("UI.ScrollableMessage", {
      messageText = {
        fieldName = "scrollableMessageBody",
        fieldText = requestParams.scrollableMessageBody
      },
      appID = c.getHMIAppId(),
      timeout = 1000
    })
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)

  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @SetInteriorVehicleData: Successful processing SetInteriorVehicleData RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.SetInteriorVehicleData( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local cid = c.getMobileSession():SendRPC(c.getAppEventName("SetInteriorVehicleData"),
    c.getAppRequestParams("SetInteriorVehicleData", "CLIMATE" ))
  local pRequestTime = timestamp()

  c.getHMIConnection():ExpectRequest(c.getHMIEventName("SetInteriorVehicleData"),
    c.getHMIRequestParams("SetInteriorVehicleData", "CLIMATE"))
  :Do(function(_, data)
      pOnRTParams.respParams = c.getHMIResponseParams("SetInteriorVehicleData", "CLIMATE")
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @CreateInteractionChoiceSet: Successful processing CreateInteractionChoiceSet RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.CreateInteractionChoiceSet( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local params = {
    interactionChoiceSetID = 300,
    choiceSet = {
      {
        choiceID = 333,
        menuName = "Choice333",
        vrCommands = { "Choice333" }
      }
    }
  }
  local corId = c.getMobileSession():SendRPC("CreateInteractionChoiceSet", params)
  local pRequestTime = timestamp()
  c.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(corId, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @DeleteInteractionChoiceSet: Successful processing DeleteInteractionChoiceSet RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.DeleteInteractionChoiceSet( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local params = {
    interactionChoiceSetID = 200
  }
  local corId = c.getMobileSession():SendRPC("DeleteInteractionChoiceSet", params)
  local pRequestTime = timestamp()
  c.getHMIConnection():ExpectRequest("VR.DeleteCommand")
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(corId, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @DeleteSubMenu: Successful processing DeleteSubMenu RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.DeleteSubMenu( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local params = {
    menuID = 1000
  }
  local corId = c.getMobileSession():SendRPC("DeleteSubMenu", params)
  local pRequestTime = timestamp()
  c.getHMIConnection():ExpectRequest("UI.DeleteSubMenu")
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(corId, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @AddSubMenu: Successful processing AddSubMenu RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.AddSubMenu( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local params = {
    menuID = 2000,
    position = 600,
    menuName ="SubMenu2"
  }
  local corId = c.getMobileSession():SendRPC("AddSubMenu", params)
  local pRequestTime = timestamp()
  c.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(corId, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @AlertManeuver: Successful processing AlertManeuver RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.AlertManeuver( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local params = {
    ttsChunks = {
      { type = "TEXT",
        text = "alertManeuver"
      }
    }
  }
  local corId = c.getMobileSession():SendRPC("AlertManeuver", params)
  local pRequestTime = timestamp()
  c.getHMIConnection():ExpectRequest("Navigation.AlertManeuver")
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getHMIConnection():ExpectRequest("TTS.Speak")
  :Do(function(_, data)
      local function SpeakResponse()
        c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      RUN_AFTER(SpeakResponse, 2000)
    end)
  c.getMobileSession():ExpectResponse(corId, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @AddCommand: Successful processing AddCommand RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.AddCommand( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local params = {
    cmdID = 123,
    menuParams = {
      position = 0,
      menuName = "CommandPositive"
    },
    vrCommands = {
      "VRCommandonepositive"
    }
  }
  local corId = c.getMobileSession():SendRPC("AddCommand", params)
  local pRequestTime = timestamp()
  c.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      local function response()
        c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      RUN_AFTER(response, 2000)
    end)
  c.getMobileSession():ExpectResponse(corId, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @ChangeRegistration: Successful processing ChangeRegistration RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.ChangeRegistration( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local params = {
    language ="EN-US",
    hmiDisplayLanguage ="EN-US"
  }
  local corId = c.getMobileSession():SendRPC("ChangeRegistration", params)
  local pRequestTime = timestamp()
  c.getHMIConnection():ExpectRequest("UI.ChangeRegistration")
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getHMIConnection():ExpectRequest("VR.ChangeRegistration")
  :Do(function(_, data)
      local function response()
        c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      RUN_AFTER(response, 1000)
    end)
  c.getHMIConnection():ExpectRequest("TTS.ChangeRegistration")
  :Do(function(_, data)
      local function response()
        c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      RUN_AFTER(response, 2000)
    end)
  c.getMobileSession():ExpectResponse(corId, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @SetGlobalProperties: Successful processing SetGlobalProperties RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.SetGlobalProperties( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local params = {
    menuTitle = "Menu Title"
  }
  local corId = c.getMobileSession():SendRPC("SetGlobalProperties", params)
  local pRequestTime = timestamp()
  c.getHMIConnection():ExpectRequest("UI.SetGlobalProperties")
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(corId, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @rpcAllowedWithConsent: Successful processing SetInteriorVehicleData with consent
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.rpcAllowedWithConsent( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams, pCalculationFunction )
  local cid = c.getMobileSession(2):SendRPC(c.getAppEventName("SetInteriorVehicleData"),
    c.getAppRequestParams("SetInteriorVehicleData", "CLIMATE"))
  local pRequestTime = timestamp()
  local consentRPC = "GetInteriorVehicleDataConsent"
  c.getHMIConnection():ExpectRequest(c.getHMIEventName(consentRPC), c.getHMIRequestParams(consentRPC, "CLIMATE", 2))
  :Do(function(_, data)
      pOnRTParams.respParams = c.getHMIResponseParams(consentRPC, true)
      pHMIRespFunc(data, pOnRTParams)
    end)

  c.getHMIConnection():ExpectRequest(c.getHMIEventName("SetInteriorVehicleData"),
    c.getHMIRequestParams("SetInteriorVehicleData", "CLIMATE", 2))
  :Do(function(_, data)
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        c.getHMIResponseParams("SetInteriorVehicleData", "CLIMATE"))
    end)
  :Timeout(pExpTimoutForMobResp)
  :Times(AtMost(1))

  c.getMobileSession(2):ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return pCalculationFunction(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
    end)
end

--[[ @responseTimeCalculation: compare expected and actual time between starting event(OnResetTimeout notification from
--! HMI or request from mobile app) and mobile response
--! @parameters:
--! pExpTimeBetweenResp - expected time between the mobile response and sending the OnResetTimeout notification from HMI
--! or request from mobile app
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pStartEventTime - time of the starting event(OnResetTimeout notification from HMI or request from mobile app)
--! @return: test status value and optional error message
--]]
function c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams, pStartEventTime)
  local respTime = timestamp()
  local inaccuracyTime
  if not pStartEventTime then pStartEventTime = c.notificationTime end
  if pOnRTParams and pOnRTParams.respTime then
    inaccuracyTime = pOnRTParams.respTime
  elseif pOnRTParams and pOnRTParams.notificationTime and pOnRTParams.notificationTime ~= 0 then
    inaccuracyTime = pOnRTParams.notificationTime
  else
    inaccuracyTime = pExpTimeBetweenResp
  end
  local inaccuracy = inaccuracyTime*6/100 -- This is 5% inaccuracy in timings in RUN_AFTER + 1% buffer
  local timeBetweenRespAndStartEvent = respTime - pStartEventTime

  if timeBetweenRespAndStartEvent >= pExpTimeBetweenResp - inaccuracy and
    timeBetweenRespAndStartEvent <= pExpTimeBetweenResp + inaccuracy then
    return true
  else
    return false, "Response is received in some unexpected time. Actual time is " .. timeBetweenRespAndStartEvent ..
    ". Expected time is " .. pExpTimeBetweenResp
  end
end

--[[ @responseTimeCalculationFromNotif: compare expected and actual time between OnResetTimeout notification from
--! HMI and mobile response
--! @parameters:
--! pExpTimeBetweenResp - expected time between the mobile response and sending the OnResetTimeout notification from HMI
--! or request from mobile app
--! pOnRTParams - parameters for BC.OnResetTimeout
--! @return: test status value and optional error message
--]]
function c.responseTimeCalculationFromNotif(pExpTimeBetweenResp, pOnRTParams)
  return c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams, c.notificationTime)
end

--[[ @responseTimeCalculationFromMobReq: compare expected and actual time between request from mobile app
--!  and mobile response
--! @parameters:
--! pExpTimeBetweenResp - expected time between the mobile response and sending the OnResetTimeout notification from HMI
--! or request from mobile app
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pRequestTime - time of the request from mobile app
--! @return: test status value and optional error message
--]]
function c.responseTimeCalculationFromMobReq(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
  return c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams, pRequestTime)
end

return c
