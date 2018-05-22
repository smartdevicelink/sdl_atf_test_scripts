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
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local freeModules = common.getAllModules()
local allocatedModules = {{}}

--[[ Local Functions ]]
local function pTUfunc(tbl)
  local appId = config.application1.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId] = common.getRCAppConfig()
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

local function alocateModule(pModuleType)
  local pModuleStatus = common.setModuleStatus(freeModules, allocatedModules, pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  common.validateOnRCStatusForHMI(1, { pModuleStatus })
end

local function registerApp()
  common.raiPTU_n(pTUfunc, 1)
  common.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  local pModuleStatus = {
	  freeModules = common.getModulesArray(freeModules),
	  allocatedModules = common.getModulesArray(allocatedModules[1])
  }
  common.validateOnRCStatusForHMI(1, { pModuleStatus })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, { 0 })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register RC application", registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Allocation of module CLIMATE", alocateModule, { "CLIMATE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
