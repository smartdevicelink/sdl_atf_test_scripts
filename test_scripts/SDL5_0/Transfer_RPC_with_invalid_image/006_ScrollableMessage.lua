---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests ScrollableMessage with image that is absent on file system
-- SDL must:
-- 1. transfer this RPC to HMI for processing
-- 2. transfer the received from HMI response (WARNINGS, message: “Requested image(s) not found”) to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Transfer_RPC_with_invalid_image/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  scrollableMessageBody = "abc",
  softButtons = {
    {
      softButtonID = 1,
      text = "Button1",
      type = "BOTH",
      image = {
        value = "missed_icon.png",
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
local function ScrollableMessage(pParams)
  local cid = common.getMobileSession():SendRPC("ScrollableMessage", pParams.requestParams)
  pParams.responseUiParams.appID = common.getHMIAppId()
  for _, v in pairs(pParams.responseUiParams.softButtons) do
    if v.image then
      v.image.value = common.getPathToFileInStorage("missed_icon.png")
    end
  end
  EXPECT_HMICALL("UI.ScrollableMessage", pParams.responseUiParams)
  :Do(function(_,data)
	common.getHMIConnection():SendNotification("UI.OnSystemContext",
	  { appID = pParams.responseUiParams.appID, systemContext = "HMI_OBSCURED" })
	local function uiResponse()
      common.getHMIConnection():SendError(data.id, data.method, "WARNINGS", "Requested image(s) not found")
      common.getHMIConnection():SendNotification("UI.OnSystemContext",
        { appID = pParams.responseUiParams.appID, systemContext = "MAIN" })
    end
    RUN_AFTER(uiResponse, 1000)
  end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(2)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS",
    info = "Requested image(s) not found" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("ScrollableMessage with invalid image", ScrollableMessage, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
