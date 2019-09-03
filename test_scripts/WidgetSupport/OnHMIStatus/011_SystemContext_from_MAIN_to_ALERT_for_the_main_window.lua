---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that "OnHMIStatus" notification with modified "systemContext" from "MAIN" to "ALERT" does not
-- send for a widget if it has "BACKGROUND" or "NONE" level
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated
-- 4) Widget_1 is created and activated on the HMI and has FULL level
-- 5) Widget_2 is created and has NONE level
-- 5) Widget_1 is deactivated in the HMI and has BACKGROUND level
-- Step:
-- 1) App sends Alert RPC
-- SDL does:
--  - send OnHMIStatus notification for the main window with ALERT value for a systemContext param to app
--  - not send OnHMIStatus notifications for widgets windows with ALERT value for a systemContext param to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  [1] = {
    windowID = 2, windowName = "Name1", type = "WIDGET"
  },
  [2] = {
    windowID = 3, windowName = "Name2", type = "WIDGET"
  }
}

--[[ Local Functions ]]
local function sendOnSystemContext(ctx)
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
  {
    appID = common.getHMIAppId(),
    systemContext = ctx,
    windowID = nil -- main window
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
  :Do(function(_, data)
    sendOnSystemContext("ALERT")

		local function alertResponse()
			common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      sendOnSystemContext("MAIN")
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
  { systemContext = "MAIN", hmiLevel = "FULL",windowID = pMainId })
  :Times(2)

  common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.wait(5000)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("App create the Widget_1", common.createWindow, { params[1] })
common.Step("App create the Widget_2", common.createWindow, { params[2] })
common.Step("Widget_1 is activated in the HMI", common.activateWidgetFromNoneToFULL, { params[1].windowID })
common.Step("Widget_1 is deactivated in the HMI", common.deactivateWidgetFromFullToBackground, { params[1].windowID })

common.Title("Test")
common.Step("Successfully processing Alert RPC for main window", alert)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
