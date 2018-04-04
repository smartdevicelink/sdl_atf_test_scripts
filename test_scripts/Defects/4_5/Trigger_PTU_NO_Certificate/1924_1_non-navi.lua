---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1924
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/4_5/Trigger_PTU_NO_Certificate/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local serviceId = 7
local appHMIType = "DEFAULT"

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }

--[[ Local Functions ]]
local function ptUpdate(pTbl)
	pTbl.policy_table.module_config.certificate = nil
end

local function startServiceSecured()
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, { })
  :Times(0)

  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(2)
  common.getHMIConnection():ExpectRequest("BasicCommunication.PolicyUpdate")

  common.delayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate without certificate", common.policyTableUpdate, { ptUpdate })

runner.Title("Test")

runner.Step("StartService Secured, PTU started, No ACK/NACK", startServiceSecured)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
