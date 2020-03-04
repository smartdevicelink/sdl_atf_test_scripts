---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3267
--
-- Steps:
-- 1. Make sure specific 'url' is defined in PT in 'endpoints' section for an application
-- 2. Start SDL, HMI, connect Mobile device
-- 3. Register mobile application
-- SDL does:
--  - send 'OnSystemRequest(LOCK_SCREEN_ICON_URL)' notification with app specific 'url'
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local urls = {
  default = "http://i.imgur.com/default.png",
  [1] = "http://i.imgur.com/0000001.png"
}

--[[ Local Functions ]]
local function updatePreloadedPT()
  local pt = common.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null
  local lockData = pt.policy_table.module_config.endpoints.lock_screen_icon_url
  lockData["default"] = { urls["default"] }
  lockData[common.app.getParams(1).fullAppID] = { urls[1] }
  common.sdl.setPreloadedPT(pt)
end

local function registerAppWOPTU(pAppId)
  local mobileSession = common.getMobileSession(pAppId)
  mobileSession:StartService(7)
  :Do(function()
    local corId = mobileSession:SendRPC("RegisterAppInterface", common.app.getParams(pAppId))
    common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
    mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      local exp = urls["default"]
      if pAppId == 1 then exp = urls[1] end
      mobileSession:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL", url = exp })
    end)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update SDL preloaded", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App 1", registerAppWOPTU, { 1 })
runner.Step("Register App 2", registerAppWOPTU, { 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
