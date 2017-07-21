---------------------------------------------------------------------------------------------------
-- Description
-- In case:
-- 1) RC app sends valid and allowed by policies GetInteriorvehicleData request without "subscribe" parameter
-- 2) and SDL received GetInteriorVehicledata response with "resultCode:<any_result>" and with "isSubscribed" parameter from HMI
-- SDL must:
-- 1) Transfer GetInteriorVehicleData response with provided from HMI current module data
-- and without "isSubscribed" parameter to the related app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function getDataForModule(pModuleType, isSubscriptionActive, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleDescription = {
      moduleType = pModuleType
    },
    -- no subscribe parameter
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleDescription = {
      moduleType = pModuleType
    }
    -- no subscribe parameter
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.getModuleControlData(pModuleType),
        isSubscribed = isSubscriptionActive -- return current value of subscription
      })
    end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
    moduleData = commonRC.getModuleControlData(pModuleType)
    -- no isSubscribed parameter
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("GetInteriorVehicleData " .. mod .. " NoSubscription", getDataForModule, { mod, false })
end

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, commonRC.subscribeToModule, { mod })
  runner.Step("GetInteriorVehicleData " .. mod .. " ActiveSubscription_subscribe", getDataForModule, { mod, true })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
