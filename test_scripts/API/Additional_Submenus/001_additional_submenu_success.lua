---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0148-template-additional-submenus.md#backwards-compatibility
-- Description: Tests sending a parentID param in a AddSubMenu request
-- In case:
-- 1) Mobile application is set to appropriate HMI level and System Context MENU, MAIN
-- 2) Mobile application sends AddSubMenu SubMenu with menuID = 1
-- 3) Mobile sends additional AddSubMenu request with menuID = 99 and parentID = 1
-- SDL does:
-- 1) Sends AddSubMenu requests to HMI with parentID in menu params
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
local requestParams = {
    menuID = 99, 
    menuName = "SubMenu2",
    parentID = 1
}

local hmiRequestParams = {
    menuID = 99, 
    menuParams = { 
        menuName = "SubMenu2",
        parentID = 1 
    }
}
 
local function AdditionalSubmenu()
    local cid = common.getMobileSession():SendRPC("AddSubMenu", requestParams)
    common.getHMIConnection():ExpectRequest("UI.AddSubMenu", hmiRequestParams)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession():ExpectNotification("OnHashChange")
    :Do(function(_, data)
        common.hashId = data.payload.hashID
      end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)
runner.Step("Add menu", common.addSubMenu)
runner.Step("Add additional submenu", AdditionalSubmenu)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
