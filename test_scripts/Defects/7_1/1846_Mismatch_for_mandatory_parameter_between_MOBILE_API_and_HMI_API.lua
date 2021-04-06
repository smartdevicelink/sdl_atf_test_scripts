---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1846
--
-- Description:
-- Mismatch for mandatory parameter between MOBILE_API and HMI_API
--
-- Preconditions:
-- 1) Clear environment
-- 2) SDL started, HMI and mobile session connected
-- 3) Registered and activated app
-- 4) PTU
--
-- Steps:
-- 1) send mobile RPC "ShowConstantTBT" without "distanceToManeuver" param
--    and recieve resultCode = "INVALID_DATA"
-- 2) send mobile RPC "ShowConstantTBT" without "distanceToManeuverScale" param
--    and recieve resultCode = "INVALID_DATA"
-- 3) send mobile RPC "ShowConstantTBT" with "distanceToManeuver" and
--    "distanceToManeuverScale" params and recieve resultCode = "SUCCESS"
--
-- Expected:
-- Params "distanceToManeuver" and "distanceToManeuverScale" of the mobile RPC "ShowConstantTBT"
-- should be mandatory
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local params = {
  distanceToManeuver = 50.1,
  distanceToManeuverScale = 100.2
}

--[[ Local Functions ]]
local function ptuFunc(tbl)
	tbl.policy_table.app_policies["0000001"].groups = {"Base-4", "Navigation-1"}
end

local function checkShowConstantTBTPositive(pParams)
	local cid = common.getMobileSession():SendRPC("ShowConstantTBT", pParams)

	common.getHMIConnection():ExpectRequest("Navigation.ShowConstantTBT", pParams)
	:Do(function(_, data)
			common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
		end)

	common.getMobileSession():ExpectResponse(cid, {
		success = true,
		resultCode = "SUCCESS"
	})
end

local function checkShowConstantTBTNegative(pParams)
	local cid = common.getMobileSession():SendRPC("ShowConstantTBT", pParams)

	common.getHMIConnection():ExpectRequest("Navigation.ShowConstantTBT", pParams)
	:Times(0)

	common.getMobileSession():ExpectResponse(cid, {
		success = false,
		resultCode = "INVALID_DATA"
	})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("PTU", common.policyTableUpdate, { ptuFunc })

runner.Title("Test")
runner.Step("Negative check mandatory parameter distanceToManeuver", checkShowConstantTBTNegative, {{
		distanceToManeuverScale = params.distanceToManeuverScale
	}})
runner.Step("Negative check mandatory parameter distanceToManeuverScale", checkShowConstantTBTNegative, {{
		distanceToManeuver = params.distanceToManeuver
	}})
runner.Step("Positive case for ShowConstantTBT", checkShowConstantTBTPositive, {params})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
