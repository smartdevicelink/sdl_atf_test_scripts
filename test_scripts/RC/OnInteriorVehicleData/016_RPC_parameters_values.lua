---------------------------------------------------------------------------------------------------
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
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function invalidParamName(pModuleType, self)
  self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
    modduleData = commonRC.getAnotherModuleControlData(pModuleType) -- invalid name of parameter
  })

  EXPECT_NOTIFICATION("OnInteriorVehicleData")
  :Times(0)

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function invalidParamType(pModuleType, self)
  local moduleData = commonRC.getAnotherModuleControlData(pModuleType)
  moduleData.moduleType = {} -- invalid type of parameter

  self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
    moduleData = moduleData
  })

  EXPECT_NOTIFICATION("OnInteriorVehicleData")
  :Times(0)

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function missingMandatoryParam(pModuleType, self)
  local moduleData = commonRC.getAnotherModuleControlData(pModuleType)
  moduleData.moduleType = nil -- mandatory parameter missing

  self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
    moduleData = moduleData
  })

  EXPECT_NOTIFICATION("OnInteriorVehicleData")
  :Times(0)

  commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, commonRC.subscribeToModule, { mod, 1 })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is subscribed", commonRC.isSubscribed, { mod, 1 })
end

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("OnInteriorVehicleData " .. mod .. " invalid name of parameter", invalidParamName, { mod })
  runner.Step("OnInteriorVehicleData " .. mod .. " invalid type of parameter", invalidParamType, { mod })
  runner.Step("OnInteriorVehicleData " .. mod .. " mandatory parameter missing", missingMandatoryParam, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
