---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleData
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function getDataForModule(module_type, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleDescription = {
      moduleType = module_type
    },
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
  :Times(0)

  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = nil
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("GetInteriorVehicleData " .. mod, getDataForModule, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
