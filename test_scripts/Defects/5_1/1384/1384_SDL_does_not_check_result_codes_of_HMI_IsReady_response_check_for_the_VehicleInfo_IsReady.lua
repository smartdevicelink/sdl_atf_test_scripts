---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1384
-- Description: SDL doesn't check result codes of HMI IsReady response
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) SDL receives VehicleInfo.IsReady (error_result_code, available=true) from the HMI
-- 3) App is registered and activated
-- In case:
-- 1) App requests GetVehicleData and SubscribeVehicleData RPCs
-- Expected result:
-- 1) SDL respond with 'UNSUPPORTED_RESOURCE, success:false,' + 'info: VehicleInfo is not supported by system'
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

--[[ Local Variables ]]

--[[ Local Functions ]]
local function getHMIValues()
  local params = hmi_values.getDefaultHMITable()
  params.VehicleInfo = nil
  return params
end

local function updatePreloadedPT(pGroups)
  local pt = common.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  pt.policy_table.app_policies[common.app.getParams().fullAppID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[common.app.getParams().fullAppID].groups = { "Base-4", "Location-1" }
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = pGroups
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  common.sdl.setPreloadedPT(pt)
end

local function start (pHMIvalues)
  common.start(pHMIvalues)
  common.getHMIConnection():ExpectRequest("VehicleInfo.IsReady")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "REJECTED", { available = true })
  end)
end

local function sendRPC(pRPC)
  local cid = common.getMobileSession():SendRPC(pRPC, { gps = true })
  common.getMobileSession():ExpectResponse(cid,
  { success = false, resultCode = "UNSUPPORTED_RESOURCE", info = "VehicleInfo is not supported by system" })
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update local PT", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", start, { getHMIValues() })
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Sends GetVehicleData", sendRPC, { "GetVehicleData" })
runner.Step("Sends SubscribeVehicleData", sendRPC, { "SubscribeVehicleData" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
