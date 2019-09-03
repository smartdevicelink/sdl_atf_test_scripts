---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check deprecated parameters are present in response of RegisterAppInterface for old apps (5.0)
--
-- Preconditions:
-- 1) SDL and HMI are started
-- Steps:
-- 1) New app tries to register with 'syncMsgVersion' = 5.0
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

--[[ Test Configuration ]]
common.getConfigAppParams().syncMsgVersion.majorVersion = 5
common.getConfigAppParams().syncMsgVersion.minorVersion = 0

--[[ Local Functions ]]
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
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

common.Title("Test")
common.Step("App sends RAI RPC - there are deprecated parameters", sendRegisterApp)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
