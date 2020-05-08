---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item:
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

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function invalidParamName(pModuleType)
  local cid = commonRC.getMobileSession():SendRPC("GetInteriorVehicleData", {
    modduleType = pModuleType, -- invalid name of parameter
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {}):Times(0)
  commonRC.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function invalidParamType(pModuleType)
  local cid = commonRC.getMobileSession():SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = 17 -- invalid type of parameter
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {}):Times(0)
  commonRC.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function missingMandatoryParam()
  local cid = commonRC.getMobileSession():SendRPC("GetInteriorVehicleData", {
    -- moduleType = "CLIMATE", --  mandatory parameter absent
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {}):Times(0)
  commonRC.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function fakeParam(pModuleType)
  local cid = commonRC.getMobileSession():SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    fakeParam = "value",
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = true
  })
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.getModuleControlData(pModuleType),
        isSubscribed = true
      })
    end)

  commonRC.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    isSubscribed = true,
    moduleData = commonRC.getModuleControlData(pModuleType)
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

runner.Step("GetInteriorVehicleData SEAT invalid name of parameter", invalidParamName, { "SEAT" })
runner.Step("GetInteriorVehicleData SEAT invalid type of parameter", invalidParamType, { "SEAT" })
runner.Step("GetInteriorVehicleData SEAT fake parameter", fakeParam, { "SEAT" })
runner.Step("GetInteriorVehicleData mandatory parameter absent", missingMandatoryParam)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
