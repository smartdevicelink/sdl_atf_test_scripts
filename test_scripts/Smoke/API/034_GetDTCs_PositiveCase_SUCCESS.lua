---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: GetDTCs
-- Item: Happy path
--
-- Requirement summary:
-- [GetDTCs] SUCCESS on VehicleInfo.GetDTCs
--
-- Description:
-- Mobile application sends GetDTCs request with valid parameters to SDL
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
--
-- Steps:
-- Application sends GetDTCs request with valid parameters to SDL
--
-- Expected:
-- SDL validates parameters of the request
-- SDL checks if VehicleInfo interface is available on HMI
-- SDL checks if GetDTCs is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the VehicleInfo part of request with allowed parameters to HMI
-- SDL receives VehicleInfo part of response from HMI with "SUCCESS" result code
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getDTCsSuccess()
  local requestParams = {
    ecuName = 2,
    dtcMask = 3
  }
  local responseParams = {
    ecuHeader = 2,
    dtc = { "line 0", "line 1", "line 2" }
  }

  local cid = common.getMobileSession():SendRPC("GetDTCs", requestParams)

  requestParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetDTCs", requestParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", responseParams)
    end)

  common.getMobileSession():ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    ecuHeader = responseParams.ecuHeader,
    dtc = responseParams.dtc
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetDTCs Positive Case", getDTCsSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
