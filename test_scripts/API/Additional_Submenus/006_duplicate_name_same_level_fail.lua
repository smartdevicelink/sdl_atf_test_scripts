---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0148-template-additional-submenus.md#backwards-compatibility
-- Description: Tests sending a parentID param in a AddSubMenu request
-- In case:
-- 1) Mobile application is set to appropriate HMI level and System Context MENU, MAIN
-- 2) Mobile application sends AddSubMenu SubMenu with menuID = 1
-- 3) Mobile sends additional AddSubMenu requests where two submenus at the same level have a duplicate menuName
-- SDL does:
-- 1) Fails the request with result code DUPLICATE_NAME
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Additional_Submenus/additional_submenus_common')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
    common.reqParams.AddSubMenu.mob,
    {
        menuID = 99, 
        menuName = "SubMenu2",
        parentID = 1
    }
}

local duplicateNameRequestParams = {
    menuID = 101, 
    menuName = requestParams[2].menuName,
    parentID = requestParams[2].parentID 
}

local function DuplicateNameMenu()
    local cid = common.getMobileSession():SendRPC("AddSubMenu", duplicateNameRequestParams)
    common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "DUPLICATE_NAME" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)
for i, _ in ipairs(requestParams) do
    runner.Step("Add submenu", common.addSubMenu, { requestParams[i] })
end
runner.Step("Duplicate Name SubMenu", DuplicateNameMenu)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
