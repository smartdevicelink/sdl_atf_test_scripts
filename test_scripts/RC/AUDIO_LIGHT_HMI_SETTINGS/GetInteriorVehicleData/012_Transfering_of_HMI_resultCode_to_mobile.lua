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
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local modules = { "AUDIO", "LIGHT", "HMI_SETTINGS" }
local success_codes = { "WARNINGS" }
local error_codes = { "GENERIC_ERROR", "INVALID_DATA", "OUT_OF_MEMORY", "REJECTED" }

--[[ Local Functions ]]
local function stepSuccessfull(pModuleType, pResultCode)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = pModuleType,
      subscribe = true
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
      appID = common.getHMIAppId(),
      moduleType = pModuleType,
      subscribe = true
    })
  :Do(function(_, data)
      common.getHMIconnection():SendResponse(data.id, data.method, pResultCode, {
          moduleData = common.getModuleControlDataForResponse(pModuleType),
          isSubscribed = false
        })
    end)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = pResultCode,
      isSubscribed = false,
      moduleData = common.getModuleControlDataForResponse(pModuleType)
    })
end

local function stepUnsuccessfull(pModuleType, pResultCode)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = pModuleType,
      subscribe = true
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
      appID = common.getHMIAppId(),
      moduleType = pModuleType,
      subscribe = true
    })
  :Do(function(_, data)
      common.getHMIconnection():SendError(data.id, data.method, pResultCode, "Error error")
    end)

  mobileSession:ExpectResponse(cid, { success = false, resultCode = pResultCode})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.raiPTUn)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

for _, mod in pairs(common.modules) do
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
runner.Step("Stop SDL", common.postconditions)
