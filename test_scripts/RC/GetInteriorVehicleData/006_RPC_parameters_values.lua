---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Exceptions: 2.1
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) RC app sends GetInteriorVehicleData request with invalid parameters
--    - invalid parameter name
--    - invalid parameter type
--    - missing mandatory parameter
-- SDL must:
-- 1) Do not transfer request to HMI
-- 2) Respond with success:false, "INVALID_DATA"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function invalidParamName(pModuleType, self)
  local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData", {
    modduleType = pModuleType, -- invalid name of parameter
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
  :Times(0)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function invalidParamType(pModuleType, self)
  local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = 17 -- invalid type of parameter
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
  :Times(0)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function missingMandatoryParam(self)
  local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData", {
    -- moduleType = "CLIMATE", --  mandatory parameter absent
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
  :Times(0)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function fakeParam(pModuleType, self)
  local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    fakeParam = 7,
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
        isSubscribed = true
      })
    end)

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    isSubscribed = true,
    moduleData = commonRC.getModuleControlData(pModuleType)
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("GetInteriorVehicleData " .. mod .. " invalid name of parameter", invalidParamName, { mod })
  runner.Step("GetInteriorVehicleData " .. mod .. " invalid type of parameter", invalidParamType, { mod })
  runner.Step("GetInteriorVehicleData " .. mod .. " fake parameter", fakeParam, { mod })
end

runner.Step("GetInteriorVehicleData mandatory parameter absent", missingMandatoryParam)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
