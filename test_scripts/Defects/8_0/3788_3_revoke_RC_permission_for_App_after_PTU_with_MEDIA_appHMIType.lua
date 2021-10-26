---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3788
---------------------------------------------------------------------------------------------------
-- Description: Check SDL assigns RC permissions for the App in case:
-- - policy table contains an information about app with 'REMOTE_CONTROL' appHMIType
-- - app is registered with 'MEDIA' appHMIType
--
-- In case:
-- 1. App is registered with 'REMOTE_CONTROL' appHMIType
-- 2. PTU is performed with 'MEDIA' appHMIType for App
-- 3. App is activated
-- 4. App sends valid SetInteriorVehicleData request
-- SDL does:
-- - disallow App's remote-control RPCs (success:false, "DISALLOWED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local rc = require('user_modules/sequences/remote_control')
local utils = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local appSessionId1 = 1
local moduleType = "RADIO"

--[[ Local Functions ]]
local function getRCAppConfig(pPt)
  local out = utils.cloneTable(pPt.policy_table.app_policies.default)
  out.moduleType = rc.data.getRcModuleTypes()
  out.groups = { "Base-4", "RemoteControl" }
  out.AppHMIType = { "REMOTE_CONTROL" }
  return out
end

local function preparePreloadedPT()
  local preloadedTable = actions.sdl.getPreloadedPT()
  local appId = actions.app.getParams().fullAppID
  preloadedTable.policy_table.app_policies[appId] = getRCAppConfig(preloadedTable)
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  actions.sdl.setPreloadedPT(preloadedTable)
end

local function PTUfunc(tbl)
	local appId1 = config.application1.registerAppInterfaceParams.fullAppID
	tbl.policy_table.app_policies[appId1].AppHMIType = { "MEDIA" }
	tbl.policy_table.app_policies[appId1].moduleType = utils.json.EMPTY_ARRAY
	tbl.policy_table.app_policies[appId1].groups = { "Base-4", "RemoteControl" }
end

local function rpcDenied(pModuleType, pAppId, pRpc, pResultCode)
  local moduleData = rc.predefined.getSettableModuleControlData(pModuleType)
  rc.rc.rpcReject(pModuleType, moduleData.moduleId, pAppId, pRpc, moduleData, pResultCode)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", actions.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", rc.rc.start)
runner.Step("Update preloaded PT with RC app", preparePreloadedPT)
runner.Step("RAI", actions.registerApp, { appSessionId1 })
runner.Step("PTU", actions.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", actions.activateApp, { appSessionId1 })

runner.Title("Test")
runner.Step("SetInteriorVehicleData DISALLOWED", rpcDenied,
	{ moduleType, appSessionId1, "SetInteriorVehicleData", "DISALLOWED" })

runner.Title("Postconditions")
runner.Step("Stop SDL", actions.postconditions)
