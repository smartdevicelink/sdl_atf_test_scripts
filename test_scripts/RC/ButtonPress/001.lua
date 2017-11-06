---------------------------------------------------------------------------------------------------
-- RPC: ButtonPress
-- Script: 001
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Functions ]]
local function step1(self)
	local cid = self.mobileSession:SendRPC("ButtonPress",	{
		zone = commonRC.getInteriorZone(),
		moduleType = "CLIMATE",
		buttonName = "AC",
		buttonPressMode = "SHORT"
	})

	EXPECT_HMICALL("Buttons.ButtonPress",	{
		appID = self.applications["Test Application"],
		zone = commonRC.getInteriorZone(),
		moduleType = "CLIMATE",
		buttonName = "AC",
		buttonPressMode = "SHORT"
	})
	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

local function step2(self)
	local cid = self.mobileSession:SendRPC("ButtonPress",	{
		zone = commonRC.getInteriorZone(),
		moduleType = "RADIO",
		buttonName = "VOLUME_UP",
		buttonPressMode = "LONG"
	})

	EXPECT_HMICALL("Buttons.ButtonPress",	{
		appID = self.applications["Test Application"],
		zone = commonRC.getInteriorZone(),
		moduleType = "RADIO",
		buttonName = "VOLUME_UP",
		buttonPressMode = "LONG"
	})
	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("ButtonPress_CLIMATE", step1)
runner.Step("ButtonPress_RADIO", step2)
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
