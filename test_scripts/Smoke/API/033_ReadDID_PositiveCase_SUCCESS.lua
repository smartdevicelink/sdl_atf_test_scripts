---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: ReadDID
-- Item: Happy path
--
-- Requirement summary:
-- [ReadDID] SUCCESS: getting SUCCESS:VehicleInfo.ReadDID()
--
-- Description:
-- Mobile application sends valid ReadDID request and gets VehicleInfo.ReadDID "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests ReadDID with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if VehicleInfo interface is available on HMI
-- SDL checks if ReadDID is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the VehicleInfo part of request with allowed parameters to HMI
-- SDL receives VehicleInfo part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function setReadDIDRequest()
  return {
    ecuName = 2000,
    didLocation = {
      56832
    }
  }
end

local function setReadDIDSuccessResponse(pDIdLocationValues)
  local temp = {
    didResult = {}
  }
  for i = 1, #pDIdLocationValues do
    temp.didResult[i] = {
      resultCode = "SUCCESS",
      didLocation = pDIdLocationValues[i],
      data = "123"
    }
  end
  return temp
end

local function readDID()
  local paramsSend = setReadDIDRequest()
  local response = setReadDIDSuccessResponse(paramsSend.didLocation)
  local cid = common.getMobileSession():SendRPC("ReadDID",paramsSend)
  paramsSend.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("VehicleInfo.ReadDID",paramsSend)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", response)
    end)
  local expectedResult = response
  expectedResult.success = true
  expectedResult.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, expectedResult)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("ReadDID Positive Case", readDID)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
