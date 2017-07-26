---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData Requirement
--
-- Description:
-- In case:
-- 1) RC app sends valid and allowed by policies GetInteriorvehicleData request
-- 2) and SDL received GetInteriorVehicledata response with successful result code and current module data from HMI
-- SDL must:
-- 1) Transfer GetInteriorVehicleData response with provided from HMI current module data for allowed module and control items
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }
local success_codes = { "WARNINGS" }
local error_codes = { "GENERIC_ERROR", "INVALID_DATA", "OUT_OF_MEMORY", "REJECTED" }

--[[ Local Functions ]]
local function stepSuccessfull(pModuleType, pResultCode, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleType = pModuleType,
    subscribe = true
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, pResultCode, {
        moduleData = commonRC.getModuleControlData(pModuleType)
        -- isSubscribed = true
      })
    end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = pResultCode,
    -- isSubscribed = true,
    moduleData = commonRC.getModuleControlData(pModuleType)
  })
end

local function stepUnsuccessfull(pModuleType, pResultCode, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleType = pModuleType,
    subscribe = true
  })
  :Do(function(_, data)
      self.hmiConnection:SendError(data.id, data.method, pResultCode, "Error error")
    end)

  EXPECT_RESPONSE(cid, { success = false, resultCode = pResultCode})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

for _, mod in pairs(modules) do
  for _, code in pairs(success_codes) do
    runner.Step("GetInteriorVehicleData " .. mod .. " with " .. code .. " resultCode", stepSuccessfull, { mod, code })
  end
end

for _, mod in pairs(modules) do
  for _, code in pairs(error_codes) do
    runner.Step("GetInteriorVehicleData " .. mod .. " with " .. code .. " resultCode", stepUnsuccessfull, { mod, code })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
