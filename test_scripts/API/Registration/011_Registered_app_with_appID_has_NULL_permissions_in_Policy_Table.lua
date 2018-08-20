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
-- 1) Application registered with appID which has "null" permissions in Policy Table.
-- SDL does:
-- 1) Successfully register a mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local utils = require('user_modules/utils')
local json = require("modules/json")


--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

--[[ Local Functions ]]
local function backupPreloadedPT()
    commonPreconditions:BackupFile(preloadedPT)
end

local function updatePreloadedPT()
    local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
    local pt = utils.jsonFileToTable(preloadedFile)
    pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
    pt.policy_table.app_policies["0000001"] = json.null
    utils.tableToJsonFile(pt, preloadedFile)
end

local function restorePreloadedPT()
    commonPreconditions:RestoreFile(preloadedPT)
end

local function rai_appIDNullPermissions()
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
            appID = "0000001"
        })
        common.getMobileSession():ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
        :Do(function()
            local corId = common.getMobileSession():SendRPC("UnregisterAppInterface", { })

            common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "DISALLOWED" })
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Back-up PreloadedPT", backupPreloadedPT)
runner.Step("Preloaded update", updatePreloadedPT)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)

runner.Title("Test")
runner.Step("Application registered with appName which not Listed In NickNames DISALLOWED", rai_appIDNullPermissions)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore PreloadedPT", restorePreloadedPT)
