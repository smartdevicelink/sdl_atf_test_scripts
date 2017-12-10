---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: DeleteSubMenu
-- Item: Happy path
--
-- Requirement summary:
-- [DeleteSubMenu] SUCCESS: getting SUCCESS:UI.DeleteSubMenu() and all related UI or/and VR.DeleteCommand()
--
-- Description:
-- Mobile application sends valid DeleteSubMenu request and gets UI.DeleteSubMenu "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level
-- d. SubMenu with related menuID was created

-- Steps:
-- appID requests DeleteSubMenu with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if DeleteSubMenu is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Variables ]]
local addSubMenuRequestParams = {
	menuID = 1000,
	position = 500,
	menuName ="SubMenupositive"
}

local addSubMenuResponseUiParams = {
	menuID = addSubMenuRequestParams.menuID,
	menuParams = {
		position = addSubMenuRequestParams.position,
		menuName = addSubMenuRequestParams.menuName
	}
}

local addSubMenuAllParams = {
	requestParams = addSubMenuRequestParams,
	responseUiParams = addSubMenuResponseUiParams
}

local deleteSubMenuRequestParams = {
	menuID = addSubMenuRequestParams.menuID
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

local function deleteSubMenu(params, self)
	local cid = self.mobileSession1:SendRPC("DeleteSubMenu", params)

	params.appID = commonSmoke.getHMIAppId()
	EXPECT_HMICALL("UI.DeleteSubMenu", params)
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
runner.Step("AddSubMenu", addSubMenu, {addSubMenuAllParams})

runner.Title("Test")
runner.Step("DeleteSubMenu Positive Case", deleteSubMenu, {deleteSubMenuRequestParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
