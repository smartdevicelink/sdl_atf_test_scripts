---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0148-template-additional-submenus.md#backwards-compatibility
-- Description: Tests sending a parentID param in a AddSubMenu request
-- In case:
-- 1) Mobile application is set to appropriate HMI level and System Context MENU, MAIN
-- 2) Mobile application sends 3 AddSubMenu requests where each submenu is nested in the previous submenu
-- 3) Mobile sends 2 Add Command requests to populate the nested submenus
-- 4) Mobile requests to delete the top level submenu
-- SDL does:
-- 1) Sends DeleteSubmenu and DeleteCommand requests for the requested submenu and all contents under that submenu
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Additional_Submenus/additional_submenus_common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mobileAddSubMenuRequestParams = {
    {
        menuID = 99, 
        menuName = "SubMenu2",
        parentID = 1
    },
    {
        menuID = 101, 
        menuName = "SubMenu3",
        parentID = 99
    }
}

local mobileAddCommandRequestParans = {
    {
        cmdID = 44,
        menuParams = {
            parentID = mobileAddSubMenuRequestParams[1].menuID,
            menuName = "Add Command 1"
        }
    },
    {
        cmdID = 45,
        menuParams = {
            parentID = mobileAddSubMenuRequestParams[2].menuID,
            menuName = "Add Command 2"
        }
    }
}

local mobileDeleteSubMenuRequestParams = {
    menuID = 1
}

local hmiAddSubMenuRequestParams = {
    {
        menuID = mobileAddSubMenuRequestParams[1].menuID, 
        menuParams = { 
            menuName = mobileAddSubMenuRequestParams[1].menuName,
            parentID = mobileAddSubMenuRequestParams[1].parentID 
        }
    },
    {
        menuID = mobileAddSubMenuRequestParams[2].menuID, 
        menuParams = { 
            menuName = mobileAddSubMenuRequestParams[2].menuName,
            parentID = mobileAddSubMenuRequestParams[2].parentID 
        }
    }
}

local hmiAddCommandRequestParams = {
    {
        cmdID = mobileAddCommandRequestParans[1].cmdID,
        menuParams = {
            parentID = mobileAddCommandRequestParans[1].menuParams.parentID,
            menuName = mobileAddCommandRequestParans[1].menuParams.menuName
        }
    },
    {
        cmdID = mobileAddCommandRequestParans[2].cmdID,
        menuParams = {
            parentID = mobileAddCommandRequestParans[2].menuParams.parentID,
            menuName = mobileAddCommandRequestParans[2].menuParams.menuName
        }
    }
}

local hmiDeleteSubMenuRequestParams = {
    {
        menuID = mobileAddSubMenuRequestParams[1].menuID
    },
    {
        menuID = mobileAddSubMenuRequestParams[2].menuID
    },
    {
        menuID = mobileDeleteSubMenuRequestParams.menuID
    }
}

local hmiDeleteCommandRequestParams = {
    {
        cmdID = mobileAddCommandRequestParans[1].cmdID
    },
    {
        cmdID = mobileAddCommandRequestParans[2].cmdID
    }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)
runner.Step("Add menu", common.addSubMenu)
for i, _ in ipairs(mobileAddSubMenuRequestParams) do
    runner.Step("Add additional submenu", common.AdditionalSubmenu, { mobileAddSubMenuRequestParams[i], hmiAddSubMenuRequestParams[i], true })
end
for i, _ in ipairs(mobileAddCommandRequestParans) do
    runner.Step("Add Commands to nested submenus", common.AddNestedCommands, {  mobileAddCommandRequestParans[i], hmiAddCommandRequestParams[i]})
end
runner.Step("Send DeleteSubMenu", common.DeleteSubMenu, {mobileDeleteSubMenuRequestParams, hmiDeleteCommandRequestParams, hmiDeleteSubMenuRequestParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
