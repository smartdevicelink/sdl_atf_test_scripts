---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Description:
-- In case:
-- 1) "moduleType" in app's assigned policies has one or more valid values
-- 2) and SDL received GetInteriorVehicleData request from App with moduleType not in list
-- SDL must:
-- 1) Disallow app's remote-control RPCs for this module (success:false, "DISALLOWED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local mod = "AUDIO"

--[[ Local Functions ]]
local function getDataForModule(pModuleType, self)
  local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData", {
      moduleType = pModuleType
    })
  EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
  :Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = { "CLIMATE" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { PTUfunc })
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("GetInteriorVehicleData " .. mod, getDataForModule, { mod })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
