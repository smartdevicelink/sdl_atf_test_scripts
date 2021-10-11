---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2399
---------------------------------------------------------------------------------------------------
-- Description:
-- SDL does respond UNSUPPORTED_RESOURCE to SystemRequest(QUERY_APPS) in case mobile app is registered with protocol
-- version less than 4.0
---------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is registered and activated
-- 2. Mobile app requests SystemRequest(QUERY_APPS)
-- SDL does:
-- - Respond SystemRequest (UNSUPPORTED_RESOURCE, success:false) to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local maxSdlProtocolVersion = 3

--[[ Local function ]]
local function systemRequest()
  local cid = common.getMobileSession():SendRPC("SystemRequest", { requestType = "QUERY_APPS" })
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update INI File", common.setSDLIniParameter, { "MaxSupportedProtocolVersion", maxSdlProtocolVersion })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("SystemRequest (QUERY_APPS) request", systemRequest)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
