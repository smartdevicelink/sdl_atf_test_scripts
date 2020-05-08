---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the SetAppProperties request with unknown parameter from HMI
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends the BC.SetAppProperties request with unknown parameter
--  a. SDL cuts off the unknown parameter and process this RPC as assigned
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("SetAppProperties request: with unknown parameter", common.setAppProperties,
  { common.updateDefaultAppProperties("unknownParameter", "unknownParameter") })
common.Step("GetAppProperties request to check set values", common.getAppProperties,
  { common.defaultAppProperties })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
