---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Application is registered with PROJECTION appHMIType
-- 2) and starts secured video services
-- SDL must:
-- 1) Start services successful
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/PROJECTION/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appHMIType = "PROJECTION"

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appName = "server"
config.application1.registerAppInterfaceParams.appID = "SPT"
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }
config.defaultProtocolVersion = 3

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  local filePath = "./files/Security/client_credential.pem"
  local crt = common.readFile(filePath)
  pTbl.policy_table.module_config.certificate = crt
  pTbl.policy_table.app_policies[common.getAppID()].AppHMIType = { appHMIType }
end

local function startServiceSecured(pData, serviceId)
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, pData)
  local handshakeOccurences = 0
  if pData.encryption == true then handshakeOccurences = 1 end
  common.getMobileSession():ExpectHandshakeMessage()
  :Times(handshakeOccurences)
  common.delayedExp()
end

--[[ Scenario ]]
runner.Title("SDL MUST BE CONFIGURED FOR SECURITY")
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set ForceProtectedService OFF", common.setForceProtectedServiceParam, { "Non" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate with certificate", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Start secured video service", startServiceSecured,
	{ { frameInfo = common.frameInfo.START_SERVICE_ACK, encryption = true }, 11 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
