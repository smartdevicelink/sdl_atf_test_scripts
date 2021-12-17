---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/980
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds INVALID_DATA in case soft button has Type(Image or Both)
-- and Text is whitespace or \t or \n or empty
--
-- Precondition:
-- 1) AlertManeuver is allowed by policy
-- 2) SDL, HMI, Mobile session started
-- 3) App is registered and activated
-- In case:
-- 1) App sends AlertManeuver with soft button (type = Image or Both, Text = whitespace or \t or \n or empty)
-- SDL does:
-- 1) Respond with AlertManeuver(success = false, resultCode = "INVALID_DATA") to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  type_BOTH = {
    ttsChunks = { { text = "FirstAlert", type = "TEXT" } },
    softButtons = { { type = "BOTH", text = "Close", softButtonID = 821, } } -- soft button has type is "BOTH"
  },
  type_IMAGE = {
    ttsChunks = { { text = "FirstAlert", type = "TEXT" } },
    softButtons = { { type = "IMAGE", text = "Close", softButtonID = 821, } } -- soft button has type is "Image"
  },
  text_HorizontalTab = {
    ttsChunks = { { text = "FirstAlert", type = "TEXT" } },
    softButtons = { { type = "TEXT", text = "Close\t", softButtonID = 821, } } -- soft button has Text is \t
  },
  text_lineBreak = {
    ttsChunks = { { text = "FirstAlert", type = "TEXT" } },
    softButtons = { { type = "TEXT", text = "Close\n", softButtonID = 821 } } -- soft button has Text is \n
  },
   text_Whitespace = {
    ttsChunks = { { text = "FirstAlert", type = "TEXT" } },
    softButtons = { { type = "TEXT", text = "        ", softButtonID = 821 } } -- soft button has Text is whitespace
  },
  text_empty = {
    ttsChunks = { { text = "FirstAlert", type = "TEXT" } },
    softButtons = { { type = "TEXT", text = "", softButtonID = 821 } } -- soft button has Text is empty
  }
}

--[[ Local Functions ]]
local function updatePreloadedPT()
  local pt = common.sdl.getPreloadedPT()
  local appId = common.app.getParams().fullAppID
  pt.policy_table.app_policies[appId] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[appId].groups = { "Base-4", "Navigation-1" }
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null
  common.sdl.setPreloadedPT(pt)
end

local function sendAlertManeuver(pParams)
  local corId = common.mobile.getSession():SendRPC("AlertManeuver", pParams)
  common.mobile.getSession():ExpectResponse(corId, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for k, v in pairs(requestParams) do
  runner.Step("App sends AlertManeuver with soft button has " .. k, sendAlertManeuver, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)