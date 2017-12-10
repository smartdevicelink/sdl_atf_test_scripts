---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: AddSubMenu
-- Item: Happy path
--
-- Requirement summary:
-- [AddSubMenu] SUCCESS: getting SUCCESS:UI.AddSubMenu()
--
-- Description:
-- Mobile application sends valid AddSubMenu request and gets UI.AddSubMenu "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests AddSubMenu with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if AddSubMenu is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Variables ]]
local requestParams = {
	menuID = 1000,
	position = 500,
	menuName ="SubMenupositive"
}

local responseUiParams = {
	menuID = requestParams.menuID,
	menuParams = {
		position = requestParams.position,
		menuName = requestParams.menuName
	}
}

local allParams = {
	requestParams = requestParams,
	responseUiParams = responseUiParams
}

--[[ Local Functions ]]
local function addSubMenu(params, self)
	local cid = self.mobileSession1:SendRPC("AddSubMenu", params.requestParams)

	params.responseUiParams.appID = commonSmoke.getHMIAppId()
	EXPECT_HMICALL("UI.AddSubMenu", params.responseUiParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	self.mobileSession1:ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("AddSubMenu Positive Case", addSubMenu, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
