---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1894
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
  common.getMobileSession():ExpectControlMessage(serviceId, {
    frameInfo = common.frameInfo.START_SERVICE_NACK,
    encryption = false
  })
  common.getMobileSession():ExpectHandshakeMessage()
  :Times(0)

  local function expNotificationFunc()
    common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
      { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
    :Times(3)
  end

  common.policyTableUpdate(ptUpdate, expNotificationFunc)
  common.delayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set ForceProtectedService OFF", common.setForceProtectedServiceParam, { "Non" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate without certificate", common.policyTableUpdate, { ptUpdate })
runner.Step("StartService Secured, PTU started, NACK, no Handshake", startServiceSecured)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
