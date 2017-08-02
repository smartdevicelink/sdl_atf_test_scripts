---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) RC app sends SetInteriorVehicleData request with valid parameters
-- 2) and HMI response is invalid
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
  local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
    moduleData = commonRC.getSettableModuleControlData(pModuleType)
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleData = commonRC.getSettableModuleControlData(pModuleType)
  })
  :Do(function(_, data)
      local modData = commonRC.getSettableModuleControlData(pModuleType)
      modData.moduleType = "MODULE" -- invalid value of parameter
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = modData,
        isSubscribed = "yes" -- fake parameter
      })
    end)

  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

local function missingMandatoryParam(pModuleType, self)
  local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
    moduleData = commonRC.getSettableModuleControlData(pModuleType)
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleData = commonRC.getSettableModuleControlData(pModuleType)
  })
  :Do(function(_, data)
      local moduleData = commonRC.getModuleControlData(pModuleType)
      moduleData.moduleType = nil -- missing mandatory parameter
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = moduleData
      })
    end)

  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("SetInteriorVehicleData " .. mod .. " Invalid response from HMI-Invalid type of parameter", invalidParamType, { mod })
  runner.Step("SetInteriorVehicleData " .. mod .. " Invalid response from HMI-Missing mandatory parameter", missingMandatoryParam, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
