---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- Send encrypted or unencrypted RPCs in protected and unprotected mode from apps registered on different
-- mobile devices and having same appNames and same appIds
--
-- Preconditions:
-- 1) SDL has up-to-date certificates in Policy Table
-- 2) App_1 is registered from Mobile №1 and RPC service is started in unprotected mode
-- 3) App_2 is registered from Mobile №2 and RPC service is started in unprotected mode
--
-- Steps:
-- 1) App_1 switches RPC service to protected mode:
--   Check:
--    SDL started protected mode successfully for App1.
-- 2) Mobile №1 sends AddCommand RPC in protected mode to SDL
--   Check:
--    SDL responds with  AddCommand secure response (protected) to Mobile №1
-- 3) Mobile №1 sends AddCommand RPC in unprotected mode to SDL
--   Check:
--    SDL responds with  AddCommand response (unprotected) to Mobile №1
-- 4) Mobile №2 sends AddCommand RPC in unprotected mode to SDL
--   Check:
--    SDL responds with AddCommand response (unprotected) to Mobile №2
-- 5) App_2 switches RPC service to protected mode:
--   Check:
--    SDL started protected mode successfully for App2.
-- 6) Mobile №2 sends AddCommand RPC in protected mode to SDL
--   Check:
--    SDL responds with  AddCommand secure response (protected) to Mobile №2
-- 7) Mobile №2 sends AddCommand RPC in unprotected mode to SDL
--   Check:
--    SDL responds with  AddCommand response (unprotected) to Mobile №2
-- 8) Mobile №1 sends AddCommand RPC in protected mode to SDL
--   Check:
--    SDL responds with  AddCommand secure response (protected) to Mobile №1
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/Security/commonSecurity')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = { appName = "server", appID = "0001", fullAppID = "SPT" },
  [2] = { appName = "server", appID = "0001", fullAppID = "SPT" }
}

local addCommandParams = {
  { cmdID  = 001, menuParams = {menuName = "menu_1"}},
  { cmdID  = 002, menuParams = {menuName = "menu_2"}},
  { cmdID  = 003, menuParams = {menuName = "menu_3"}}
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set DTLS protocol in SDL", common.setSDLIniParameter, { "Protocol", "DTLSv1.0" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App2 from device 2", common.registerAppEx, {2, appParams[2], 2, true})
runner.Step("Policy Table Update Certificate", common.policyTableUpdate, { common.ptUpdate })
runner.Step("Activate App 1", common.activateApp, { 1 })

runner.Title("Test")
runner.Step ("Start RPC Service protected for App 1", common.startServiceProtected, { 7, 1 })
runner.Step ("Mobile 1 sends secure RPC in protected mode",   common.protectedModeRPC, { 1, addCommandParams[1] })
runner.Step ("Mobile 1 sends insecure RPC in protected mode", common.nonProtectedRPC,  { 1, addCommandParams[2] })

runner.Step ("Activate App 2", common.activateApp, { 2 })
runner.Step ("Mobile 2 sends insecure RPC in NON protected mode", common.nonProtectedRPC,{2, addCommandParams[1] })

runner.Step ("Start RPC Service protected for App 2", common.startServiceProtected, { 7, 2 })
runner.Step ("Mobile 2 sends secure RPC in protected mode",  common.protectedModeRPC, { 2, addCommandParams[2] })
runner.Step ("Mobile 2 sends insecure RPC in protected mode", common.nonProtectedRPC, { 2, addCommandParams[3] })
runner.Step ("Mobile 1 sends secure RPC in protected mode",  common.protectedModeRPC, { 1, addCommandParams[3] })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
