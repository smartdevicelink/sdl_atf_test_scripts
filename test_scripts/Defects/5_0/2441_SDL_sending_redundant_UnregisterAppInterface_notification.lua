---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2441
--
-- Description:
-- SDL sending redundant UnregisterAppInterface notification to mobile.
-- Steps to reproduce:
-- 1) Register and activate App
-- 2) Unregister App
-- Expected:
-- 1) SDL must send response to mobile applications request and send notification to HMI. 
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local variables ]]

-- [[ Local function ]]
local function unregisterApp()
    local cid = common.getMobileSession():SendRPC("UnregisterAppInterface", {})
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession():ExpectNotification("UnregisterAppInterface")
    :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Unregister App", unregisterApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
