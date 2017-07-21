---------------------------------------------------------------------------------------------------
-- Description
-- In case:
-- 1) RC app is subscribed to "<moduleType_value>"
-- 2) and RC app sends valid and allowed-by-policies GetInteriorVehicleData request with "subscribe:false" parameter
-- 3) and SDL received GetInteriorVehicleData response with "resultCode: <any-erroneous-result>" from HMI
--    and with "isSubscribed" parameter
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
local error_codes = {
  { name = "GENERIC_ERROR", id = 22 },
  { name = "INVALID_DATA", id = 11 },
  { name = "OUT_OF_MEMORY", id = 17 },
  { name = "REJECTED", id = 4 }
}

--[[ Local Functions ]]
local function unSubscriptionToModule(pModuleType, pResultCodeName, pResultCodeId, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleDescription = {
      moduleType = pModuleType
    },
    subscribe = false
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleDescription = {
      moduleType = pModuleType
    },
    subscribe = false
  })
  :Do(function(_, data)
      self.hmiConnection:Send('{"error":{"data":{"method":"' .. data.method .. '"},"params":{"isSubscribed":false},'
        .. '"message":"error message","code":' .. pResultCodeId .. '},"jsonrpc":"2.0","id":' .. data.id .. '}')
    end)

  EXPECT_RESPONSE(cid, { success = false, resultCode = pResultCodeName })
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
    runner.Step("Unsubscribe app to " .. mod .. " (" .. err.name .. " from HMI)", unSubscriptionToModule, { mod, err.name, err.id })
    runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App still subscribed", commonRC.isSubscribed, { mod })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
