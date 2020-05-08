---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item:
--
-- Description:
-- In case:
-- 1) RC app is subscribed to a RC module
-- 2) and then SDL received OnInteriorVehicleData notification for this module with invalid data
--    - invalid parameter name
--    - invalid parameter type
--    - missing mandatory parameter
-- SDL must:
-- 1) Does not re-send OnInteriorVehicleData notification to the related app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function invalidParamName(pModuleType)
  commonRC.getHMIConnection():SendNotification("RC.OnInteriorVehicleData", {
    modduleData = commonRC.getAnotherModuleControlData(pModuleType) -- invalid name of parameter
  })

  commonRC.getMobileSession():ExpectNotification("OnInteriorVehicleData"):Times(0)
end

local function invalidParamType(pModuleType)
  local moduleData = commonRC.getAnotherModuleControlData(pModuleType)
  moduleData.moduleType = {} -- invalid type of parameter

  commonRC.getHMIConnection():SendNotification("RC.OnInteriorVehicleData", {
    moduleData = moduleData
  })

  commonRC.getMobileSession():ExpectNotification("OnInteriorVehicleData"):Times(0)
end

local function missingMandatoryParam(pModuleType)
  local moduleData = commonRC.getAnotherModuleControlData(pModuleType)
  moduleData.moduleType = nil -- mandatory parameter missing

  commonRC.getHMIConnection():SendNotification("RC.OnInteriorVehicleData", {
    moduleData = moduleData
  })

  commonRC.getMobileSession():ExpectNotification("OnInteriorVehicleData"):Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)
runner.Step("Subscribe app to SEAT", commonRC.subscribeToModule, { "SEAT" })
runner.Step("Send notification OnInteriorVehicleData SEAT. App is subscribed", commonRC.isSubscribed, { "SEAT" })

runner.Title("Test")
runner.Step("OnInteriorVehicleData SEAT invalid name of parameter", invalidParamName, { "SEAT" })
runner.Step("OnInteriorVehicleData SEAT invalid type of parameter", invalidParamType, { "SEAT" })
runner.Step("OnInteriorVehicleData SEAT mandatory parameter missing", missingMandatoryParam, { "SEAT" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
