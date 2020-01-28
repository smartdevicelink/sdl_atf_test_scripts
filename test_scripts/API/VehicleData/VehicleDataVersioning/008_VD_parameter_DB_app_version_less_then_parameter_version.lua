---------------------------------------------------------------------------------------------------
-- Description: The app is NOT able to retrieve the parameter in case app version is less then parameter version,
--  parameter is listed in DB

-- In case:
-- 1. App is registered with syncMsgVersion=5.0
-- 2. Parameter has since=5.9 DB
-- 3. App requests GetVehicleData(<Parameter>)
-- SDL does:
--   a. reject the request as empty one
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0
config.ValidateSchema = false

--[[ Local Variables ]]
local vehicleDataName = "custom_vd_item1_integer"

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
      since = "5.9.0"
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
runner.Step("RPC GetVehicleData INVALID_DATA", common.processGetVDunsuccess, { vehicleDataName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
