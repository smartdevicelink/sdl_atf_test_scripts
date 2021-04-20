---------------------------------------------------------------------------------------------------
-- Description: The app is able to retrieve the parameter in case app version is more then parameter version,
--  parameter is listed in DB, version of parameter is more then version of the API

-- In case:
-- 1. App is registered with syncMsgVersion=8.0
-- 2. Parameter has since=7.0 DB
-- 3. App requests GetVehicleData(<Parameter>)
-- SDL does:
--   a. process the request successful
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/VehicleDataVersioning/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 8
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0
config.ValidateSchema = false

--[[ Local Functions ]]
local function ptuFunc(pTbl)
  pTbl.policy_table.vehicle_data = {}
  pTbl.policy_table.vehicle_data.schema_version = "00.00.01"
  pTbl.policy_table.vehicle_data.schema_items = {
    {
      name = "custom_vd_item1_integer",
      type = "Integer",
      key = "OEM_REF_INT",
      array = false,
      mandatory = false,
      minvalue = 0,
      maxvalue = 100,
      since = "7.0.0"
    }
  }
  pTbl.policy_table.functional_groupings.NewTestCaseGroup = common.cloneTable(pTbl.policy_table.functional_groupings["Emergency-1"])
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.GetVehicleData.parameters = { "custom_vd_item1_integer" }
  pTbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID].groups = { "Base-4", "NewTestCaseGroup" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { ptuFunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC GetVehicleData", common.processGetVDwithCustomDataSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
