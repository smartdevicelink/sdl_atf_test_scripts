---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item:
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) SDL receive several supported Radio parameters in GetCapabilites response and
-- 2) App sends RC RPC request with several supported by HMI parameters and some unssuported
-- SDL must:
-- 1) Reject such request with UNSUPPORTED_RESOURCE result code, success: false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local seat_capabilities = {{moduleName = "Seat", horizontalPositionAvailable = true, verticalPositionAvailable = false}}
local rc_capabilities = commonRC.buildHmiRcCapabilities(commonRC.DEFAULT, commonRC.DEFAULT, seat_capabilities, commonRC.DEFAULT)
local seat_params = {
  moduleType = "SEAT",
  seatControlData = {
    id = "DRIVER",
    horizontalPosition = 72,
    verticalPosition = 83
  }
}

--[[ Local Functions ]]
local function setVehicleData(params, self)
	local cid = self.mobileSession1:SendRPC("SetInteriorVehicleData", {moduleData = params})
	EXPECT_HMICALL("RC.SetInteriorVehicleData"):Times(0)
	self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, {rc_capabilities})
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate_App", commonRC.activate_app)

runner.Title("Test")
runner.Step("SetInteriorVehicleData rejected if at least one prameter unsuported", setVehicleData, { seat_params })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
