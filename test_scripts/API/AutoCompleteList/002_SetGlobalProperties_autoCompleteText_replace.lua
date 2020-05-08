---------------------------------------------------------------------------------------------------
-- User story: AutoCompleteList
-- Use case: SetGlobalProperties
-- Item: Deprecated parameter path
--
-- Requirement summary:
-- [SetGlobalProperties] SUCCESS on UI.SetGlobalProperties
--
-- Description:
-- In case mobile application sends valid SetGlobalProperties_request with "autoCompleteText" and 
-- no "autoCompleteList", SDL must transfer from mobile app to HMI the UI.SetGlobalProperties request,
-- including "autoCompleteList" with only one element (the received "autoCompleteText"). On getting 
-- "SUCCESS" result code, SDL must transfer "resutCode:SUCCESS", success:"true" to mobile application.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in BACKGROUND, LIMITED, or FULL HMI level

-- Steps:
-- appID requests SetGlobalproperties with autoCompleteText

-- Expected:

-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if SetGlobalProperties is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI request with generated autoCompleteList to HMI
-- SDL receives UI response from HMI with "SUCCESS" result code
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/AutoCompleteList/commonAutoCompleteList')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  keyboardProperties = {
    autoCompleteText = "Suggested entry"
  }
}

local requestUiParams = {
  keyboardProperties = {
  	autoCompleteList = { requestParams.keyboardProperties.autoCompleteText }
  }
}

local allParams = {
  requestParams = requestParams,
  requestUiParams = requestUiParams
}

--[[ Local Functions ]]
local function setGlobalProperties(params)
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC("SetGlobalProperties", params.requestParams)

  params.requestUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("UI.SetGlobalProperties", params.requestUiParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  EXPECT_HMICALL("TTS.SetGlobalProperties", {}):Times(0)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  mobileSession:ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetGlobalProperties", setGlobalProperties, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
