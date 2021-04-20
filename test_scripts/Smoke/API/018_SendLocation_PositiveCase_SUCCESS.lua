---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: SendLocation
-- Item: Happy path
--
-- Requirement summary:
-- [SendLocation] SUCCESS: getting SUCCESS:Navigation.SendLocation()
--
-- Description:
-- Mobile application sends valid SendLocation request and gets Navigation.SendLocation "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests SendLocation with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if Navigation interface is available on HMI
-- SDL checks if SendLocation is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the Navigation part of request with allowed parameters to HMI
-- SDL receives Navigation part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local pParams ]]
local putFileParams = {
  requestParams = {
    syncFileName = 'icon.png',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local requestParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  locationName = "location Name",
  locationDescription = "location Description",
  addressLines = {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  locationImage ={
    value = "icon.png",
    imageType = "DYNAMIC"
  }
}

--[[ Local Functions ]]
local function sendLocation(pParams)
  local cid = common.getMobileSession():SendRPC("SendLocation", pParams)
  pParams.appID = common.getHMIAppId()
  pParams.locationImage.value = common.getPathToFileInAppStorage(pParams.locationImage.value)
  common.getHMIConnection():ExpectRequest("Navigation.SendLocation", pParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, { putFileParams })

runner.Title("Test")
runner.Step("SendLocation Positive Case", sendLocation, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
