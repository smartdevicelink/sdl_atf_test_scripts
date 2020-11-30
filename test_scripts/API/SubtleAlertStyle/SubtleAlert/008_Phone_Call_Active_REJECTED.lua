---------------------------------------------------------------------------------------------------
-- User story: SubtleAlert cases
-- Use case: SubtleAlert
-- Item: SubtleAlert rejected during phone call
--
-- Requirement summary:
-- [SubtleAlert] REJECTED: request with UI portion rejected during higher priority event
--
-- Description:
-- Mobile application sends valid SubtleAlert request with UI-related-params and gets REJECTED 
-- resultCode due to phone call

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Full or Limited HMI level
-- d. Phone call is active in HMI

-- Steps:
-- appID requests SubtleAlert with UI-related-params

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if SubtleAlert is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI.SubtleAlert part of request with allowed parameters to HMI
-- SDL receives UI.SubtleAlert part of response from HMI with "REJECTED" result code
-- SDL responds with (resultCode: REJECTED, success:false) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SubtleAlertStyle/commonSubtleAlert')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local putFileParams = {
  syncFileName = "icon.png",
  fileType = "GRAPHIC_PNG",
  persistentFile = false,
  systemFile = false
}

local iconFilePath = "files/icon.png"

local requestParams = {
	alertText1 = "alertText1",
	alertText2 = "alertText2",
	alertIcon = {
		value = "icon.png",
		imageType = "DYNAMIC"
	}
}

local uiRequestParams = {
  alertStrings = {
    {
      fieldName = "subtleAlertText1",
      fieldText = requestParams.alertText1
    },
    {
      fieldName = "subtleAlertText2",
      fieldText = requestParams.alertText2
    }
  },
  alertType = "UI",
  alertIcon = requestParams.alertIcon,
  duration = 5000
}

local allParams = {
  requestParams = requestParams,
  uiRequestParams = uiRequestParams
}

--[[ Local Functions ]]
local function prepareParams(pParams)
  local params = common.cloneTable(pParams)
  params.uiRequestParams.appID = common.getHMIAppId()
  params.uiRequestParams.alertIcon.value =
    common.getPathToFileInAppStorage(putFileParams.syncFileName)

  return params
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, { { requestParams = putFileParams, filePath = iconFilePath } })

runner.Title("Test")
runner.Step("SubtleAlert during phone call, REJECTED result", common.subtleAlertRejectedPhoneCall, { allParams, prepareParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
