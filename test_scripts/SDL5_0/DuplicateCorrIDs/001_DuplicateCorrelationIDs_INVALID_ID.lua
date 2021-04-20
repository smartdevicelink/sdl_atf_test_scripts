---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0147-template-color-scheme.md
--
-- Description:
-- SDL Core should track the number of attempted SetDisplayLayout requests with the current template and REJECT
-- any beyond the first with the reason "Using SetDisplayLayout to change the color scheme may only be done once.
-- However, The color scheme can be changed if the layout is also changed.
--
-- Preconditions: Send SetDisplayLayout with a layout and a color scheme.
--
-- Steps: Send additional SetDisplayLayout with a different layout and a different color scheme.
--
-- Expected result:
-- SDL Core returns SUCCESS
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local functionId = require('function_id')
local json = require('json')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local hmiRequestData = {}
local cid = 0

local requestParams = {
	menuID = 100,
	menuName = "Menu1"
}

local requestParams2 = {
	menuID = 101,
	menuName = "Menu2"
}

local hmiResponseParams = {
	menuID = 100,
	menuParams = {
		menuName = "Menu1"
	}
}

local function addSubMenuWithoutResponse()
	cid = commonSmoke.getMobileSession():SendRPC("AddSubMenu", requestParams)
	EXPECT_HMICALL("UI.AddSubMenu", hmiResponseParams)
	:Do(function(_, data)
		hmiRequestData = data
	end)
end

local function addSubMenuWithDuplicateCorrelationIDInvalidID()
	local msg = {
		serviceType = 7,
		frameInfo = 0,
		rpcType = 0,
		rpcFunctionId = functionId["AddSubMenu"],
		rpcCorrelationId = cid,
		payload = json.encode(requestParams2)
	}
	commonSmoke.getMobileSession():Send(msg)
	commonSmoke.getMobileSession():ExpectResponse(cid, {
		success = false,
		resultCode = "INVALID_ID"
	})
end

local function addSubMenuRespondToOriginal()
	commonSmoke.getHMIConnection():SendResponse(hmiRequestData.id, hmiRequestData.method, "SUCCESS", {})
	commonSmoke.getMobileSession():ExpectResponse(cid, {
		success = true,
		resultCode = "SUCCESS"
	})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("Send AddSubMenu request with valid params", addSubMenuWithoutResponse)
runner.Step("Send AddSubMenu with Duplicate Correlation ID", addSubMenuWithDuplicateCorrelationIDInvalidID)
runner.Step("Send AddSubMenu response to original message", addSubMenuRespondToOriginal)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
