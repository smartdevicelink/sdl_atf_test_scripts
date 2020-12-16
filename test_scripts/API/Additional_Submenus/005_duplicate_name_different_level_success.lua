---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0148-template-additional-submenus.md#backwards-compatibility
-- Description: Tests sending a parentID param in a AddSubMenu request
-- In case:
-- 1) Mobile application is set to appropriate HMI level and System Context MENU, MAIN
-- 2) Mobile application sends AddSubMenu SubMenu with menuID = 1
-- 3) Mobile sends additional AddSubMenu requests where a nested submenu has the same menu name as its parent menu
-- SDL does:
-- 1) Sends AddSubMenu requests to HMI with parentID in menu params
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Additional_Submenus/additional_submenus_common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local menuIDs = { 1, 99, 101 }
local mobileAddSubMenuRequestParams = {
    common.reqParams.AddSubMenu.mob,
    {
        menuID = menuIDs[2], 
        menuName = "SubMenu2",
        parentID = menuIDs[1]
    },
    {
        menuID = menuIDs[3], 
        menuName = "SubMenu2",
        parentID = menuIDs[2]
    }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)
for i, _ in ipairs(mobileAddSubMenuRequestParams) do
    runner.Step("Add submenu", common.addSubMenu, { mobileAddSubMenuRequestParams[i] })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
