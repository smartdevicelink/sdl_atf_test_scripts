---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: GetInteriorVehicleData
-- Item: Happy path
--
-- Requirement summary:
-- [ReadDID] SUCCESS: getting SUCCESS:RC.GetInteriorVehicleData()
--
-- Description:
-- Mobile application sends valid GetInteriorVehicleData request for CLIMATE:C0A RC module.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently Full HMI level

-- Steps:
-- appID requests GetInteriorVehicleData with valid parameters

-- Expected:
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local moduleId = common.getRcModuleId("CLIMATE", 1)

local moduleData = {
  moduleType = "CLIMATE",
  moduleId = moduleId,
  climateControlData = {
    fanSpeed = 10,
    currentTemperature = {
      unit = "FAHRENHEIT",
      value = 22.4
    },
    desiredTemperature = {
      unit = "CELSIUS",
      value = 20.7
    },
    acEnable = false,
    circulateAirEnable = true,
    autoModeEnable = true,
    defrostZone = "FRONT",
    dualModeEnable = false,
    acMaxEnable = true,
    ventilationMode = "BOTH",
    heatedSteeringWheelEnable = true,
    heatedWindshieldEnable = false,
    heatedRearWindowEnable = true,
    heatedMirrorsEnable = true
  }
}

local params = {
  mobRequest = {
    moduleType = "CLIMATE",
    moduleId = moduleId,
    subscribe = true
  },
  hmiRequest = {
    moduleType = "CLIMATE",
    moduleId = moduleId,
    subscribe = true
  },
  hmiResponse = {
    moduleData = moduleData,
    isSubscribed = true
  },
  mobResponse = {
    success = true,
    resultCode = "SUCCESS",
    moduleData = moduleData,
    isSubscribed = true
  }
}

--[[ Local Functions ]]
local function getInteriorVehicleData()
  local mobSession = common.getMobileSession()
  local hmi = common.getHMIConnection()
  local cid = mobSession:SendRPC("GetInteriorVehicleData", params.mobRequest)
  hmi:ExpectRequest("RC.GetInteriorVehicleData", params.hmiRequest)
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", params.hmiResponse)
    end)
  mobSession:ExpectResponse(cid, params.mobResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPTForRC)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetInteriorVehicleData CLIMATE module Positive Case", getInteriorVehicleData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
