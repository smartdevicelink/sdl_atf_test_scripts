---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item
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

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function invalidParamName(pModuleType)
  local mobileSession = commonRC.getMobileSession()
  local cid = mobileSession:SendRPC("SetInteriorVehicleData", {
    moduleDData = commonRC.getSettableModuleControlData(pModuleType) -- invalid name of parameter
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {}):Times(0)
  mobileSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function invalidParamType(pModuleType)
  local mobileSession = commonRC.getMobileSession()
  local moduleData = commonRC.getSettableModuleControlData(pModuleType)
  moduleData.moduleType = {} -- invalid type of parameter
  local cid = mobileSession:SendRPC("SetInteriorVehicleData", {
    modduleData = moduleData
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {}):Times(0)
  mobileSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function missingMandatoryParam(pModuleType)
  local mobileSession = commonRC.getMobileSession()
  local moduleData = commonRC.getSettableModuleControlData(pModuleType)
  moduleData.moduleType = nil -- mandatory parameter missing
  local cid = mobileSession:SendRPC("SetInteriorVehicleData", {
    modduleData = moduleData
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {}):Times(0)
  mobileSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function fakeParam(pModuleType)
  local mobileSession = commonRC.getMobileSession()
	local cid = mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = commonRC.getSettableModuleControlData(pModuleType),
    fakeParam = false
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = commonRC.getHMIAppId(),
		moduleData = commonRC.getSettableModuleControlData(pModuleType)
	})
	:Do(function(_, data)
			commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = commonRC.getSettableModuleControlData(pModuleType)
			})
		end)
	mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("SetInteriorVehicleData SEAT invalid name of parameter", invalidParamName, { "SEAT" })
runner.Step("SetInteriorVehicleData SEAT invalid type of parameter", invalidParamType, { "SEAT" })
runner.Step("SetInteriorVehicleData SEAT fake parameter", fakeParam, { "SEAT" })
runner.Step("SetInteriorVehicleData SEAT missing mandatory parameter", missingMandatoryParam, { "SEAT" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
