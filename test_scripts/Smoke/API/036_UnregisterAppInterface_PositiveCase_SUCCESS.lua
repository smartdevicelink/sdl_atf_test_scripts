---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: UnregisterAppInterface
-- Item: Happy path
--
-- Requirement summary:
-- [UnregisterAppInterface] SUCCESS: getting SUCCESS:UnregisterAppInterface()
--
-- Description:
-- Mobile application sends valid UnregisterAppInterface request and gets UnregisterAppInterface "SUCCESS"
-- response from SDL

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests UnregisterAppInterface

-- Expected:
-- SDL checks if UnregisterAppInterface is allowed by Policies
-- SDL sends the BasicCommunication notification to HMI
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function unregisterAppInterface()
  local cid = common.getMobileSession():SendRPC("UnregisterAppInterface", { })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = false })
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("UnregisterAppInterface Positive Case", unregisterAppInterface)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
