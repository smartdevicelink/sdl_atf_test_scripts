---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/5
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/unsubscribe_from_module_status_change_notification.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Subscribe on RC module change notification
-- [SDL_RC] Unsubscribe from RC module change notifications
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

  commonRC.getMobileSession():ExpectNotification("OnInteriorVehicleData")
  :Times(0)
  commonRC.wait(commonRC.timeout)
end

local function invalidParamType(pModuleType)
  local moduleData = commonRC.getAnotherModuleControlData(pModuleType)
  moduleData.moduleType = {} -- invalid type of parameter

  commonRC.getHMIConnection():SendNotification("RC.OnInteriorVehicleData", {
    moduleData = moduleData
  })

  commonRC.getMobileSession():ExpectNotification("OnInteriorVehicleData")
  :Times(0)
  commonRC.wait(commonRC.timeout)
end

local function missingMandatoryParam(pModuleType)
  local moduleData = commonRC.getAnotherModuleControlData(pModuleType)
  moduleData.moduleType = nil -- mandatory parameter missing

  commonRC.getHMIConnection():SendNotification("RC.OnInteriorVehicleData", {
    moduleData = moduleData
  })

  commonRC.getMobileSession():ExpectNotification("OnInteriorVehicleData")
  :Times(0)
  commonRC.wait(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

for _, mod in pairs(commonRC.modules)  do
  runner.Step("Subscribe app to " .. mod, commonRC.subscribeToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is subscribed", commonRC.isSubscribed, { mod })
end

runner.Title("Test")

for _, mod in pairs(commonRC.modules)  do
  runner.Step("OnInteriorVehicleData " .. mod .. " invalid name of parameter", invalidParamName, { mod })
  runner.Step("OnInteriorVehicleData " .. mod .. " invalid type of parameter", invalidParamType, { mod })
  runner.Step("OnInteriorVehicleData " .. mod .. " mandatory parameter missing", missingMandatoryParam, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
