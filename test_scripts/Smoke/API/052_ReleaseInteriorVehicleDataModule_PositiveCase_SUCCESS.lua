---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: ReleaseInteriorVehicleDataModule
-- Item: Happy path
--
-- Requirement summary:
-- [ReadDID] SUCCESS: getting SUCCESS:ReleaseInteriorVehicleDataModule()
--
-- Description:
-- Mobile application sends valid ReleaseInteriorVehicleDataModule request for CLIMATE:C0A RC module.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently Full HMI level
-- d. CLIMATE:C0A RC module is allocated to appID

-- Steps:
-- appID requests ReleaseInteriorVehicleDataModule with valid parameters

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
local moduleData = {
  moduleType = "CLIMATE",
  moduleId = commonSmoke.getRcModuleId("CLIMATE", 1),
  climateControlData = {
    fanSpeed = 18
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
local function allocateInteriorVehicleDataModule(self)
  local mobSession = commonSmoke.getMobileSession(1, self)
  local cid = mobSession:SendRPC("SetInteriorVehicleData", params.mobRequest)
  EXPECT_HMICALL("RC.SetInteriorVehicleData", params.hmiRequest)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params.hmiResponse)
    end)
  mobSession:ExpectResponse(cid, params.mobResponse)
end

local function releaseInteriorVehicleDataModule(self)
  local mobSession = commonSmoke.getMobileSession(1, self)
  local cid = mobSession:SendRPC("ReleaseInteriorVehicleDataModule",
      { moduleType = moduleData.moduleType, moduleId = moduleData.moduleId })
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Prepare preloaded policy table", commonSmoke.preparePreloadedPTForRC)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("AllocateInteriorVehicleDataModule CLIMATE module", allocateInteriorVehicleDataModule)

runner.Title("Test")
runner.Step("ReleaseInteriorVehicleDataModule CLIMATE module Positive Case", releaseInteriorVehicleDataModule)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
