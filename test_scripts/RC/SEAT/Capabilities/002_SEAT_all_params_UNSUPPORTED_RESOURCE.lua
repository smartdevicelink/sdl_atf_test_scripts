---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item:
--
-- Description:
-- In case:
-- 1) SDL does not get RC capabilities for SEAT module through RC.GetCapabilities
-- SDL must:
-- 1) Response with success = false and resultCode = UNSUPPORTED_RESOURCE on all valid RPC with module SEAT
-- 2) Does not send RPC request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI (HMI has not SEAT RC capabilities), connect Mobile, start Session", commonRC.start,
	{commonRC.buildHmiRcCapabilities(commonRC.DEFAULT, commonRC.DEFAULT, nil, commonRC.DEFAULT)})
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App1", commonRC.activate_app)

runner.Title("Test")
runner.Step("GetInteriorVehicleData SEAT(UNSUPPORTED_RESOURCE)", commonRC.rpcDenied,
			{ "SEAT", 1, "GetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })
runner.Step("SetInteriorVehicleData SEAT(UNSUPPORTED_RESOURCE)", commonRC.rpcDenied,
			{ "SEAT", 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
