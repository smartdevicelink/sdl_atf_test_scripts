---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL proceed with "SetDisplayLayout" RPC according to req-ts
-- in case if HMI respond unsuccessfully
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered (color schemes are not defined)
-- Steps:
-- 1) App sends "SetDisplayLayout" request with all parameters defined
-- SDL does:
--   - Transfer request to HMI
-- 2) HMI respond with one of the following:
--   - no response
--   - erroneous response
--   - invalid data response
-- SDL does:
--   - validate HMI response
--   - respond to app accordingly
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]

local params = {
  displayLayout = "Layout1",
  dayColorScheme = {
    primaryColor = {
      red = 1,
      green = 2,
      blue = 3
    }
  }
}

--[[ Local Functions ]]
local function sendSetDisplayLayout_UNSUCCESS_noHMIResponse()
  local cid = common.getMobileSession():SendRPC("SetDisplayLayout", params)
  common.getHMIConnection():ExpectRequest("UI.SetDisplayLayout")
  :Do(function()
      -- no response from HMI
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

local function sendSetDisplayLayout_UNSUCCESS_errorHMIResponse()
  local cid = common.getMobileSession():SendRPC("SetDisplayLayout", params)
  common.getHMIConnection():ExpectRequest("UI.SetDisplayLayout")
  :Do(function(_, data)
      common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Error code")
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "TIMED_OUT" })
end

local function sendSetDisplayLayout_UNSUCCESS_invalidHMIResponse()
  local cid = common.getMobileSession():SendRPC("SetDisplayLayout", params)
  common.getHMIConnection():ExpectRequest("UI.SetDisplayLayout")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, 123, "SUCCESS", {}) -- invalid method
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end


--[[ Scenario ]]
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)

common.Title("Test")
common.Step("App sends SetDisplayLayout no HMI response GENERIC_ERROR",
  sendSetDisplayLayout_UNSUCCESS_noHMIResponse)
common.Step("App sends SetDisplayLayout error HMI response TIMED_OUT",
  sendSetDisplayLayout_UNSUCCESS_errorHMIResponse)
common.Step("App sends SetDisplayLayout invalid HMI response GENERIC_ERROR",
  sendSetDisplayLayout_UNSUCCESS_invalidHMIResponse)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
