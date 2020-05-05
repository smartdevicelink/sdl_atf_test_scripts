---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2399
--
-- Description:
-- SDL must respond UNSUPPORTED_RESOURCE to SystemRequest(QUERY_APPS) in case app is registered with protocol version
-- less than 4.0
-- Precondition:
-- SDL and HMI are started.
-- App is registered and activated.
-- In case:
-- 1) Application sends SystemRequest(QUERY_APPS)
-- SDL must:
-- 1) Respond SystemRequest (UNSUPPORTED_RESOURCE, success:false) to mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local protocol_version = 3

--[[ Local Functions ]]
local function updateINIFile()
  commonFunctions:write_parameter_to_smart_device_link_ini("MaxSupportedProtocolVersion", protocol_version)
end

local function systemRequest()
  local cid = common.getMobileSession():SendRPC("SystemRequest", { requestType = "QUERY_APPS" })
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("updateINIFile", updateINIFile)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("SystemRequest (QUERY_APPS) request", systemRequest)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
