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
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local moduleData = {
  moduleType = "CLIMATE",
  moduleId = common.getRcModuleId("CLIMATE", 1),
  climateControlData = {
    fanSpeed = 18
  }
}

local params = {
  mobRequest = {
    moduleData = moduleData
  },
  hmiRequest = {
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
local function allocateInteriorVehicleDataModule()
  local mobSession = common.getMobileSession()
  local hmi = common.getHMIConnection()
  local cid = mobSession:SendRPC("SetInteriorVehicleData", params.mobRequest)
  params.hmiRequest.appID = common.getHMIAppId(1)
  hmi:ExpectRequest("RC.SetInteriorVehicleData", params.hmiRequest)
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", params.hmiResponse)
    end)
  mobSession:ExpectResponse(cid, params.mobResponse)
end

local function releaseInteriorVehicleDataModule()
  local mobSession = common.getMobileSession()
  local cid = mobSession:SendRPC("ReleaseInteriorVehicleDataModule",
      { moduleType = moduleData.moduleType, moduleId = moduleData.moduleId })
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPTForRC)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("AllocateInteriorVehicleDataModule CLIMATE module", allocateInteriorVehicleDataModule)

runner.Title("Test")
runner.Step("ReleaseInteriorVehicleDataModule CLIMATE module Positive Case", releaseInteriorVehicleDataModule)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
