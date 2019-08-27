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
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local capParams = {}
capParams.CLIMATE = commonRC.DEFAULT
capParams.RADIO = commonRC.DEFAULT
capParams.BUTTONS = commonRC.DEFAULT
capParams.SEAT = commonRC.DEFAULT
local hmiRcCapabilities = commonRC.buildHmiRcCapabilities(capParams)

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Update HMI capabilities file", commonRC.updateDefaultCapabilities, { { "SEAT" }, true })
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI (HMI has all posible RC capabilities), connect Mobile, start Session", commonRC.start,
  { hmiRcCapabilities })
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App1", commonRC.activateApp)

runner.Title("Test")

runner.Step("GetInteriorVehicleData SEAT", commonRC.subscribeToModule, { "SEAT", 1 })
runner.Step("SetInteriorVehicleData SEAT", commonRC.rpcAllowed, { "SEAT", 1, "SetInteriorVehicleData" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
