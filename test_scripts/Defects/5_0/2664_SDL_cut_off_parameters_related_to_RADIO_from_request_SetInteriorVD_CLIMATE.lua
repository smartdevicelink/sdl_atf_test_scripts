---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2664
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL transfer request to HMI without parameters related to RADIO in case
-- app sends SetInteriorVehicleData(CLIMATE) request
--
-- Precondition:
-- 1) SDL, HMI, Mobile session are started
-- 2) App is registered and activated
-- In case:
-- 1) RC app sends SetInteriorVehicleData(CLIMATE) request with parameters are related to RADIO module
-- SDL does:
--  - transfer request to HMI without data related to RADIO module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local moduleType = "CLIMATE"

--[[ Local Functions ]]
local function cutOffParamsForAnotherModule()
  local moduleData = commonRC.getSettableModuleControlData(moduleType)
  moduleData.climateControlData.frequencyInteger = 10 -- frequencyInteger parameter is related to RADIO module
  moduleData.radioControlData = { }
  moduleData.radioControlData.frequencyInteger = 10

  local cid = commonRC.getMobileSession():SendRPC("SetInteriorVehicleData", { moduleData = moduleData })
  commonRC.getHMIConnection():ExpectRequest("RC.SetInteriorVehicleData", {
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
        return false, "SDL transfers to HMI parameters not related to module"
      end
      return true
    end)

  commonRC.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("Register App", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("SetInteriorVehicleData with params for another module in moduleData", cutOffParamsForAnotherModule)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
