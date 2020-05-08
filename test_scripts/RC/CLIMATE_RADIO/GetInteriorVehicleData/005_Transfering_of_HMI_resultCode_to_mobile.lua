---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Exceptions: 5.2
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
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

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local success_codes = { "WARNINGS" }
local error_codes = { "GENERIC_ERROR", "INVALID_DATA", "OUT_OF_MEMORY", "REJECTED" }

--[[ Local Functions ]]
local function stepSuccessfull(pModuleType, pResultCode)
  local cid = commonRC.getMobileSession():SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = true
  })
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, pResultCode, {
        moduleData = commonRC.getModuleControlData(pModuleType)
        -- isSubscribed = true
      })
    end)

  commonRC.getMobileSession():ExpectResponse(cid, { success = true, resultCode = pResultCode,
    isSubscribed = false,
    moduleData = commonRC.getModuleControlData(pModuleType)
  })
end

local function stepUnsuccessfull(pModuleType, pResultCode)
  local cid = commonRC.getMobileSession():SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = true
  })
  :Do(function(_, data)
      commonRC.getHMIConnection():SendError(data.id, data.method, pResultCode, "Error error")
    end)

  commonRC.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

for _, mod in pairs(commonRC.modules) do
  for _, code in pairs(success_codes) do
    runner.Step("GetInteriorVehicleData " .. mod .. " with " .. code .. " resultCode", stepSuccessfull, { mod, code })
  end
end

for _, mod in pairs(commonRC.modules) do
  for _, code in pairs(error_codes) do
    runner.Step("GetInteriorVehicleData " .. mod .. " with " .. code .. " resultCode", stepUnsuccessfull, { mod, code })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
