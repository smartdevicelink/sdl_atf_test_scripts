---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item:
--
-- Description:
-- In case:
-- 1) "moduleType" does not exist in app's assigned policies
-- 2) and RC app sends GetInteriorVehicleData request with valid parameters
-- SDL must:
-- 1) Disallow this RPC to be processed (success:false, "DISALLOWED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getDataForModule(module_type)
  local mobSession = commonRC.getMobileSession()
  local cid = mobSession:SendRPC("GetInteriorVehicleData", {
    moduleType = module_type,
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
  :Times(0)

  mobSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = nil
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("GetInteriorVehicleData SEAT", getDataForModule, { "SEAT" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
