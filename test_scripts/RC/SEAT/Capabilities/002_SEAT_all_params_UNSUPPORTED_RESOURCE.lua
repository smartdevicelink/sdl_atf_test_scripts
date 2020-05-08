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
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local capParams = {}
capParams.CLIMATE = commonRC.DEFAULT
capParams.RADIO = commonRC.DEFAULT
capParams.BUTTONS = commonRC.DEFAULT
capParams.SEAT = nil
local hmiRcCapabilities = commonRC.buildHmiRcCapabilities(capParams)

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI (HMI has not SEAT RC capabilities), connect Mobile, start Session", commonRC.start,
	{hmiRcCapabilities})
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App1", commonRC.activateApp)

runner.Title("Test")
runner.Step("GetInteriorVehicleData SEAT(UNSUPPORTED_RESOURCE)", commonRC.rpcDenied,
			{ "SEAT", 1, "GetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })
runner.Step("SetInteriorVehicleData SEAT(UNSUPPORTED_RESOURCE)", commonRC.rpcDenied,
			{ "SEAT", 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
