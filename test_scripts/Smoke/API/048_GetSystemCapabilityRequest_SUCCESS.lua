---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: GetSystemCapabilities
-- Item: Happy path
--
-- Requirement summary:
-- [ReadDID] SUCCESS: getting SUCCESS:VehicleInfo.GetSystemCapabilities()
--
-- Description:
-- Mobile application sends valid GetSystemCapabilities request for Nav, Phone, and Video.
-- Capabilities related to app services and remote control are in seperate tests.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests GetSystemCapabilities with valid parameters

-- Expected:
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application for all Nav, Phone, and Video capability types
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local navCapabilities = {
  navigationCapability={
    getWayPointsEnabled=true,
    sendLocationEnabled=true
  },
  systemCapabilityType="NAVIGATION"
}
local phoneCapabilities = {
  phoneCapability={
    dialNumberEnabled=true
  },
  systemCapabilityType="PHONE_CALL"
}
local videoCapabilities = {
  videoStreamingCapability={
    preferredResolution={
      resolutionWidth=800,
      resolutionHeight=350
    },
    maxBitrate=10000,
    supportedFormats={{
      protocol="RAW",
      codec="H264"
    }},
    hapticSpatialDataSupported= false
  },
  systemCapabilityType="VIDEO_STREAMING"
}

--[[ Local Functions ]]
local function getSystemCapabilityRequest(type)
  local temp = {
    systemCapabilityType = type
  }
  return temp
end

local function getSystemCapabilityResponse(capabilities)
  local temp = {
    systemCapability = capabilities
  }
  return temp
end

local function getSystemCapability(capabilities)
  local type = capabilities.systemCapabilityType
  local paramsSend = getSystemCapabilityRequest(type)
  local response = getSystemCapabilityResponse(capabilities)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetSystemCapability", paramsSend)

  local expectedResult = response
  expectedResult.success = true
  expectedResult.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, expectedResult)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability NAVIGATION Positive Case", getSystemCapability, {navCapabilities})
runner.Step("GetSystemCapability PHONE_CALL Positive Case", getSystemCapability, {phoneCapabilities})
runner.Step("GetSystemCapability VIDEO_STREAMING Positive Case", getSystemCapability, {videoCapabilities})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
