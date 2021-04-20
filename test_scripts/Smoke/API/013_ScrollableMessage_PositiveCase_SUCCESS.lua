---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: ScrollableMessage
-- Item: Happy path
--
-- Requirement summary:
-- [AddCommand] SUCCESS: getting SUCCESS on UI.ScrollableMessage()
--
-- Description:
-- Mobile application sends valid ScrollableMessage request

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests ScrollableMessage with valid values of parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if ScrollableMessage is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI request with allowed parameters to HMI
-- SDL receives UI response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local putFileParams = {
  requestParams = {
    syncFileName = 'icon.png',
      fileType = "GRAPHIC_PNG",
      persistentFile = false,
      systemFile = false
  },
  filePath = "files/icon.png"
}

local requestParams = {
  scrollableMessageBody = "abc",
  softButtons = {
    {
      softButtonID = 1,
      text = "Button1",
      type = "BOTH",
      image = {
        value = "icon.png",
        imageType = "DYNAMIC"
      },
      isHighlighted = false,
      systemAction = "DEFAULT_ACTION"
      },
    {
      softButtonID = 2,
      text = "Button2",
      type = "TEXT",
      isHighlighted = false,
      systemAction = "DEFAULT_ACTION"
    }
  },
  timeout = 5000
}

local responseUiParams = {
  messageText = {
    fieldName = "scrollableMessageBody",
    fieldText = requestParams.scrollableMessageBody
  },
  softButtons = requestParams.softButtons
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
}

--[[ Local Functions ]]
local function scrollableMessage(pParams)
  local cid = common.getMobileSession():SendRPC("ScrollableMessage", pParams.requestParams)
  pParams.responseUiParams.appID = common.getHMIAppId()
  for _, v in pairs(pParams.responseUiParams.softButtons) do
    if v.image then
      v.image.value = common.getPathToFileInAppStorage("icon.png")
    end
  end
  common.getHMIConnection():ExpectRequest("UI.ScrollableMessage", pParams.responseUiParams)
  :Do(function(_, data)
      common.getHMIConnection():SendNotification("UI.OnSystemContext", {
        appID = pParams.responseUiParams.appID, systemContext = "HMI_OBSCURED"
      })
      local function uiResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        common.getHMIConnection():SendNotification("UI.OnSystemContext", {
          appID = pParams.responseUiParams.appID, systemContext = "MAIN"
        })
      end
     common.runAfter(uiResponse, 1000)
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(2)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, { putFileParams })

runner.Title("Test")
runner.Step("ScrollableMessage Positive Case", scrollableMessage, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
