---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/980
-- Description: [APIs] AlertManeuver: SDL responds GENERIC_ERROR instead of INVALID_DATA when soft button has
-- Type is Image or Both and Text is whitespace or \t or \n or empty
-- Precondition:
-- 1) AlertManeuver is allowed by policy for "default" group.
-- 2) SDL and HMI are started.
-- 3) App is connected and at the FULL.
-- In case:
-- 1) Send AlertManeuver sure that soft button has Type is Image or Both and Text is whitespace or \t or \n or empty.
-- Expected result:
-- 1) SDL must respond with resultCode "INVALID_DATA" and success:"false".
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local json = require("modules/json")

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
   text_Whitespace = {
    ttsChunks = { { text = "FirstAlert", type = "TEXT" } },
    softButtons = { { type = "TEXT", text = "        ", softButtonID = 821 } } -- soft button has Text is whitespace
  },
  text_empty = {
    ttsChunks = { { text = "FirstAlert", type = "TEXT" } },
    softButtons = { { type = "TEXT", text = "", softButtonID = 821 } } -- soft button has Text is empty
  },
  text_lineBreak = {
    ttsChunks = { { text = "FirstAlert", type = "TEXT" } },
    softButtons = { { type = "TEXT", text = "Close\n", softButtonID = 821 } } -- soft button has Text is \n
  }
}

--[[ Local Functions ]]
local function updatePreloadedPT()
  local pt = common.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  pt.policy_table.app_policies[common.app.getParams().fullAppID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[common.app.getParams().fullAppID].groups = { "Base-4", "Navigation-1" }
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  common.sdl.setPreloadedPT(pt)
end

local function sendAlertManeuver(pParams)
  local corId = common.getMobileSession():SendRPC("AlertManeuver", pParams)
common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update local PT", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for k, v in pairs(requestParams) do
  runner.Step("App sends AlertManeuver with soft button has " .. k, sendAlertManeuver, {v})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
