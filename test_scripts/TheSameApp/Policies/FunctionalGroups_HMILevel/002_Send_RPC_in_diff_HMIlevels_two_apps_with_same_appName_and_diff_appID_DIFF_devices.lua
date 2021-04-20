---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- Check of sending RPC on different HMI levels by two mobile applications having the same appIDs and
-- same appNames from different mobile deviсes.
--
-- Preconditions:
-- 1) Create new custom functional group TestGroup_1 containing RPCs: AddCommand (FULL),
--    addSubMenu (BACKGROUND, LIMITED) and SendLocation(NONE);
-- 2) Set TestGroup_1 for app1 having appId = 1
-- 3) Create new custom functional group TestGroup_1 containing another set of RPCs: SendLocation (FULL),
--    addSubMenu (BACKGROUND, LIMITED) and AddCommand(NONE);
-- 4) Set TestGroup_2 for app2 having appId = 2
-- 5) SDL and HMI are started
-- 6) Mobile №1 and №2 are connected to SDL
-- 7) Mobile №1 and №2 are registered successfully
--
-- Steps:
-- 1) Mobile №1 sent SendLocation RPC
--   Check:
--    SDL resends SendLocation RPC to HMI for Mobile №1 app1
-- 2) Mobile №1 sent AddCommand RPC
--   Check:
--    SDL sends response RPC( resultCode = "DISALLOWED" ) to Mobile №1
-- 3) Activate Mobile №1 app1 - in FULL mode now
-- 4) Mobile №1 sent AddCommand RPC
--   Check:
--    SDL resends AddCommand RPC to HMI for Mobile №1 app1
-- 5) Mobile №1 sent SendLocation RPC
--   Check:
--    SDL sends response RPC( resultCode = "DISALLOWED" ) to Mobile №1
-- 6) Mobile №2 sent AddCommand RPC
--   Check:
--    SDL resends AddCommand RPC to HMI for Mobile №2 app1
-- 7) Mobile №2 sent SendLocation RPC
--   Check:
--    SDL sends response RPC( resultCode = "DISALLOWED" ) to Mobile №2
-- 8) Activate Mobile №2 app2 - in FULL mode now
-- 9) Mobile №1 sent addSubMenu RPC
--   Check:
--    SDL resends addSubMenu RPC to HMI for Mobile №1 app1
-- 10) Mobile №1 sent SendLocation RPC
--   Check:
--    SDL sends response RPC( resultCode = "DISALLOWED" ) to Mobile №1
-- 11) Mobile №2 sent SendLocation RPC
--   Check:
--    SDL resends SendLocation RPC to HMI for Mobile №2 app2
-- 12) Mobile №2 sent AddCommand RPC
--   Check:
--    SDL sends response RPC( resultCode = "DISALLOWED" ) to Mobile №2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = { appName = "Test Application", appID = "0001",  fullAppID = "0000001" },
  [2] = { appName = "Test Application", appID = "00022", fullAppID = "00000022" }
}

local TestGroup_1 = {
  rpcs = {
    AddCommand   = { hmi_levels = { "FULL" }},
    AddSubMenu   = { hmi_levels = { "BACKGROUND", "LIMITED" }},
    SendLocation = { hmi_levels = { "NONE" }}
  }
}
local TestGroup_2 = {
  rpcs = {
    AddCommand   = { hmi_levels = { "NONE" }},
    AddSubMenu   = { hmi_levels = { "BACKGROUND", "LIMITED" }},
    SendLocation = { hmi_levels = { "FULL" }}
  }
}
local locationParams      = { locationName = "Location Name", longitudeDegrees = 1.2, latitudeDegrees = 2.2 }
local addCommandParams    = { cmdID  = 111, menuParams = { menuName = "Play_Stop" } }
local addSubMenuParams    = { menuID = 333, menuName   = "Check" }
local reqAddSubmenuParams = { menuID = 333, menuParams = { menuName = "Testing" } }

--[[ Local Functions ]]
local function modificationOfPreloadedPT(pPolicyTable)
  common.createNewGroup( appParams[1].fullAppID, "TestGroup_1", TestGroup_1, pPolicyTable)
  common.createNewGroup( appParams[2].fullAppID, "TestGroup_2", TestGroup_2, pPolicyTable)
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modificationOfPreloadedPT})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, { 1, appParams[1], 1 })
runner.Step("Register App2 from device 2", common.registerAppEx, { 2, appParams[2], 2 })

runner.Title("Test")
runner.Step("App1 sends 'SendLocation' RPC from Mobile 1, SUCCESS",    common.sendRPCPositive,
              { 1, "Navigation.", "SendLocation", locationParams })
runner.Step("App1 sends 'AddCommand' RPC from Mobile 1, DISALLOWED",   common.sendRPCNegative,
              { 1, "AddCommand", addCommandParams })

runner.Step("Activate App 1", common.app.activate, { 1 })
runner.Step("App1 sends 'AddCommand' RPC from Mobile 1, SUCCESS",      common.sendRPCPositive,
              { 1, "UI.", "AddCommand", addCommandParams })
runner.Step("App1 sends 'SendLocation' RPC from Mobile 1, DISALLOWED", common.sendRPCNegative,
              { 1, "SendLocation", locationParams })

runner.Step("App2 sends 'AddCommand' RPC from Mobile 2, SUCCESS",      common.sendRPCPositive,
              { 2, "UI.", "AddCommand", addCommandParams })
runner.Step("App2 sends 'SendLocation' RPC from Mobile 2, DISALLOWED", common.sendRPCNegative,
              { 2, "SendLocation", locationParams })

runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("App1 sends 'AddSubMenu' RPC from Mobile 1, SUCCESS",      common.sendRPCPositive,
              { 1, "UI.", "AddSubMenu", addSubMenuParams, reqAddSubmenuParams})
runner.Step("App1 sends 'SendLocation' RPC from Mobile 1, DISALLOWED", common.sendRPCNegative,
              { 1, "SendLocation", locationParams })
runner.Step("App2 sends 'SendLocation' RPC from Mobile 2, SUCCESS",    common.sendRPCPositive,
              { 2, "Navigation.", "SendLocation", locationParams })
runner.Step("App2 sends 'AddCommand' RPC from Mobile 2, DISALLOWED",   common.sendRPCNegative,
              { 2, "AddCommand", addCommandParams })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
