---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1925
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/4_5/Trigger_PTU_NO_Certificate/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appHMIType = {
  [1] = "DEFAULT",
  [2] = "DEFAULT"
}

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType[1] }
config.application2.registerAppInterfaceParams.appHMIType = { appHMIType[2] }

--[[ Local Functions ]]
local function ptUpdate(pTbl)
	pTbl.policy_table.module_config.certificate = nil
end

local function expNotificationFunc()
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register " .. appHMIType[1] .. " App", common.registerApp, { 1 })
runner.Step("PTU 1 finished", common.policyTableUpdate, { ptUpdate })

runner.Title("Test")
runner.Step("Register " .. appHMIType[2] .. " App, PTU started", common.registerApp, { 2, expNotificationFunc })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
