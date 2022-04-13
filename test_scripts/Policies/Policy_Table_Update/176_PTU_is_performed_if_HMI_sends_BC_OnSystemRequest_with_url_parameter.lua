---------------------------------------------------------------------------------------------------
-- Issues: https://github.com/smartdevicelink/sdl_core/issues/3715,
--         https://github.com/smartdevicelink/sdl_core/issues/3881
---------------------------------------------------------------------------------------------------
-- Description: SDL accepts PTU from application in case HMI sends BC.OnSystemRequest with 'url' parameter
-- Steps:
-- 1. Core and HMI are started
-- 2. App is registered
-- 3. Core sends OnStatusUpdate UPDATING
-- 4. HMI sends OnSystemRequest with 'url' parameter
-- 5. After OnSystemRequest is sent to app, app attempts to send first SystemRequest during PTU
-- SDL does:
--  - accept the PTU, responding success:true, resultCode:SUCCESS
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local utils = require('user_modules/utils')
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Functions ]]
local function policyTableUpdate()
  local ptuFileName = os.tmpname()
  local requestId = common.hmi.getConnection():SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  common.hmi.getConnection():ExpectResponse(requestId)
  :Do(function()
      common.hmi.getConnection():SendNotification("BasicCommunication.OnSystemRequest", {
        requestType = "PROPRIETARY",
        fileName = common.sdl.getPTSFilePath(),
        url = "http://x.x.x.x:3000/api/1/policies/proprietary"
      })
      local ptuTable = common.getPTUFromPTS()
      ptuTable.policy_table.app_policies[common.app.getPolicyAppId()] = common.ptu.getAppData()
      utils.tableToJsonFile(ptuTable, ptuFileName)
      local event = common.run.createEvent()
      common.hmi.getConnection():ExpectEvent(event, "PTU event")
      common.mobile.getSession():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          common.hmi.getConnection():ExpectRequest("BasicCommunication.SystemRequest")
          :Do(function(_, d3)
              common.hmi.getConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
              common.hmi.getConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
              common.hmi.getConnection():SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
              common.hmi.getConnection():SendNotification("SDL.OnReceivedPolicyUpdate",
                { policyfile = d3.params.fileName })
            end)
          common.hmi.getConnection():RaiseEvent(event, "PTU event")
          local corIdSystemRequest = common.mobile.getSession():SendRPC("SystemRequest", {
            requestType = "PROPRIETARY" }, ptuFileName)
          common.mobile.getSession():ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
          :Do(function() os.remove(ptuFileName) end)
        end)
      :Times(AtMost(1))
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)

runner.Title("Test")
runner.Step("Successful PTU via a mobile app", policyTableUpdate)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
