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
-- - invalid parameter name
-- - invalid parameter type
-- - missing mandatory parameter
-- SDL must:
-- 1) Do not transfer request to HMI
-- 2) Respond with success:false, "INVALID_DATA"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function invalidParamName(pModuleType)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      modduleType = pModuleType, -- invalid name of parameter
      subscribe = true
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
  :Times(0)

  mobileSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function invalidParamType(pModuleType)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = pModuleType,
      subscribe = 17 -- invalid type of parameter
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
  :Times(0)

  mobileSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function missingMandatoryParam()
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      -- moduleType = "CLIMATE", -- mandatory parameter absent
      subscribe = true
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
  :Times(0)

  mobileSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function fakeParam(pModuleType)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = pModuleType,
      fakeParam = 7,
      subscribe = true
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
      moduleType = pModuleType,
      subscribe = true
    })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = common.getModuleControlDataForResponse(pModuleType),
          isSubscribed = true
        })
    end)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
      isSubscribed = true,
      moduleData = common.getModuleControlDataForResponse(pModuleType)
    })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

for _, mod in pairs(common.newModules) do
  runner.Step("GetInteriorVehicleData " .. mod .. " invalid name of parameter", invalidParamName, { mod })
  runner.Step("GetInteriorVehicleData " .. mod .. " invalid type of parameter", invalidParamType, { mod })
  runner.Step("GetInteriorVehicleData " .. mod .. " fake parameter", fakeParam, { mod })
end

runner.Step("GetInteriorVehicleData mandatory parameter absent", missingMandatoryParam)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
