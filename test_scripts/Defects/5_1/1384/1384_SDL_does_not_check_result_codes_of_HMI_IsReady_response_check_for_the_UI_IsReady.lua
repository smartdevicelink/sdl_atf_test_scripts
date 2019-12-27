---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1384
-- Description: SDL doesn't check result codes of HMI IsReady response
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) SDL receives UI.IsReady (error_result_code, available=true) from the HMI
-- 3) App is registered and activated
-- In case:
-- 1) App requests AddCommand with the both vrCommands and menuParams
-- Expected result:
-- 1) SDL transfers only VR.AddCommand request to the HMI and
--    respond with 'UNSUPPORTED_RESOURCE, success:true,' + 'info: UI is not supported by system'
-- Actual result:
-- SDL responds with GENERIC_ERROR, success=false
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
  params.UI = nil
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

local responseUiParams = {
  cmdID = requestParams.cmdID,
  menuParams = requestParams.menuParams
}

local responseVrParams = {
  cmdID = requestParams.cmdID,
  type = "Command",
  vrCommands = requestParams.vrCommands
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
  responseVrParams = responseVrParams
}
--[[ Local Functions ]]
local function start (pHMIvalues)
  common.start(pHMIvalues)
  common.getHMIConnection():ExpectRequest("UI.IsReady")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "REJECTED", { available = true })
  end)
end

local function sendAddCommand(params)
  local cid = common.getMobileSession():SendRPC("AddCommand", params.requestParams)
  common.getHMIConnection():ExpectRequest("VR.AddCommand", params.responseVrParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getMobileSession():ExpectResponse(cid,
  { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "UI is not supported by system" })
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", start, { getHMIValues() })
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Sends AddCommand", sendAddCommand, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
