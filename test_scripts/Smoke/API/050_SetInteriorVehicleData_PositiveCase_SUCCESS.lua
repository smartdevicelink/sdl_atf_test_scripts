---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: SetInteriorVehicleData
-- Item: Happy path
--
-- Requirement summary:
-- [ReadDID] SUCCESS: getting SUCCESS:RC.SetInteriorVehicleData()
--
-- Description:
-- Mobile application sends valid SetInteriorVehicleData request for CLIMATE:C0A RC module.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently Full HMI level

-- Steps:
-- appID requests SetInteriorVehicleData with valid parameters

-- Expected:
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local moduleId = commonSmoke.getRcModuleId("CLIMATE", 1)

local moduleData = {
  moduleType = "CLIMATE",
  moduleId = moduleId,
  climateControlData = {
    fanSpeed = 12,
    acEnable = true,
    circulateAirEnable = false,
    autoModeEnable = true,
    dualModeEnable = false,
    acMaxEnable = true,
    ventilationMode = "BOTH",
    heatedSteeringWheelEnable = true,
    heatedWindshieldEnable = true,
    heatedRearWindowEnable = false,
    heatedMirrorsEnable = true
  }
}

local params = {
  mobRequest = {
    moduleData = moduleData
  },
  hmiRequest = {
    appID = commonSmoke.getHMIAppId(1),
    moduleData = moduleData
  },
  hmiResponse = {
    moduleData = moduleData
  },
  mobResponse = {
    success = true,
    resultCode = "SUCCESS",
    moduleData = moduleData
  }
}

--[[ Local Functions ]]
local function setInteriorVehicleData(self)
  local mobSession = commonSmoke.getMobileSession(1, self)
  local cid = mobSession:SendRPC("SetInteriorVehicleData", params.mobRequest)
  EXPECT_HMICALL("RC.SetInteriorVehicleData", params.hmiRequest)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params.hmiResponse)
    end)
  mobSession:ExpectResponse(cid, params.mobResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Prepare preloaded policy table", commonSmoke.preparePreloadedPTForRC)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("SetInteriorVehicleData CLIMATE module Positive Case", setInteriorVehicleData)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
