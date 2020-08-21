---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0148-template-additional-submenus.md#backwards-compatibility
-- Description: Tests sending a parentID param in a AddSubMenu request
-- In case:
-- 1) Mobile application is set to appropriate HMI level and System Context MENU, MAIN
-- 2) Mobile application sends 3 AddSubMenu requests where each submenu is nested in the previous submenu
-- 3) Mobile sends 2 Add Command requests to populate the nested submenus
-- 4) Mobile requests to delete a nested submenu
-- SDL does:
-- 1) Sends DeleteSubmenu and DeleteCommand requests for the request submenu and all contents under that submenu
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Additional_Submenus/additional_submenus_common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local menuIDs = {1, 99, 101}
local cmdIDs = {44, 45}
local mobileAddSubMenuRequestParams = {
    common.reqParams.AddSubMenu.mob,
    {
        menuID = menuIDs[2], 
        menuName = "SubMenu2",
        parentID = menuIDs[1]
    },
    {
        menuID = menuIDs[3], 
        menuName = "SubMenu3",
        parentID = menuIDs[2]
    }
}

local mobileAddCommandRequestParams = {
    {
        cmdID = cmdIDs[1],
        menuParams = {
            parentID = mobileAddSubMenuRequestParams[2].menuID,
            menuName = "Add Command 1"
        }
    },
    {
        cmdID = cmdIDs[2],
        menuParams = {
            parentID = mobileAddSubMenuRequestParams[3].menuID,
            menuName = "Add Command 2"
        }
    }
}

local mobileDeleteSubMenuRequestParams = {
    menuID = menuIDs[2]
}

local hmiDeleteSubMenuRequestParams = {
    {
        menuID = mobileAddSubMenuRequestParams[3].menuID
    },
    {
        menuID = mobileAddSubMenuRequestParams[2].menuID
    }
}

local hmiDeleteCommandRequestParams = {
    {
        cmdID = mobileAddCommandRequestParams[1].cmdID
    },
    {
        cmdID = mobileAddCommandRequestParams[2].cmdID
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
    runner.Step("Add additional submenu", common.addSubMenu, { mobileAddSubMenuRequestParams[i] })
end
for i, _ in ipairs(mobileAddCommandRequestParams) do
  runner.Step("Add Commands to nested submenus", common.addCommand, {  mobileAddCommandRequestParams[i] })
end
runner.Step("Send DeleteSubMenu", common.DeleteSubMenu, {mobileDeleteSubMenuRequestParams, hmiDeleteCommandRequestParams, hmiDeleteSubMenuRequestParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
