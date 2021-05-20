---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1584
--
-- Description:
-- App sends RPC before RegisterAppInterface
--
-- Preconditions:
-- 1) Clean environment
-- 2) SDL, HMI, Mobile session started
--
-- Steps: 
-- 1) Mobile sends an RPC
--
-- Expected:
-- 1) Mobile receives resultCode APPLICATION_NOT_REGISTERED
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]

--[[ Local Functions ]]
local function test()
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC("UnregisterAppInterface", {})
  mobileSession:ExpectResponse(cid, { resultCode = "APPLICATION_NOT_REGISTERED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Mobile Sends RPC", test)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)