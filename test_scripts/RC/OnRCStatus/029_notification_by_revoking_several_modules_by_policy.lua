---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC app is registered
-- 2) App allocates module CLIMATE, RADIO
-- 3) PTU for app is performed with revoking of allocated modules
-- SDL must:
-- 1) send OnRCStatus notifications to mobile app and to the HMI with all modules in freeModules by PTU with revoking of allocated modules
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')
local json = require('modules/json')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Variables ]]
local freeModules = common.getAllModules()
local allocatedModules = {
  [1] = { }
}

--[[ Local Functions ]]
local function pTUfunc(tbl)
  local appId1 = config.application1.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId1] = common.getRCAppConfig(tbl)
  tbl.policy_table.app_policies[appId1].moduleType = json.EMPTY_ARRAY
  local appId2 = config.application2.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId2] = common.getRCAppConfig(tbl)
end

local function alocateModule(pModuleType)
  local pModuleStatus = common.setModuleStatus(freeModules, allocatedModules, pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.validateOnRCStatusForApp(1, pModuleStatus)
  common.validateOnRCStatusForHMI(1, { pModuleStatus })
end

local function registrationAppWithRevokingModule()
  common.raiPTU_n(pTUfunc, 2)
  local pModuleStatus = {
    freeModules = common.getModulesArray(common.getAllModules()),
    allocatedModules = { }
  }
  common.validateOnRCStatusForApp(1, pModuleStatus)
  common.validateOnRCStatusForHMI(1, { pModuleStatus })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, { 1 })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application 1", common.registerRCApplication)
runner.Step("Activate App 1", common.activateApp)
runner.Step("Allocating module CLIMATE", alocateModule, { "CLIMATE" })
runner.Step("Allocating module RADIO", alocateModule, { "RADIO" })

runner.Title("Test")
runner.Step("OnRCStatus by PTU with revoking of allocated module", registrationAppWithRevokingModule)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
