--------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3895
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL does not send:
--  - BasicCommunication.PolicyUpdate notification twice to HMI for 'PROPRIETARY' and 'EXTERNAL_PROPRIETARY' policy mode
--  - OnSystemRequest request twice to App for 'HTTP' mode in case HMI sends SDL.OnPolicyUpdate notification
--  during 'ApplicationListUpdateTimeout' when timeout is almost expired
---------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. App is registered
-- Steps:
-- 1. HMI sends SDL.OnPolicyUpdate notification during 'ApplicationListUpdateTimeout' when timeout is almost expired
-- SDL does:
-- - send BasicCommunication.PolicyUpdate notification to HMI for 'PROPRIETARY' and 'EXTERNAL_PROPRIETARY' policy mode
-- - OnSystemRequest request to App for 'HTTP' mode
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local common = require("user_modules/sequences/actions")
local utils = require ('user_modules/utils')
local atf_logger = require("atf_logger")
local consts = require("user_modules/consts")
local SDL = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local applicationListUpdateTimeout = common.sdl.getSDLIniParameter("ApplicationListUpdateTimeout")
local latencyTime = 20
local sendOnPolicyUpdateTime = applicationListUpdateTimeout + latencyTime

local policyModes = {
  P  = "PROPRIETARY",
  EP = "EXTERNAL_PROPRIETARY",
  H  = "HTTP"
}

--[[ Local Functions ]]
local function logger(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter ..tostring(p)
  end
  utils.cprint(consts.color.magenta, str)
end

local function sendOnPolicyUpdate()
  logger("HMI->SDL: SDL.OnPolicyUpdate")
  common.getHMIConnection():SendNotification("SDL.OnPolicyUpdate", {} )
end

local function registerAppDuringOnPolicyUpdate()
  local pAppId = 1
  local pMobConnId = 1
  common.run.runAfter(sendOnPolicyUpdate, sendOnPolicyUpdateTime)
  local session = common.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", common.app.getParams(pAppId))
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.app.getParams(pAppId).appName } })
      :Do(function(_, d1)
          common.hmi.getConnection():ExpectRequest("SDL.OnStatusUpdate",
            { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
          :Times(2)
          common.app.setHMIId(d1.params.application.appID, pAppId)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateAppList")
          :Do(function(_, d)
              logger("SDL->HMI: BasicCommunication.UpdateAppList")
              common.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { })
            end)
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          local policyMode = SDL.buildOptions.extendedPolicy
          if policyMode == policyModes.P or policyMode == policyModes.EP then
            common.hmi.getConnection():ExpectRequest("BasicCommunication.PolicyUpdate")
            :Do(function(_, d2)
                common.hmi.getConnection():SendResponse(d2.id, d2.method, "SUCCESS", { })
              end)
          elseif policyMode == policyModes.H then
            session:ExpectNotification("OnSystemRequest",
              { requestType = "LOCK_SCREEN_ICON_URL" },
              { requestType = "HTTP" })
            :Times(2)
          end
        end)
    end)
  utils.wait(3000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", registerAppDuringOnPolicyUpdate)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
