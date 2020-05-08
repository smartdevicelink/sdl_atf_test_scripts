---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL does not send CreateWindow request to HMI during RAI app
--
-- Preconditions:
-- 1) SDL and HMI are started
-- Steps:
-- 1) App sends RAI request to SDL
-- SDL does:
--  - send BC.OnAppRegistered notification to HMI
--  - not send `CreateWindow` request to HMI
--  - send RAI response with success: true resultCode: "SUCCESS" to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Functions ]]
local function rai_WithoutCreateWindow()
  common.getMobileSession():StartService(7)
  :Do(function()
    local corId = common.getMobileSession():SendRPC("RegisterAppInterface", common.getConfigAppParams())
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")

    common.getHMIConnection():ExpectRequest("UI.CreateWindow")
    :Times(0)

    common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  end)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

common.Title("Test")
common.Step("SDL does not send CreateWindow request to HMI during RAI", rai_WithoutCreateWindow)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
