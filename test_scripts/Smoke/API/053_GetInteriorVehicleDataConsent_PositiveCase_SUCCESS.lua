---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: GetInteriorVehicleDataConsent
-- Item: Happy path
--
-- Requirement summary:
-- [ReadDID] SUCCESS: getting SUCCESS:RC.GetInteriorVehicleDataConsent()
--
-- Description:
-- Mobile application sends valid GetInteriorVehicleDataConsent request for CLIMATE RC modules.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently Full HMI level

-- Steps:
-- appID requests GetInteriorVehicleDataConsent with valid parameters

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
local moduleType = "CLIMATE"
local moduleIds  = { common.getRcModuleId(moduleType, 1), common.getRcModuleId(moduleType, 2) }

local params = {
  mobRequest = {
    moduleType = moduleType,
    moduleIds = moduleIds
  },
  mobResponse = {
    success = true,
    resultCode = "SUCCESS",
    allowed = { true, true }
  }
}

--[[ Local Functions ]]
local function getInteriorVehicleDataConsent()
  local mobSession = common.getMobileSession()
  local cid = mobSession:SendRPC("GetInteriorVehicleDataConsent", params.mobRequest)
  common.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleDataConsent")
  :Times(0)
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
runner.Step("GetInteriorVehicleDataConsent CLIMATE modules Positive Case", getInteriorVehicleDataConsent)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
