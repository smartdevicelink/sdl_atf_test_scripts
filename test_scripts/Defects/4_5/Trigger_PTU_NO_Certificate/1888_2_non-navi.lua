---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1888
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
config.application1.registerAppInterfaceParams.appName = "server"
config.application1.registerAppInterfaceParams.fullAppID = "SPT"
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.module_config.certificate = nil
end

local function startServiceSecured(pData)
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, pData)

  local handshakeOccurences = 0
  local crt = nil
  if pData.encryption == true then
    handshakeOccurences = 1
    crt = common.readFile("./files/Security/client_credential.pem")
  end
  common.getMobileSession():ExpectHandshakeMessage()
  :Times(handshakeOccurences)

  local function ptUpdateCertificate(pTbl)
    pTbl.policy_table.module_config.certificate = crt
    pTbl.policy_table.app_policies[common.getAppID()].AppHMIType = { appHMIType }
  end

  local function expNotificationFunc()
    common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
      { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
    :Times(3)
  end

  common.policyTableUpdate(ptUpdateCertificate, expNotificationFunc)
  common.delayedExp()
end

local function sendRPCAddCommandSecured()
  local params = {
    cmdID = 1,
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local cid = common.getMobileSession():SendEncryptedRPC("AddCommand", params)
  common.getHMIConnection():ExpectRequest("UI.AddCommand", params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectEncryptedNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set ForceProtectedService OFF", common.setForceProtectedServiceParam, { "Non" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")

runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate wo cert", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Step("StartService Secured, PTU wo cert, NACK, no Handshake", startServiceSecured, { {
    frameInfo = common.frameInfo.START_SERVICE_NACK,
    encryption = false
  }})

runner.Step("StartService Secured, PTU with cert, ACK, Handshake", startServiceSecured, { {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = true
  }})

runner.Step("AddCommand Secured", sendRPCAddCommandSecured)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
