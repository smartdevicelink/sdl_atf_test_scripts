---------------------------------------------------------------------------------------------------
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- Check that SDL respond resultCode "WARNINGS" application registration with "type":"FILE" for "ttsName"
-- In case:
-- 1) Mobile application is registered with ttsName: type = FILE
-- SDL does:
-- 1) Returned  WARNINGS response to the mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local pValue = commonPreconditions:GetPathToSDL() .. "storage/" .. common.getConfigAppParams( pAppId ).appID .. "_"
.. utils.getDeviceMAC() .. "/SyncProxyTester"

--[[ Local Variables ]]
local paramsApp1 = common.getRequestParams(1)
paramsApp1.ttsName = {{ text = pValue, type = "FILE"}}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)

runner.Title("Test")
runner.Step("Register_App_with_type_FILE", common.registerApp, { 1, paramsApp1, "WARNINGS" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
