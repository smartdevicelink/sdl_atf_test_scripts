---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Unsubscribe from RC module change notifications Requirement
--
-- Description:
-- In case:
-- 1) RC app is subscribed to "<moduleType_value>"
-- 2) and RC app sends valid and allowed-by-policies GetInteriorVehicleData request with "subscribe:false" parameter
-- 3) and SDL received GetInteriorVehicleData response with "resultCode: <any-erroneous-result>" from HMI
--    and without "isSubscribed" parameter
-- 4) and then SDL received OnInteriorVehicleData notification
-- SDL must:
-- 1) Transfer GetInteriorVehicleData response with "resultCode: <any-erroneous-result>" and without "isSubscribed" param to the related app
-- 2) Re-send OnInteriorVehicleData notification to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }
local error_codes = { "GENERIC_ERROR", "INVALID_DATA", "OUT_OF_MEMORY", "REJECTED" }

--[[ Local Functions ]]
local function unSubscriptionToModule(pModuleType, pResultCode, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = false
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleType = pModuleType,
    subscribe = false
  })
  :Do(function(_, data)
      self.hmiConnection:SendError(data.id, data.method, pResultCode, "Error error")
      -- no isSubscribed parameter
    end)

  EXPECT_RESPONSE(cid, { success = false, resultCode = pResultCode })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, commonRC.subscribeToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App subscribed", commonRC.isSubscribed, { mod })
end

runner.Title("Test")

for _, mod in pairs(modules) do
  for _, err in pairs(error_codes) do
    runner.Step("Unsubscribe app to " .. mod .. " (" .. err .. " from HMI)", unSubscriptionToModule, { mod, err })
    runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App still subscribed", commonRC.isSubscribed, { mod })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
