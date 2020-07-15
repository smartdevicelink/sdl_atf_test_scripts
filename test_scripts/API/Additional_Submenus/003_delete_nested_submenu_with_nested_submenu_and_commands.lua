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
local common = require('test_scripts/Smoke/commonSmoke')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion = {
    majorVersion = 7,
    minorVersion = 0
}

--[[ Local Variables ]]
local mobileAddSubMenuRequestParams = {
    subMenu2 = {
        menuID = 99, 
        menuName = "SubMenu2",
        parentID = 1
    },
    submenu3 = {
        menuID = 101, 
        menuName = "SubMenu3",
        parentID = 99
    }
}

local mobileAddCommandRequestParans = {
    addCommand1 = {
        cmdID = 44,
        menuParams = {
            parentID = 99,
            menuName = "SubMenu2"
        }
    },
    addCommand2 = {
        cmdID = 45,
        menuParams = {
            parentID = 101,
            menuName = "SubMenu3"
        }
    }
}

local mobileDeleteSubMenuRequestParams = {
    menuID = 99
}

local hmiAddSubMenuRequestParams = {
    subMenu2 = {
        menuID = 99, 
        menuParams = { 
            menuName = "SubMenu2",
            parentID = 1 
        }
    },
    subMenu3 = {
        menuID = 101, 
        menuParams = { 
            menuName = "SubMenu3",
            parentID = 99 
        }
    }
}

local hmiAddCommandRequestParams = {
    addCommand1 = {
        cmdID = 44,
        menuParams = {
            parentID = 99,
            menuName = "SubMenu2"
        }
    },
    addCommand2 = {
        cmdID = 45,
        menuParams = {
            parentID = 101,
            menuName = "SubMenu3"
        }
    }
}

local hmiDeleteSubMenuRequestParams = {
    deleteSubMenu2 = {
        menuID = 101
    },
    deleteSubMenu3 = {
        menuID = 99
    }
}

local hmiDeleteCommandRequestParams = {
    deleteCommand1 = {
        cmdID = 44
    },
    deleteCommand2 = {
        cmdID = 45
    }
}
 
local function AddNestedSubMenus(key)
    local cid = common.getMobileSession():SendRPC("AddSubMenu", mobileAddSubMenuRequestParams[key])
    common.getHMIConnection():ExpectRequest("UI.AddSubMenu", hmiAddSubMenuRequestParams[key])
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function AddNestedCommands(key)
    local cid = common.getMobileSession():SendRPC("AddCommand", mobileAddCommandRequestParans[key])
    common.getHMIConnection():ExpectRequest("UI.AddCommand", hmiAddCommandRequestParams[key])
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession():ExpectNotification("OnHashChange")
    :Do(function(_, data)
        common.hashId = data.payload.hashID
    end)
end

local function DeleteSubMenu()
    local cid = common.getMobileSession():SendRPC("DeleteSubMenu", mobileDeleteSubMenuRequestParams)

    common.getHMIConnection():ExpectRequest("UI.DeleteCommand", 
        hmiDeleteCommandRequestParams[deleteCommand1], 
        hmiDeleteCommandRequestParams[deleteCommand2]
    )
    :Times(2)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    common.getHMIConnection():ExpectRequest("UI.DeleteSubMenu", 
        hmiDeleteSubMenuRequestParams[deleteSubMenu2],
        hmiDeleteSubMenuRequestParams[deleteSubMenu3]
    )
    :Times(2)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)
runner.Step("Add menu", common.addSubMenu)
for key, params in pairs(mobileAddSubMenuRequestParams) do
    runner.Step("Add additional submenu", AddNestedSubMenus, { key })
end
for key, params in pairs(mobileAddCommandRequestParans) do
  runner.Step("Add Commands to nested submenus", AddNestedCommands, { key })
end
runner.Step("Send DeleteSubMenu", DeleteSubMenu)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
