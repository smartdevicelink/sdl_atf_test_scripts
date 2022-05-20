---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3856
---------------------------------------------------------------------------------------------------
-- Description: SDL resumes AddCommand with all parameters after ignition off
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
-- 3. Mobile requests AddCommand RPC with all parameters
-- 4. Ignition OFF and ON are performed
-- 5. Mobile app is registered with actual hashId
-- SDL does:
--  - request UI.AddCommand and VR.AddCommand with all parameters during data resumption
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
common.Step("AddSubMenu", common.addSubMenu, { common.reqAddSubMenuParams1 })
common.Step("AddCommand", common.addCommand, { common.reqAddCommandParams })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI with resumption", common.registerAppResumption,
  { common.expectSubMenuCommand, common.reqAddCommandParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
