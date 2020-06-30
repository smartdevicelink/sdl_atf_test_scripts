---------------------------------------------------------------------------------------------
-- GitHub issue: https://github.com/smartdevicelink/sdl_core/issues/955
---------------------------------------------------------------------------------------------
-- Steps:
-- 1. Register app
-- 2. Activate app
-- 3. Send SystemRequest(PROPRIETARY, "/test")
--
-- Expected:
-- SDL responds to SystemRequest with INVALID DATA result code
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
 runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function SendSystemRequestwithFileName()
    local cid  = common.getMobileSession():SendRPC("SystemRequest", {
      requestType = "PROPRIETARY",
      fileName = "/test" })
    common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.registerApp)
runner.Step("Activate App1", common.activateApp)
runner.Step("PTU", common.policyTableUpdate)

runner.Title("Test")
runner.Step("Mobile sends SystemRequest with file", SendSystemRequestwithFileName)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
