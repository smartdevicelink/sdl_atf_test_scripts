---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1384
-- Description: SDL doesn't check result codes of HMI IsReady response
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) SDL receives Navigation.IsReady (error_result_code, available=true) from the HMI
-- 3) App is registered and activated
-- In case:
-- 1) App requests SendLocation RPC
-- Expected result:
-- 1) SDL responds with 'UNSUPPORTED_RESOURCE, success:false,' + 'info: Navigation is not supported by system'
-- Actual result:
-- SDL responds with GENERIC_ERROR, success=false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local hmi_values = require("user_modules/hmi_values")
local utils = require('user_modules/utils')
local json = require("modules/json")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getHMIValues()
  local params = hmi_values.getDefaultHMITable()
  params.Navigation = nil
  return params
end

local function start (pHMIvalues)
  common.start(pHMIvalues)
  common.getHMIConnection():ExpectRequest("Navigation.IsReady")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "REJECTED", { available = true })
  end)
end

local function updatePreloadedPT(pGroups, pAppId)
  local pt = common.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  pt.policy_table.app_policies[common.app.getParams(pAppId).fullAppID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[common.app.getParams(pAppId).fullAppID].groups = { "Base-4", "SendLocation" }
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = pGroups
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  common.sdl.setPreloadedPT(pt)
end

local function sendSendLocation()
  local requestParams = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1
  }
  local cid = common.getMobileSession():SendRPC("SendLocation", requestParams)
  common.getMobileSession():ExpectResponse(cid,
  { success = false, resultCode = "UNSUPPORTED_RESOURCE", info = "Navigation is not supported by system" })
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update local PT", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", start, { getHMIValues() })
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Sends SendLocation", sendSendLocation)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
