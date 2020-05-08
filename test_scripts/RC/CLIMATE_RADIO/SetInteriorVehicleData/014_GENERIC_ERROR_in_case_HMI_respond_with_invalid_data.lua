---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/3
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) RC app sends SetInteriorVehicleData request with valid parameters
-- 2) and HMI response is invalid
-- SDL must:
-- 1) Respond to App with success:false, "GENERIC_ERROR"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function invalidParamType(pModuleType)
  local cid = commonRC.getMobileSession():SendRPC("SetInteriorVehicleData", {
    moduleData = commonRC.getSettableModuleControlData(pModuleType)
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {
    appID = commonRC.getHMIAppId(),
    moduleData = commonRC.getSettableModuleControlData(pModuleType)
  })
  :Do(function(_, data)
      local modData = commonRC.getSettableModuleControlData(pModuleType)
      modData.moduleType = "MODULE" -- invalid value of parameter
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = modData,
        isSubscribed = "yes" -- fake parameter
      })
    end)

  commonRC.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

local function missingMandatoryParam(pModuleType)
  local cid = commonRC.getMobileSession():SendRPC("SetInteriorVehicleData", {
    moduleData = commonRC.getSettableModuleControlData(pModuleType)
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {
    appID = commonRC.getHMIAppId(),
    moduleData = commonRC.getSettableModuleControlData(pModuleType)
  })
  :Do(function(_, data)
      local moduleData = commonRC.getModuleControlData(pModuleType)
      moduleData.moduleType = nil -- missing mandatory parameter
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = moduleData
      })
    end)

  commonRC.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

for _, mod in pairs(commonRC.modules)  do
  runner.Step("SetInteriorVehicleData " .. mod .. " Invalid response from HMI-Invalid type of parameter", invalidParamType, { mod })
  runner.Step("SetInteriorVehicleData " .. mod .. " Invalid response from HMI-Missing mandatory parameter", missingMandatoryParam, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
