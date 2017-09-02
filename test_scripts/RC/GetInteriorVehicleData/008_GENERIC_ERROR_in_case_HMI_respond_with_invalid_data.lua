---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Exceptions: 5.1
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) RC app sends GetInteriorVehicleData request with valid parameters
-- 2) and HMI responds with invalid data:
--    - invalid type of parameter
--    - missing mandatory parameter
-- SDL must:
-- 1) Respond to App with success:false, "GENERIC_ERROR"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function invalidParamType(pModuleType, self)
  local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleType = pModuleType,
    subscribe = true
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.getModuleControlData(pModuleType),
        isSubscribed = "yes" -- invalid type of parameter
      })
    end)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

local function missingMandatoryParam(pModuleType, self)
  local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleType = pModuleType,
    subscribe = true
  })
  :Do(function(_, data)
      local moduleData = commonRC.getModuleControlData(pModuleType)
      moduleData.moduleType = nil -- missing mandatory parameter
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = moduleData,
        isSubscribed = true
      })
    end)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("GetInteriorVehicleData " .. mod .. " Invalid response from HMI-Invalid type of parameter", invalidParamType, { mod })
  runner.Step("GetInteriorVehicleData " .. mod .. " Invalid response from HMI-Missing mandatory parameter", missingMandatoryParam, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
