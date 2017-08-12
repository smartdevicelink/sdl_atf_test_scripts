---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) Non remote-control application is registered on SDL
-- 2) and SDL received GetInteriorVehicleData request from this App
-- SDL must:
-- 1) Disallow remote-control RPCs for this app (success:false, "DISALLOWED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function getDataForModule(pModuleType, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData")
  :Times(0)

  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function ptu_update_func(tbl)
  local appId = config.application1.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId].moduleType = nil
  tbl.policy_table.app_policies[appId].groups_primaryRC = nil
  tbl.policy_table.app_policies[appId].AppHMIType = { "DEFAULT" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("GetInteriorVehicleData " .. mod, getDataForModule, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
