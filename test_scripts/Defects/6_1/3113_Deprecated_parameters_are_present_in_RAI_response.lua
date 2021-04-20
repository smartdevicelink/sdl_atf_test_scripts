---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check deprecated parameters are present in response of RegisterAppInterface for a new apps (6.0)
--
-- Preconditions:
-- 1) SDL and HMI are started (HMI doesn't provide UI.GetCapabilities)
-- Steps:
-- 1) New app tries to register with 'syncMsgVersion' = 6.0
-- SDL does:
-- 1) Proceed with 'RegisterAppInterface' request
-- 2) Respond to app with deprecated parameters
--   - displayCapabilities
--   - buttonCapabilities
--   - softButtonCapabilities
--   - presetBankCapabilities
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
common.getConfigAppParams().syncMsgVersion.majorVersion = 6
common.getConfigAppParams().syncMsgVersion.minorVersion = 0

--[[ Local Functions ]]
local function getHMIParams()
  local params = hmi_values.getDefaultHMITable()
  params.UI.IsReady.params.available = true
  params.UI.GetCapabilities = nil
  return params
end

local function sendRegisterApp()
  common.getMobileSession():StartService(7)
  :Do(function()
      local corId = common.getMobileSession():SendRPC("RegisterAppInterface", common.getConfigAppParams())
      common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :ValidIf(function(_, data)
          local msg = ""
          if not data.payload.displayCapabilities then
            msg = msg .. "'displayCapabilities', "
          end
          if not data.payload.buttonCapabilities then
            msg = msg .. "'buttonCapabilities', "
          end
          if not data.payload.softButtonCapabilities then
            msg = msg .. "'softButtonCapabilities', "
          end
          if not data.payload.presetBankCapabilities then
            msg = msg .. "'presetBankCapabilities', "
          end
          if string.len(msg) > 0 then
            return false, "There are no expected parameters in response:\n" .. string.sub(msg, 1, -3)
          end
          return true
        end)
    end)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { getHMIParams() })

common.Title("Test")
common.Step("App sends RAI RPC - there are deprecated parameters", sendRegisterApp)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
