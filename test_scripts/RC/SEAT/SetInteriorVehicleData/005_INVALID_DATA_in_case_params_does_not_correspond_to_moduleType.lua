---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md 
-- User story: 
-- Use case: 
-- Item
--
-- Description:
-- In case:
-- 1) In case: The application is registered and sends a request contains moduleType_Seat and  ControlData for other moduleType 
-- (with "seatControlData" and RADIO moduleType) OR (with "radioControlData" and SEAT moduleType)                          --Changed
-- SDL must:
-- 1) Returns INVALID_DATA and doesn't transfer the request to HMI                                                               --Changed
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function setVehicleData(pModuleType)
  local mobSession = commonRC.getMobileSession()
  local moduleType2 = nil
  if pModuleType == "SEAT" then 
    moduleType2 = "RADIO"
  elseif pModuleType == "RADIO" then 
    moduleType2 = "SEAT"
  end

  local moduleData = commonRC.getSettableModuleControlData(moduleType2)
  moduleData.moduleType = pModuleType

	local cid = mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = moduleData
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData")
	:Times(0)

	mobileSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })

	commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

runner.Step("SetInteriorVehicleData SEAT_gets_INVALID_DATA", setVehicleData, { "SEAT" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)