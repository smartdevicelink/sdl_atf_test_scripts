---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Verify that the SDL does not establish WebSocket-Secure connection in case of WS Client Certificate is self signed
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. Create WebSocket-Secure connection
--  a. SDL does not establish WebSocket-Secure connection
---------------------------------------------------------------------------------------------------
--[[ General test configuration ]]
config.defaultMobileAdapterType = "WSS"

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = {{webSocketServerSupport = {"ON"}}}

config.wssCertificateCAPath = "./files/Security/WebEngine/ca-cert.pem"
config.wssCertificateClientPath = "./files/Security/WebEngine/SelfSigned/client-cert.pem"
config.wssPrivateKeyPath = "./files/Security/WebEngine/SelfSigned/client-key.pem"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Add certificates for WS Server in smartDeviceLink.ini file", common.addAllCertInIniFile)
runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.startWOdeviceConnect)

runner.Title("Test")
runner.Step("Connect WebEngine device", common.connectWSSWebEngine)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
