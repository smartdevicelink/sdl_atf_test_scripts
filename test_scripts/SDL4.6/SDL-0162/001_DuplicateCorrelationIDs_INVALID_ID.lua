---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0162-define-handling-of-duplicate-correlation-ids.md
--
-- Description:
-- SDL Core should reject any messages with the same correlation ID as a pending request while 
-- still managing the original valid message.
--
-- Preconditions: Register and activate app
--
-- Steps:
--   1. Send an Mobile RPC to Core which has a corresponding HMI RPC
--   2. Send another Mobile RPC with the same correlation ID before a response is received from the
--      HMI for the original message
--
-- Expected result: 
-- SDL Core returns INVALID_ID for the second RPC
--
--   3. Send an HMI response to the first message
--
-- Expected result:
-- SDL Core returns SUCCESS for the original RPC
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local functionId = require('function_id')
local json = require('json')

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

local function addSubMenuWithoutResponse(self)
	cid = self.mobileSession1:SendRPC("AddSubMenu", requestParams)
	EXPECT_HMICALL("UI.AddSubMenu", hmiResponseParams)
	:Do(function(_, data)
		hmiRequestData = data
	end)
end

local function addSubMenuWithDuplicateCorrelationIDInvalidID(self)
	local msg = {
		serviceType = 7,
		frameInfo = 0,
		rpcType = 0,
		rpcFunctionId = functionId["AddSubMenu"],
		rpcCorrelationId = cid,
		payload = json.encode(requestParams2)
	}
	self.mobileSession1:Send(msg)
	self.mobileSession1:ExpectResponse(cid, {
		success = false,
		resultCode = "INVALID_ID"
	})
end

local function addSubMenuRespondToOriginal(self)
	self.hmiConnection:SendResponse(hmiRequestData.id, hmiRequestData.method, "SUCCESS", {})
	self.mobileSession1:ExpectResponse(cid, {
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
