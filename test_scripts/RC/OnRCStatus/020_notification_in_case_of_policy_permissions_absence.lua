---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall not send OnRCStatus notifications to rc registered app
-- in case application has not permissions for OnRCStatus
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
local function PTUfunc(tbl)
  local appId = config.application1.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId] = commonOnRCStatus.getRCAppConfig()
  local HMILevels = { "NONE", "BACKGROUND", "FULL", "LIMITED" }
  local RCgroup = {
    rpcs = {
      ButtonPress = { hmi_levels = HMILevels },
      GetInteriorVehicleData = { hmi_levels = HMILevels },
      SetInteriorVehicleData = { hmi_levels = HMILevels },
      OnInteriorVehicleData = { hmi_levels = HMILevels },
      SystemRequest = { hmi_levels = HMILevels }
    }
  }
  tbl.policy_table.functional_groupings.NewTestCaseGroup1 = RCgroup
  tbl.policy_table.app_policies[appId].groups = { "Base-4", "NewTestCaseGroup1" }
end

local function AlocateModule(pModuleType)
  local ModulesStatus = commonOnRCStatus.SetModuleStatus(freeModules, allocatedModules, pModuleType)
  commonOnRCStatus.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  ModulesStatus.appID = commonOnRCStatus.getHMIAppId()
  EXPECT_HMINOTIFICATION("RC.OnRCStatus", ModulesStatus)
end

local function RegisterApp()
  commonOnRCStatus.rai_ptu_n(PTUfunc)
  commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  local ModulesStatus = {
	appID = commonOnRCStatus.getHMIAppId(),
	  freeModules = commonOnRCStatus.ModulesArray(freeModules),
	  allocatedModules = commonOnRCStatus.ModulesArray(allocatedModules)
  }
  EXPECT_HMINOTIFICATION("RC.OnRCStatus", ModulesStatus)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonOnRCStatus.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonOnRCStatus.start)

runner.Title("Test")
runner.Step("RAI, PTU", RegisterApp)
runner.Step("Activate App", commonOnRCStatus.ActivateApp)
runner.Step("Allocation of module CLIMATE", AlocateModule, { "CLIMATE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonOnRCStatus.postconditions)
