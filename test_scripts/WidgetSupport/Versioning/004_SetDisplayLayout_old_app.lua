---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL successfully proceed with "SetDisplayLayout" RPC for old apps (5.0)
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) New app registers with 'syncMsgVersion' = 5.0 and activated
-- Steps:
-- 1) App sends 'SetDisplayLayout' request to SDL
-- SDL does:
-- 1) Proceed with request successfully and respond "WARNINGS" to app with 'info' parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Test Configuration ]]
common.getConfigAppParams().syncMsgVersion.majorVersion = 5
common.getConfigAppParams().syncMsgVersion.minorVersion = 0

--[[ Local Functions ]]
local function sendSetDisplayLayout()
  local params = {
    displayLayout = "Layout1"
  }
  local cid = common.getMobileSession():SendRPC("SetDisplayLayout", params)
  common.getHMIConnection():ExpectRequest("UI.SetDisplayLayout")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf(function(_, data)
      if data.payload.info ~= nil then
        return false, "'Info' is not expected"
      end
      return true
    end)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("App sends SetDisplayLayout RPC - SUCCESS", sendSetDisplayLayout)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
