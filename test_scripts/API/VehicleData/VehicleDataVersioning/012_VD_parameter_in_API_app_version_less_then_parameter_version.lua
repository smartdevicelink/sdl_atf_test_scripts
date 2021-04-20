---------------------------------------------------------------------------------------------------
-- Description: The app is NOT able to retrieve the parameter in case app version is less then parameter version,
--  parameter is listed in API

-- In case:
-- 1. App is registered with syncMsgVersion=5.0
-- 2. Parameter has since=5.1 in API
-- 3. App requests GetVehicleData(<Parameter>)
-- SDL does:
--   a. reject the request as empty one
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/VehicleDataVersioning/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
-- cloudAppVehicleID has since="5.1" in API
local vehicleDataName = "cloudAppVehicleID"

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
      since = "5.0.0"
    }
  }
  pTbl.policy_table.functional_groupings.NewTestCaseGroup = common.cloneTable(pTbl.policy_table.functional_groupings["Emergency-1"])
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.GetVehicleData.parameters = { vehicleDataName }
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
