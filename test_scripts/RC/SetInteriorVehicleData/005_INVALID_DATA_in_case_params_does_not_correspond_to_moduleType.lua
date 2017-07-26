---------------------------------------------------------------------------------------------------
-- Description #1
-- In case:
-- 1) Application registered with REMOTE_CONTROL AppHMIType and sends SetInteriorVehicleData RPC
-- 2) (with "climateControlData" and RADIO moduleType) OR (with "radioControlData" and CLIMATE moduleType)
-- SDL must:
-- 1) Respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle
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

  local moduleData = commonRC.getSettableModuleControlData(moduleType2)
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
