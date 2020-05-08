---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item:
--
-- Description:
-- In case:
-- 1) RC app sends valid and allowed by policies SetInteriorvehicleData request
-- 2) and SDL received SetInteriorVehicleData response with successful result code and current module data from HMI
-- SDL must:
-- 1) Transfer SetInteriorVehicleData response with provided from HMI current module data
-- for allowed module and control items
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local success_codes = { "WARNINGS" }
local error_codes = { "GENERIC_ERROR", "INVALID_DATA", "OUT_OF_MEMORY", "REJECTED" }

--[[ Local Functions ]]
local function stepSuccessfull(pModuleType, pResultCode)
  local mobileSession = commonRC.getMobileSession()
	local cid = mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = commonRC.getSettableModuleControlData(pModuleType)
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = commonRC.getHMIAppId(),
		moduleData = commonRC.getSettableModuleControlData(pModuleType)
	})
	:Do(function(_, data)
			commonRC.getHMIConnection():SendResponse(data.id, data.method, pResultCode, {
				moduleData = commonRC.getSettableModuleControlData(pModuleType)
			})
		end)

	mobileSession:ExpectResponse(cid,
    { success = true, resultCode = pResultCode, moduleData = commonRC.getSettableModuleControlData(pModuleType) })
end

local function stepUnsuccessfull(pModuleType, pResultCode)
  local mobileSession = commonRC.getMobileSession()
  local cid = mobileSession:SendRPC("SetInteriorVehicleData", {
    moduleData = commonRC.getSettableModuleControlData(pModuleType)
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {
    appID = commonRC.getHMIAppId(),
    moduleData = commonRC.getSettableModuleControlData(pModuleType)
  })
  :Do(function(_, data)
      commonRC.getHMIConnection():SendError(data.id, data.method, pResultCode, "Error error")
    end)

  mobileSession:ExpectResponse(cid, { success = false, resultCode = pResultCode })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
for _, code in pairs(success_codes) do
  runner.Step("SetInteriorVehicleData with SEAT resultCode", stepSuccessfull, { "SEAT", code })
end

for _, code in pairs(error_codes) do
  runner.Step("SetInteriorVehicleData with SEAT resultCode", stepUnsuccessfull, { "SEAT", code })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
