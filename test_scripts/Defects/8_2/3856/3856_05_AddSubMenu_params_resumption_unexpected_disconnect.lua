---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3856
---------------------------------------------------------------------------------------------------
-- Description: SDL resumes AddSubMenu with mandatory and one optional parameters after unexpected disconnect
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
-- 3. Mobile requests AddSubMenu RPC with mandatory and one optional parameters
-- 4. Unexpected disconnect is performed
-- 5. Mobile app is registered with actual hashId
-- SDL does:
--  - request UI.AddSubMenu with mandatory and one optional parameters during data resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/8_2/3856/3856_common')

--[[ Scenario ]]
for param, value in common.spairs(common.reqAddSubMenuParams2) do
  if param ~= "menuID" and param ~= "menuName" then
    common.Title("AddSubMenu with mandatory params and '" .. param .. "' parameter")
    local reqParams = common.getSubMenuReqParams(param, value)
    common.Title("Preconditions")
    common.Step("Clean environment", common.preconditions)
    common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
    common.Step("RAI", common.registerApp)
    common.Step("Send window capabilities", common.sendWindowCapabilities)
    common.Step("PutFile", common.putFile)
    common.Step("Activate App", common.activateApp)
    common.Step("AddSubMenu 1", common.addSubMenu, { common.reqAddSubMenuParams1 })
    common.Step("AddSubMenu 2", common.addSubMenu, { reqParams })

    common.Title("Test")
    common.Step("Unexpected disconnect", common.unexpectedDisconnect)
    common.Step("Connect mobile", common.connectMobile)
    common.Step("RAI with resumption", common.registerAppResumption,
      { common.expectTwoSubMenus, reqParams })

    common.Title("Postconditions")
    common.Step("Stop SDL", common.postconditions)
  end
end
