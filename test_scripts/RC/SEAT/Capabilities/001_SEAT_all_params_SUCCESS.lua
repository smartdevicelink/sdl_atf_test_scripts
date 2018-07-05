---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item:
--
-- Description:
-- In case:
-- SDL gets all RC capabilities for SEAT modules through RC.GetCapabilities
-- SDL must:
-- Send RPC request to HMI and resend HMI answer to Mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Update HMI capabilities file", commonRC.updateDefaultCapabilities, { { "SEAT" } })
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI (HMI has all posible RC capabilities), connect Mobile, start Session", commonRC.start,
	{commonRC.buildHmiRcCapabilities(commonRC.DEFAULT, commonRC.DEFAULT, commonRC.DEFAULT, commonRC.DEFAULT)})
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App1", commonRC.activate_app)

runner.Title("Test")

runner.Step("GetInteriorVehicleData SEAT", commonRC.subscribeToModule, { "SEAT", 1 })
runner.Step("SetInteriorVehicleData SEAT", commonRC.rpcAllowed, { "SEAT", 1, "SetInteriorVehicleData" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
