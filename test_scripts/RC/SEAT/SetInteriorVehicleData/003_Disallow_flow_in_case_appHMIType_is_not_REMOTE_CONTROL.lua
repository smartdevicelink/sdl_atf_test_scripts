---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item
--
-- Description:
-- In case:
-- 1) Non remote-control application is registered on SDL
-- 2) and SDL received SetInteriorVehicleData request from this App
-- SDL must:
-- 1) Disallow remote-control RPCs for this app (success:false, "DISALLOWED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function setVehicleData(pModuleType)
	local mobileSession = commonRC.getMobileSession()
	local cid = mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = commonRC.getSettableModuleControlData(pModuleType)
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData"):Times(0)
	mobileSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

local function ptu_update_func(tbl)
  local appId = config.application1.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId].AppHMIType = { "DEFAULT" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("SetInteriorVehicleData SEAT", setVehicleData, { "SEAT" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
