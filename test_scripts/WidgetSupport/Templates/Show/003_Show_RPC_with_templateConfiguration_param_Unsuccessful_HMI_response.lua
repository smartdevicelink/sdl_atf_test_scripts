---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL proceed with "Show" RPC in case if HMI respond unsuccessfully
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered (color schemes are not defined)
-- 3) App is activated
-- Steps:
-- 1) App sends "Show" request with templateConfiguration param to Main window
-- SDL does:
--   - transfer request to HMI
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
local requestShowParams = {
  windowID = 0,
  templateConfiguration = {
    template = "Template3",
    dayColorScheme = {
      primaryColor = {
        red = 11,
        green = 11,
        blue = 11
      }
    }
  }
}

--[[ Local Functions ]]
local function sendShow_UNSUCCESS_noHMIResponse()
  local cid = common.getMobileSession():SendRPC("Show", requestShowParams)
  common.getHMIConnection():ExpectRequest("UI.Show", requestShowParams)
  :Do(function()
      -- no response from HMI
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

local function sendShow_UNSUCCESS_errorHMIResponse()
  local cid = common.getMobileSession():SendRPC("Show", requestShowParams )
  common.getHMIConnection():ExpectRequest("UI.Show", requestShowParams)
  :Do(function(_, data)
    common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Error code")
  end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "TIMED_OUT" })
end

local function sendShow_UNSUCCESS_invalidHMIResponse()
  local cid = common.getMobileSession():SendRPC("Show", requestShowParams)
  common.getHMIConnection():ExpectRequest("UI.Show", requestShowParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, 123, "SUCCESS", {}) -- invalid method
  end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends Show no HMI response GENERIC_ERROR", sendShow_UNSUCCESS_noHMIResponse)
common.Step("App sends Show error HMI response TIMED_OUT' ", sendShow_UNSUCCESS_errorHMIResponse)
common.Step("App sends Show invalid HMI response GENERIC_ERROR", sendShow_UNSUCCESS_invalidHMIResponse)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
