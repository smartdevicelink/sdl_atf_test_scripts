---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1894
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/4_5/Trigger_PTU_NO_Certificate/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local serviceId = 10
local appHMIType = "NAVIGATION"
local startServiceData = {
  frameInfo = common.frameInfo.START_SERVICE_ACK,
  encryption = false
}

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set ForceProtectedService OFF", common.setForceProtectedServiceParam, { "Non" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate without certificate", common.policyTableUpdate, { common.ptUpdateWOcert })
runner.Step("Activate App", common.activateApp)
runner.Step("StartService Secured, PTU without certificate, ACK, encryption=false, no Handshake",
  common.startServiceSecured, { serviceId, startServiceData, common.ptUpdateWOcert })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
