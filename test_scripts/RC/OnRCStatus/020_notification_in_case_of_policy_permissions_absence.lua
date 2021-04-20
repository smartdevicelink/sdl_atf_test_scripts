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
-- 2) App has not permissions for OnRCStatus
-- 3) App allocates module
-- SDL must:
-- 1) Not send OnRCStatus notifications to app and the HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function PTUfunc(tbl)
  local appId = config.application1.registerAppInterfaceParams.fullAppID
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
  local pModuleStatus = common.setModuleStatus(pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  common.validateOnRCStatusForHMI(1, pModuleStatus)
end

local function registerApp()
  common.registerApp()
  common.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  EXPECT_HMICALL("RC.OnRCStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, { true, 0 })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register RC application", registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Allocation of module CLIMATE", alocateModule, { "CLIMATE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
