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
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Functions ]]
local function PTUpdateFunc(tbl)
  local GetDTCs = {
    rpcs = {
      GetDTCs = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
      }
    }
  }
  tbl.policy_table.functional_groupings.NewTestCaseGroup = GetDTCs
  tbl.policy_table.app_policies[commonSmoke.getMobileAppId()].groups = { "Base-4", "NewTestCaseGroup" }
end

local function getDTCsSuccess(self)
  local requestParams = {
    ecuName = 2,
    dtcMask = 3
  }
  local responseParams = {
    ecuHeader = 2,
    dtc = { "line 0", "line 1", "line 2" }
  }

  local cid = self.mobileSession1:SendRPC("GetDTCs", requestParams)

  requestParams.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("VehicleInfo.GetDTCs", requestParams)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responseParams)
    end)

  self.mobileSession1:ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    ecuHeader = responseParams.ecuHeader,
    dtc = responseParams.dtc
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU, { 1, PTUpdateFunc })
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("GetDTCs Positive Case", getDTCsSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
