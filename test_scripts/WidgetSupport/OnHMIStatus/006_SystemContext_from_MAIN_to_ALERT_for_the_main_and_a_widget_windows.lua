---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that app received two "OnHMIStatus" notifications with modified "systemContext" from "MAIN"
--  to "ALERT" when an app and widget have "FULL" levels
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated
-- 4) App creates a widget and it has NONE level
-- 5) Widget is activated on the HMI and has FULL level
-- Step:
-- 1) App sends Alert RPC
-- SDL does:
--  - send OnHMIStatus notification for the main and widget window with ALERT value for a systemContext param to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 2,
  windowName = "Name",
  type = "WIDGET"
}

--[[ Local Functions ]]
local function sendOnSystemContext(ctx, pWindowId, pAppId)
  if not pWindowId then pWindowId = 0 end
  if not pAppId then pAppId = 1 end
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
  {
    appID = common.getHMIAppId(pAppId),
    systemContext = ctx,
    windowID = pWindowId
  })
end

local function alert(pAppId)
  if not pAppId then pAppId = 1 end
  local pMainId = 0
  local paramsAlert = {
    ttsChunks = {
      { type = "TEXT",
        text = "pathToFile"
      }
    },
    alertText1 = "alertText1",
    progressIndicator = true,
    duration = 5000
  }
  local responseDelay = 3000
  local cid = common.getMobileSession(pAppId):SendRPC("Alert", paramsAlert)

  common.getHMIConnection():ExpectRequest("UI.Alert", {
    alertStrings = {
      { fieldName = "alertText1",
        fieldText = "alertText1"
      }
    },
    duration = 5000,
    alertType = "BOTH",
    appID = common.getHMIAppId(pAppId)
  })
  :Do(function(_,data)
    sendOnSystemContext("ALERT", pMainId)
    sendOnSystemContext("ALERT", params.windowID)

		local function alertResponse()
			common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      sendOnSystemContext("MAIN", pMainId)
      sendOnSystemContext("MAIN", params.windowID)
		end

		RUN_AFTER(alertResponse, responseDelay)
  end)

  common.getHMIConnection():ExpectRequest("TTS.Speak", {
    ttsChunks = paramsAlert.ttsChunks,
    speakType = "ALERT",
    appID = common.getHMIAppId(pAppId)
  })
  :Do(function(_, data)
    local function speakResponse()
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end
    RUN_AFTER(speakResponse, 2000)
  end)

  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
  { systemContext = "ALERT", hmiLevel = "FULL", windowID = pMainId },
  { systemContext = "ALERT", hmiLevel = "FULL", windowID = params.windowID },
  { systemContext = "MAIN", hmiLevel = "FULL",windowID = pMainId },
  { systemContext = "MAIN", hmiLevel = "FULL", windowID = params.windowID })
  :Times(4)

  common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("App create a widget", common.createWindow, { params })
common.Step("Widget is activated in the HMI", common.activateWidgetFromNoneToFULL, { params.windowID })

common.Title("Test")
common.Step("Successfully processing Alert RPC", alert)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
