---------------------------------------------------------------------------------------------------
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) The mobile application is registerы with value for "languageDesired" , which does not match the ones installed on the HMI.
-- SDL does:
-- 1) Send the WRONG_LANGUAGE response result code to mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local firstWrongLang = utils.cloneTable(common.getRequestParams(1))
firstWrongLang.languageDesired = "DE-DE"
local secondWrongLang = utils.cloneTable(common.getRequestParams(1))
secondWrongLang.hmiDisplayLanguageDesired = "DE-DE"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)

runner.Title("Test")
runner.Step("RAI_with_wrong_languageDesired_parameter", common.registerApp, {1, firstWrongLang, "WRONG_LANGUAGE" })
runner.Step("Application unregistered", common.unregisterAppInterface)
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("RAI_with_wrong_hmiDisplayLanguageDesired_parameter", common.registerApp, {1, secondWrongLang, "WRONG_LANGUAGE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
