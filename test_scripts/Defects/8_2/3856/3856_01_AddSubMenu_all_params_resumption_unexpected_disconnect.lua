---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3856
---------------------------------------------------------------------------------------------------
-- Description: SDL resumes AddSubMenu with all parameters after unexpected disconnect
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
-- 3. Mobile requests AddSubMenu RPC with all parameters
-- 4. Unexpected disconnect is performed
-- 5. Mobile app is registered with actual hashId
-- SDL does:
--  - request UI.AddSubMenu with all parameters during data resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/8_2/3856/3856_common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("Send window capabilities", common.sendWindowCapabilities)
common.Step("Activate App", common.activateApp)
common.Step("PutFile", common.putFile)
common.Step("AddSubMenu 1", common.addSubMenu, { common.reqAddSubMenuParams1 })
common.Step("AddSubMenu 2", common.addSubMenu, { common.reqAddSubMenuParams2 })

common.Title("Test")
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("RAI with resumption", common.registerAppResumption,
  { common.expectTwoSubMenus, common.reqAddSubMenuParams2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
