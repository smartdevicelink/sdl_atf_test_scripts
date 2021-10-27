---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3788
---------------------------------------------------------------------------------------------------
-- Description: Check SDL assigns RC permissions for the App in case:
-- - initially app has registered with 'MEDIA' appHMIType
-- - appHMIType is changed to 'REMOTE_CONTROL' within PTU
--
-- In case:
-- 1. App is registered with 'MEDIA' appHMIType
-- 2. PTU is performed with 'REMOTE_CONTROL' appHMIType for App
-- 3. App is activated
-- 4. App sends valid SetInteriorVehicleData request
-- SDL does:
-- - allow App's remote-control RPCs (success:true, "SUCCESS")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local rc = require('user_modules/sequences/remote_control')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Local Variables ]]
local appSessionId1 = 1
local moduleType = "RADIO"

--[[ Local Functions ]]
local function PTUfunc(tbl)
	local appId1 = config.application1.registerAppInterfaceParams.fullAppID
	tbl.policy_table.app_policies[appId1].AppHMIType = { "REMOTE_CONTROL" }
	tbl.policy_table.app_policies[appId1].moduleType = { moduleType }
	tbl.policy_table.app_policies[appId1].groups = { "Base-4", "RemoteControl" }
end

local function rpcAllowed(pModuleType, pAppId, pRpc)
  local moduleData = rc.predefined.getSettableModuleControlData(pModuleType)
  rc.rc.rpcSuccess(pModuleType, moduleData.moduleId, pAppId, pRpc, moduleData, false)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", actions.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", rc.rc.start)
runner.Step("RAI", actions.registerApp, { appSessionId1 })
runner.Step("PTU", actions.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", actions.activateApp, { appSessionId1 })

runner.Title("Test")
runner.Step("SetInteriorVehicleData SUCCESS", rpcAllowed,
	{ moduleType, appSessionId1, "SetInteriorVehicleData", "SUCCESS" })

runner.Title("Postconditions")
runner.Step("Stop SDL", actions.postconditions)
