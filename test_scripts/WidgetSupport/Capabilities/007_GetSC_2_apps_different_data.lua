---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL provides appropriate display capabilities in `GetSystemCapability` response
-- in case two Apps have different display capabilities
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) 2 Apps are registered
-- 3) HMI provides different display capabilities data through `OnSystemCapabilityUpdated` notification to each App
-- Steps:
-- 1) Each App sends `GetSystemCapability` request to SDL for DISPLAYS capabilities
-- SDL does:
--  - proceed with request successfully
--  - provide up-to-date corresponding DISPLAYS data to each App in response
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local appParams = {}
for i = 1, 2 do
  appParams[i] = common.getOnSystemCapabilityParams(i)
  local disCap = appParams[i].systemCapability.displayCapabilities[1]
  disCap.windowCapabilities[1].windowID = i
end

--[[ Local Functions ]]
local function sendOnSCU(pAppId, pParams)
  local paramsToSDL = common.cloneTable(pParams)
  paramsToSDL.appID = common.getHMIAppId(pAppId)
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", paramsToSDL)
  common.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated", pParams)
end

local function sendGetSC(pAppId, pParams)
  local cid = common.getMobileSession(pAppId):SendRPC("GetSystemCapability", { systemCapabilityType = "DISPLAYS" })
  common.getMobileSession(pAppId):ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    systemCapability = pParams.systemCapability
  })
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App 1 registration", common.registerAppWOPTU, { 1 })
common.Step("App 2 registration", common.registerAppWOPTU, { 2 })
common.Step("SDL transfers OnSCU notification for 1st app", sendOnSCU, { 1, appParams[1] })
common.Step("SDL transfers OnSCU notification for 2nd app", sendOnSCU, { 2, appParams[2] })

common.Title("Test")
common.Step("App 1 sends GetSC RPC for DISPLAYS", sendGetSC, { 1, appParams[1] })
common.Step("App 2 sends GetSC RPC for DISPLAYS", sendGetSC, { 2, appParams[2] })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
