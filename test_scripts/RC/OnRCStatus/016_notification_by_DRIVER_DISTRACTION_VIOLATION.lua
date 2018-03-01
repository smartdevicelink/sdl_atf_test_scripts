---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall send OnRCStatus notifications to rc registered app and to HMI
-- in case app deallocates module by performing DRIVER_DISTRACTION_VIOLATION form HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonOnRCStatus = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local freeModules =  commonFunctions:cloneTable(commonOnRCStatus.modules)
local allocatedModules = {}

--[[ Local Functions ]]
local function AlocateModule(pModuleType)
  local ModulesStatus = commonOnRCStatus.SetModuleStatus(freeModules, allocatedModules, pModuleType)
  commonOnRCStatus.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus", ModulesStatus)
  ModulesStatus.appID = commonOnRCStatus.getHMIAppId()
  EXPECT_HMINOTIFICATION("RC.OnRCStatus", ModulesStatus)
end

local function DriverDistractionViolation()
  local hmiAppId = commonOnRCStatus.getHMIAppId()
  commonOnRCStatus.getHMIconnection():SendNotification("BasicCommunication.OnExitApplication",
    {appID = hmiAppId, reason = "DRIVER_DISTRACTION_VIOLATION"})
  commonOnRCStatus.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  local ModulesStatus = { freeModules = commonOnRCStatus.ModulesArray(freeModules),
    allocatedModules = commonOnRCStatus.ModulesArray(allocatedModules) }
  commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus", ModulesStatus)
  ModulesStatus.appID = hmiAppId
  EXPECT_HMINOTIFICATION("RC.OnRCStatus", ModulesStatus)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonOnRCStatus.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonOnRCStatus.start)
runner.Step("RAI, PTU", commonOnRCStatus.RegisterRCapplication)
runner.Step("Activate App", commonOnRCStatus.ActivateApp)
runner.Step("App allocates module CLIMATE " , AlocateModule, { "CLIMATE" })

runner.Title("Test")
runner.Step("OnRCStatus notification by DRIVER_DISTRACTION_VIOLATION", DriverDistractionViolation)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonOnRCStatus.postconditions)
