---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.checkAllValidations = true
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local json = require("modules/json")
local utils = require('user_modules/utils')
local actions = require("user_modules/sequences/actions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonRC = require('test_scripts/RC/commonRC')
local commonSteps = require("user_modules/shared_testcases/commonSteps")

--[[ Common Variables ]]
local c = actions

local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

c.notificationTime = 0
c.jsonFileToTable = utils.jsonFileToTable
c.tableToJsonFile = utils.tableToJsonFile
c.cloneTable = utils.cloneTable
c.modules = { "RADIO", "CLIMATE" }

c.rpcs = {}

c.rpcsArray = {
  "SendLocation",
  "Alert",
  "PerformInteraction",
  "Slider",
  "Speak",
  "ScrollableMessage",
  "DiagnosticMessage",
  "SetInteriorVehicleData"
}

c.rpcsArrayWithoutRPCWithCustomTimeout = {
  "SendLocation",
  "Speak",
  "DiagnosticMessage",
  "SetInteriorVehicleData"
}

--[[ Common Functions ]]

--[[ @updatePreloadedPT: Update preloaded file with additional permissions
--! @parameters: none
--! @return: none
--]]
local function updatePreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
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

  --insert application "0000001" into "app_policies"
  pt.policy_table.app_policies["0000001"] = c.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies["0000001"].groups = { "Base-4", "NewTestCaseGroup", "RemoteControl" }
  pt.policy_table.app_policies["0000001"].moduleType = c.modules
  pt.policy_table.app_policies["0000001"].AppHMIType = { "REMOTE_CONTROL" }

  --insert application "0000002" into "app_policies"
  pt.policy_table.app_policies["0000002"] = c.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies["0000002"].groups = { "Base-4", "NewTestCaseGroup", "RemoteControl" }
  pt.policy_table.app_policies["0000002"].moduleType = c.modules
  pt.policy_table.app_policies["0000002"].AppHMIType = { "REMOTE_CONTROL" }

  utils.tableToJsonFile(pt, preloadedFile)
end

--[[ @preconditions: Remove policy DB, Logs, create backup and update for preloaded file
--! @parameters: none
--! @return: none
--]]
function c.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
  commonPreconditions:BackupFile(preloadedPT)
  updatePreloadedPT()
end

--[[ @postconditions: postcondition steps
--! @parameters: none
--! @return: none
--]]
local originPostconditions = c.postconditions
function c.postconditions()
  originPostconditions()
  commonPreconditions:RestoreFile(preloadedPT)
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
    c.onResetTimeoutNotification(pData.id, pData.method, pOnRTParams. resetPeriod)
  end
  local function sendresponse()
    c.getHMIConnection():SendResponse(pData.id, pData.method, "SUCCESS", pOnRTParams.respParams)
  end
  RUN_AFTER(sendresponse, pOnRTParams.respTime)
  RUN_AFTER(sendOnResetTimeout, pOnRTParams.notificationTime)
end

--[[ @withoutResponseWithOnResetTimeout: Send OnResetTimeout notification from HMI
--! @parameters:
--! pData - request data for sending response
--! pOnRTParams - parameters for BasicCommunication.OnResetTimeout
--! @return: none
--]]
function c.withoutResponseWithOnResetTimeout(pData, pOnRTParams)
  local function sendOnResetTimeout()
    c.onResetTimeoutNotification(pData.id, pData.method, pOnRTParams.resetPeriod)
  end
  RUN_AFTER(sendOnResetTimeout, pOnRTParams.notificationTime)
end

--[[ @createInteractionChoiceSet: Creation of Choice Set
--! @parameters: none
--! @return: none
--]]
function c.createInteractionChoiceSet()
  local params = {
    interactionChoiceSetID = 100,
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

--[[ @SendLocation: Successful processing SendLocation RPC
--! @parameters:
--! pExpTimoutForMobResp - timeout for mobile response expectation
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
--! pHMIRespFunc - custom function which executed after HMI request is received
--! pOnRTParams - parameters for BC.OnResetTimeout
--! pExpMobRespParams - parameters for mobile response
--! @return: none
--]]
function c.rpcs.SendLocation( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams )
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
  EXPECT_HMICALL("Navigation.SendLocation", { appID = c.getHMIAppId() })
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams)
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
function c.rpcs.Alert( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams )
  local paramsAlert = {
    ttsChunks = {
      { type = "TEXT",
        text = "pathToFile"
      }
    },
    alertText1 = "alertText1",
    progressIndicator = true,
    duration = 3000
  }
  local cid = c.getMobileSession():SendRPC("Alert", paramsAlert)

  c.getHMIConnection():ExpectRequest( "UI.Alert", {
      alertStrings = {
        { fieldName = "alertText1",
          fieldText = "alertText1"
        }
      },
      duration = 3000,
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
      return c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams)
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
function c.rpcs.PerformInteraction( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams )
  local params = {
    initialText = "StartPerformInteraction",
    interactionMode = "VR_ONLY",
    interactionChoiceSetIDList = { 100 },
    initialPrompt = {
      { type = "TEXT", text = "pathToFile1" }
    },
    timeout = 5000
  }
  local corId = c.getMobileSession():SendRPC("PerformInteraction", params)
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
      return c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams)
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
function c.rpcs.Slider( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams )
  local cid = c.getMobileSession():SendRPC("Slider", {
      numTicks = 7,
      position = 1,
      sliderHeader ="sliderHeader",
      sliderFooter = { "sliderFooter" },
      timeout = 1000
    })

  EXPECT_HMICALL("UI.Slider", { appID = c.getHMIAppId() })
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)

  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams)
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
function c.rpcs.Speak( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams )
  local paramsSpeak = {
    ttsChunks = {
      { text ="a",
        type ="TEXT"
      }
    }
  }
  local cid = c.getMobileSession():SendRPC("Speak", paramsSpeak)
  EXPECT_HMICALL("TTS.Speak", { ttsChunks = paramsSpeak.ttsChunks })
  :Do(function(_, data)
      pOnRTParams.respParams = { }
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams)
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
function c.rpcs.DiagnosticMessage( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams )
  local cid = c.getMobileSession():SendRPC("DiagnosticMessage",
    { targetID = 1,
      messageLength = 1,
      messageData = { 1 }
    })
  EXPECT_HMICALL("VehicleInfo.DiagnosticMessage",
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
      return c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams)
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
function c.rpcs.ScrollableMessage( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams )
  local requestParams = {
    scrollableMessageBody = "abc",
    timeout = 1000
  }
  local cid = c.getMobileSession():SendRPC("ScrollableMessage", requestParams)

  EXPECT_HMICALL("UI.ScrollableMessage", {
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
      return c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams)
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
function c.rpcs.SetInteriorVehicleData( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams )
  local cid = c.getMobileSession():SendRPC(commonRC.getAppEventName("SetInteriorVehicleData"),
    commonRC.getAppRequestParams("SetInteriorVehicleData", "CLIMATE" ))
  EXPECT_HMICALL(commonRC.getHMIEventName("SetInteriorVehicleData"),
    commonRC.getHMIRequestParams("SetInteriorVehicleData", "CLIMATE"))
  :Do(function(_, data)
      pOnRTParams.respParams = commonRC.getHMIResponseParams("SetInteriorVehicleData", "CLIMATE")
      pHMIRespFunc(data, pOnRTParams)
    end)
  c.getMobileSession():ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams)
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
function c.rpcs.rpcAllowedWithConsent( pExpTimoutForMobResp, pExpTimeBetweenResp, pHMIRespFunc, pOnRTParams, pExpMobRespParams )
  local cid = c.getMobileSession(2):SendRPC(commonRC.getAppEventName("SetInteriorVehicleData"),
    commonRC.getAppRequestParams("SetInteriorVehicleData", "CLIMATE"))

  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, "CLIMATE", 2))
  :Do(function(_, data)
      pOnRTParams.respParams = commonRC.getHMIResponseParams(consentRPC, true)
      pHMIRespFunc(data, pOnRTParams)
    end)

  EXPECT_HMICALL(commonRC.getHMIEventName("SetInteriorVehicleData"),
    commonRC.getHMIRequestParams("SetInteriorVehicleData", "CLIMATE", 2))
  :Do(function(_, data)
      c.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        commonRC.getHMIResponseParams("SetInteriorVehicleData", "CLIMATE"))
    end)
  :Timeout(pExpTimoutForMobResp)
  :Times(AtMost(1))

  c.getMobileSession(2):ExpectResponse(cid, pExpMobRespParams)
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      return c.responseTimeCalculation(pExpTimeBetweenResp, pOnRTParams)
    end)
end

--[[ @responseTimeCalculation: compare expected and actual time between starting event(OnResetTimeout notification from
--! HMI or request from mobile app) and mobile response
--! @parameters:
--! pExpTimeBetweenResp - time between the mobile response and sending the OnResetTimeout notification from HMI
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
  local timeBetweenRespAndNot = respTime - pStartEventTime
  if timeBetweenRespAndNot >= pExpTimeBetweenResp - inaccuracy and timeBetweenRespAndNot <= pExpTimeBetweenResp + inaccuracy then
    return true
  else
    return false, "Response is received in some unexpected time. Actual time is " .. timeBetweenRespAndNot ..
    ". Expected time is " .. pExpTimeBetweenResp
  end
end

return c
