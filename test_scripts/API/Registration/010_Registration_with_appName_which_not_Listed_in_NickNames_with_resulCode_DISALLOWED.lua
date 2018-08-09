---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Application is tries to registere with appName which not listed in nickNames.
-- SDL does:
-- 1) Does not registered the application and returnes DISALLOWED response to the applicatin.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function setNickNameForSpecificApp()
    local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
    local file = io.open(pathToFile, "r")
    local json_data = file:read("*all")
    file:close()
    local json = require("modules/json")
    local data = json.decode(json_data)

    if data.policy_table.functional_groupings["DataConsent-2"] then
      data.policy_table.functional_groupings["DataConsent-2"] = nil
    end
    data.policy_table.app_policies["1234567"] = {
          keep_context = false,
          steal_focus = false,
          priority = "NONE",
          default_hmi = "NONE",
          groups = {"Base-4"},
          nicknames = {"SPT"}
        }
    data = json.encode(data)
    file = io.open(pathToFile, "w")
    file:write(data)
    file:close()
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
