---------------------------------------------------------------------------------------------------
-- Description:
-- In case:
-- 1) Mobile application is registered with 5.x rpc spec version
-- 2) Mobile application is added SubMenu with menuID  = 5
-- 3) Mobile sends ShowAppMenu request with menuID = 5 parameter to SDL
-- SDL does:
-- 1) Sends INVALID_DATA with info string saying the RPC is not available for 5.x
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ShowAppMenu/commonShowAppMenu')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "PROJECTION" }
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
local menuID = 5

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)
runner.Step("Add menu", common.addSubMenu, { menuID })
runner.Step("Send show app menu, HMI SystemContext MAIN", common.showAppMenuUnsuccess, { menuID, "INVALID_DATA", true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
