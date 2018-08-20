---------------------------------------------------------------------------------------------------
-- Regression check
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Application is tried to register with appName which not listed in nickNames.
-- SDL does:
-- 1) Not register and return DISALLOWED response to the applicatin.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require('user_modules/utils')
local json = require("modules/json")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

local pAppId = "1234567"
local pResultCode = { success = false, resultCode = "DISALLOWED" }

--[[ Local Functions ]]
local function setNickNameForSpecificApp()
    local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
    local pt = utils.jsonFileToTable(preloadedFile)
    pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null

      pt.policy_table.app_policies["1234567"] = utils.cloneTable(pt.policy_table.app_policies.default)
    pt.policy_table.app_policies["1234567"].nicknames = { "SPT" }
    utils.tableToJsonFile(pt, preloadedFile)
  end

local function rai_appNameNotListedInNickNames()
    common.getMobileSession():StartService(7)
    :Do(function()
        local CorIdRegister = common.getMobileSession():SendRPC("RegisterAppInterface",
        {
            syncMsgVersion = {
            majorVersion = 3,
            minorVersion = 0 },
            appName = "TestApplication",
            isMediaApplication = true,
            languageDesired = 'EN-US',
            hmiDisplayLanguageDesired = 'EN-US',
            appID = "1234567"
        })
        common.getMobileSession():ExpectResponse(CorIdRegister, { success = false, resultCode = "DISALLOWED" })
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("PTU update", setNickNameForSpecificApp)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)

runner.Title("Test")
runner.Step("Register_with_appName_which_not_Listed_in_NickNames", rai_appNameNotListedInNickNames)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)