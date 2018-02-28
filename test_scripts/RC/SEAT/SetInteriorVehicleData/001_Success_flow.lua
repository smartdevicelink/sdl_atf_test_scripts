---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item
--
-- Description:
-- In case:
-- 1) Application is registered with REMOTE_CONTROL appHMIType
-- 2) and sends valid SetInteriorVehicleData RPC with valid parameters
-- SDL must:
-- 1) Transfer this request to HMI
-- 2) Respond with <result_code> received from HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function setVehicleData(pModuleType)
	local mobileSession = commonRC.getMobileSession()
	local cid = mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = commonRC.getSettableModuleControlData(pModuleType)
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = commonRC.getHMIAppId,
		moduleData = commonRC.getSettableModuleControlData(pModuleType)
	})
	:Do(function(_, data)
			commonRC.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = commonRC.getSettableModuleControlData(pModuleType)
			})
		end)

	mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("SetInteriorVehicleData SEAT", setVehicleData, { "SEAT" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
