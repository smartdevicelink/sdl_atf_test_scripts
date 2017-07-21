---------------------------------------------------------------------------------------------------
-- RPC: SetInteriorVehicleData
-- Script: 004
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function setVehicleData(pModuleType, self)
  local moduleType2 = nil
  if pModuleType == "CLIMATE" then
    moduleType2 = "RADIO"
  elseif pModuleType == "RADIO" then
    moduleType2 = "CLIMATE"
  end

  local moduleData = commonRC.getModuleControlData(moduleType2)
  moduleData.moduleType = pModuleType

	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = moduleData
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData")
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

	commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("SetInteriorVehicleData " .. mod .. "_gets_INVALID_DATA", setVehicleData, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
