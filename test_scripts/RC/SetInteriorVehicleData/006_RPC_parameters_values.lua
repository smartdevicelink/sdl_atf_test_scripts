---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) RC app sends SetInteriorVehicleData request with invalid parameters
--    - invalid parameter name
--    - invalid parameter type
--    - missing mandatory parameter
-- SDL must:
-- 1) Do not transfer request to HMI
-- 2) Respond with success:false, "INVALID_DATA"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function invalidParamName(pModuleType, self)
  local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
    moduleDData = commonRC.getSettableModuleControlData(pModuleType) -- invalid name of parameter
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {})
  :Times(0)

  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function invalidParamType(pModuleType, self)
  local moduleData = commonRC.getSettableModuleControlData(pModuleType)
  moduleData.moduleType = {} -- invalid type of parameter

  local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
    modduleData = moduleData
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {})
  :Times(0)

  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function missingMandatoryParam(pModuleType, self)
  local moduleData = commonRC.getSettableModuleControlData(pModuleType)
  moduleData.moduleType = nil -- mandatory parameter missing

  local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
    modduleData = moduleData
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {})
  :Times(0)

  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function fakeParam(pModuleType, self)
	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = commonRC.getSettableModuleControlData(pModuleType),
    fakeParam = 6
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = self.applications["Test Application"],
		moduleData = commonRC.getSettableModuleControlData(pModuleType)
	})
	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = commonRC.getSettableModuleControlData(pModuleType)
			})
		end)

	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("SetInteriorVehicleData " .. mod .. " invalid name of parameter", invalidParamName, { mod })
  runner.Step("SetInteriorVehicleData " .. mod .. " invalid type of parameter", invalidParamType, { mod })
  runner.Step("SetInteriorVehicleData " .. mod .. " fake parameter", fakeParam, { mod })
  runner.Step("SetInteriorVehicleData " .. mod .. " missing mandatory parameter", missingMandatoryParam, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
