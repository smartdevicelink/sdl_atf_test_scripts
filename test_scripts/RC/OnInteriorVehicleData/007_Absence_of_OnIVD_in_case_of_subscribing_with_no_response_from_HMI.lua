---------------------------------------------------------------------------------------------------
-- RPC: OnInteriorVehicleData
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Valiables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function subscriptionToModule(pModuleType, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleDescription = {
      moduleType = pModuleType
    },
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleDescription = {
      moduleType = pModuleType
    },
    subscribe = true
  })
  :Do(function(_, _)
      -- no response from HMI
    end)

  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })

  commonTestCases:DelayedExp(11000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, subscriptionToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is not subscribed", commonRC.isUnsubscribed, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
