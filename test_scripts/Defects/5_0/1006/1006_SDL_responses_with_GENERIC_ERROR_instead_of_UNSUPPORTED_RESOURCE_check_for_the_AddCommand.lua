---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1006
-- Description: PoliciesManager must allow all requested params in case "parameters" field is omitted
-- Precondition:
-- 1) SDL and HMI are started.
-- In case:
-- 1) Send any single UI-related RPC , UI interface is not supported by the system
-- 2) SDL receives UI.IsReady (available=false) from HMI
-- Expected result:
-- 1) SDL must respond "UNSUPPORTED_RESOURCE, success=false, info: UI is not supported by system" to mobile app
-- Actual result:
-- SDL responds with GENERIC_ERROR, success=false (logs are in attachment)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local function getHMIValues()
  local params = hmi_values.getDefaultHMITable()
  params.UI.IsReady.params.available = false
  params.UI.GetCapabilities = nil
  params.UI.GetLanguage = nil
  params.UI.GetSupportedLanguages = nil
  return params
end

local requestParams = {
  cmdID = 11,
  menuParams = {
    position = 0,
    menuName ="Commandpositive"
  },
  vrCommands = {
    "VRCommandonepositive",
    "VRCommandonepositivedouble"
  },
  grammarID = 1
}

local responseVrParams = {
  cmdID = requestParams.cmdID,
  type = "Command",
  vrCommands = requestParams.vrCommands
}

local allParams = {
  requestParams = requestParams,
  responseVrParams = responseVrParams
}
--[[ Local Functions ]]
local function sendAddCommand(params)
  local cid = common.getMobileSession():SendRPC("AddCommand", params.requestParams)
  common.getHMIConnection():ExpectRequest("VR.AddCommand", params.responseVrParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getMobileSession():ExpectResponse(cid, {success = true, resultCode = "UNSUPPORTED_RESOURCE"})
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, {getHMIValues()})
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Sends AddCommand", sendAddCommand, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
