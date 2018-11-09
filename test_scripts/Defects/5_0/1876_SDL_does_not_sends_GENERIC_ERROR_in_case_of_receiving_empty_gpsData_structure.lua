---------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1876
---------------------------------------------------------------------------------------------
-- In case
-- HMI sends GetVehilceData_response with:
--  - 'gpsData' structure
--  - and this structure is empty (has no parameters)
-- SDL must:
-- 1. treat GetVehicleData_response as invalid
-- 2. send 'GENERIC_ERROR, success:false, info: Invalid response received from system' to mobile app
-- 3. log corresponding error internally
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      }
    }
  }
  pTbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].groups = { "Base-4", "NewTestCaseGroup" }
end

local function getVD()
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { gps = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { gps = true })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = {} })
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetVehicleData_with_empty_gps_struct_in_response", getVD)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

