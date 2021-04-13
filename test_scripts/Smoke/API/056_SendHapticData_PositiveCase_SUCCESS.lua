---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: SendHapticData
-- Item: Happy path
--
-- Requirement summary:
-- [SendHapticData] SUCCESS: getting SUCCESS:UI.SendHapticData()
--
-- Description:
-- Mobile application sends valid SendHapticData request with valid parameters to SDL

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. Mobile app is registered and activated on SDL
-- c. Mobile app is currently Full HMI level

-- Steps:
-- 1. Mobile app requests SendHapticData with valid parameters
-- 2. HMI receives UI.SendHapticData request and responds with SUCCESS

-- Expected:
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hapticData = {
  hapticRectData = {
    { id = 1, rect = { x = 1, y = 1.5, width = 1, height = 1.5 } }
  }
}

--[[ Local Functions ]]
local function sendHapticData()
  local mobSession = common.getMobileSession()
  local hmi = common.getHMIConnection()
  local cid = mobSession:SendRPC("SendHapticData", hapticData)
  local hmiData = common.cloneTable(hapticData)
  hmiData.appID = common.getHMIAppId()
  hmi:ExpectRequest("UI.SendHapticData", hmiData)
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS")
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SendHapticData Positive Case", sendHapticData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
