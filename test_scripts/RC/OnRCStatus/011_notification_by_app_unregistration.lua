---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall send OnRCStatus notifications to registered mobile application and to the HMI by
-- app unregistration with allocated module.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonOnRCStatus = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local freeModules =  commonFunctions:cloneTable(commonOnRCStatus.modules)
local allocatedModules = { }

local NotifParams = { freeModules = commonOnRCStatus.ModulesArray(commonOnRCStatus.modules), allocatedModules = { } }

--[[ Local Functions ]]
local function RegisterSeconApp()
	commonOnRCStatus.rai_n_rc_app(2)
	commonOnRCStatus.getMobileSession(2):ExpectNotification("OnRCStatus", NotifParams)
	commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus", NotifParams)
	EXPECT_HMINOTIFICATION("RC.OnRCStatus", NotifParams )
end

local function AlocateModule(pModuleType)
  local ModulesStatus = commonOnRCStatus.SetModuleStatus(freeModules, allocatedModules, pModuleType)
  commonOnRCStatus.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus", ModulesStatus)
  commonOnRCStatus.getMobileSession(2):ExpectNotification("OnRCStatus", ModulesStatus)
  ModulesStatus.appID = commonOnRCStatus.getHMIAppId()
  EXPECT_HMINOTIFICATION("RC.OnRCStatus", ModulesStatus)
end

local function Unregistration()
  commonOnRCStatus.unregisterApp()
  commonOnRCStatus.getMobileSession(2):ExpectNotification("OnRCStatus", NotifParams)
  commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus", NotifParams)
  :Times(0)
  EXPECT_HMINOTIFICATION("RC.OnRCStatus", NotifParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonOnRCStatus.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonOnRCStatus.start)
runner.Step("First app registration", commonOnRCStatus.RegisterRCapplication)
runner.Step("Second app registration", RegisterSeconApp)
runner.Step("Activate first app", commonOnRCStatus.ActivateApp)
runner.Step("Allocating module CLIMATE", AlocateModule, { "CLIMATE" })

runner.Title("Test")
runner.Step("OnRCStatus by app unregistration", Unregistration)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonOnRCStatus.postconditions)
