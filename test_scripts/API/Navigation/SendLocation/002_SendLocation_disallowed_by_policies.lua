---------------------------------------------------------------------------------------------
-- Requirements: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
--
-- Requirement summary:
-- 1. Request is valid, SendLocation RPC is not allowed by policies
-- 2. SDL responds DISALLOWED, success:false to request
--
-- Description:
-- App requests SendLocation in different HMI levels
--
-- Steps:
-- SDL receives SendLocation request in NONE, BACKGROUND, FULL, LIMITED
--
-- Expected:
-- SDL responds DISALLOWED, success:false in NONE level, SUCCESS, success:true in BACKGROUND, FULL, LIMITED levels
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
local requestParams = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1
}

--[[ Local Functions ]]
local function ptuUpdateFuncDissalowedRPC(tbl)
	local SendLocstionRpcs = tbl.policy_table.functional_groupings["SendLocation"].rpcs
	if SendLocstionRpcs["SendLocation"] then SendLocstionRpcs["SendLocation"] = nil end
end

--[[ Local Functions ]]
local function sendLocationDisallowed(params, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation")
    :Times(0)

    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
    commonSendLocation.delayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU, { "1", ptuUpdateFuncDissalowedRPC })
runner.Step("Activate App", commonSendLocation.activateApp)

runner.Title("Test")
runner.Step("SendLocation_rpc_disallowed", sendLocationDisallowed, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
