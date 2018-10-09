---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/3
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Exceptions: 2.1
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) RC app sends SetInteriorVehicleData(CLIMATE) request with parameters are related to RADIO module
-- SDL must: 
-- 1) Transfer request to HMI and cut the data related to RADIO module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function paramsForAnotherModule()
  local moduleType = "CLIMATE"
  local moduleData = commonRC.getSettableModuleControlData(moduleType)
  moduleData.climateControlData.frequencyInteger = 10
  moduleData.radioControlData = { }
  moduleData.radioControlData.frequencyInteger = 10
	local cid = commonRC.getMobileSession():SendRPC("SetInteriorVehicleData", {
		moduleData = moduleData
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = commonRC.getHMIAppId(),
		moduleData = commonRC.getSettableModuleControlData(moduleType)
	})
	:Do(function(_, data)
			commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = commonRC.getSettableModuleControlData(moduleType)
			})
		end)
  :ValidIf(function(_, data)
      if data.params.moduleData.climateControlData.frequencyInteger or data.params.moduleData.radioControlData then
        return false, "SDL resends to HMI the not related to module type parameters"
      end
      return true
    end)

	commonRC.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("SetInteriorVehicleData with params for another module in moduleData", paramsForAnotherModule)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
