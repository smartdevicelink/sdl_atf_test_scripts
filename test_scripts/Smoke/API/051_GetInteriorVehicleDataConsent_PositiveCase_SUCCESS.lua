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
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local moduleType = "CLIMATE"
local moduleIds  = { commonSmoke.getRcModuleId(moduleType, 1), commonSmoke.getRcModuleId(moduleType, 2) }

local params = {
  mobRequest = {
    moduleType = moduleType,
    moduleIds = moduleIds
  },
  hmiRequest = {
    appID = commonSmoke.getHMIAppId(1),
    moduleType = moduleType,
    moduleIds = moduleIds
  },
  hmiResponse = {
    allowed = { true, false }
  },
  mobResponse = {
    success = true,
    resultCode = "SUCCESS",
    allowed = { true, false }
  }
}

--[[ Local Functions ]]
local function getInteriorVehicleDataConsent(self)
  local mobSession = commonSmoke.getMobileSession(1, self)
  local cid = mobSession:SendRPC("GetInteriorVehicleDataConsent", params.mobRequest)
  EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent", params.hmiRequest)
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
runner.Step("GetInteriorVehicleDataConsent CLIMATE modules Positive Case", getInteriorVehicleDataConsent)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
