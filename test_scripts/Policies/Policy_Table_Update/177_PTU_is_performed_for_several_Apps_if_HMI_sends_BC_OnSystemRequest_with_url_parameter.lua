---------------------------------------------------------------------------------------------------
-- Issues: https://github.com/smartdevicelink/sdl_core/issues/3715,
--         https://github.com/smartdevicelink/sdl_core/issues/3881
---------------------------------------------------------------------------------------------------
-- Description:
--  SDL accepts PTU from application for several Apps in case HMI sends BC.OnSystemRequest with 'url' parameter
-- Steps:
-- 1. Core and HMI are started
-- 2. App1 is registered
-- 3. App2 is registered
-- 4. Core sends OnStatusUpdate UPDATING
-- 5. HMI sends OnSystemRequest with 'url' parameter
-- 6. After OnSystemRequest is sent to randomly app, app attempts to send SystemRequest during PTU
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
      for i, _ in pairs(common.mobile.getApps()) do
        ptuTable.policy_table.app_policies[common.app.getPolicyAppId(i)] = common.ptu.getAppData(i)
      end
      utils.tableToJsonFile(ptuTable, ptuFileName)
      local event = common.run.createEvent()
      common.hmi.getConnection():ExpectEvent(event, "PTU event")
      for id, _ in pairs(common.mobile.getApps()) do
        common.mobile.getSession(id):ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function()
            common.hmi.getConnection():ExpectRequest("BasicCommunication.SystemRequest")
            :Do(function(_, d3)
                common.hmi.getConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
                common.hmi.getConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
                common.hmi.getConnection():SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                common.hmi.getConnection():SendNotification("SDL.OnReceivedPolicyUpdate",
                  { policyfile = d3.params.fileName })
              end)
            utils.cprint(35, "App ".. id .. " was used for PTU")
            common.hmi.getConnection():RaiseEvent(event, "PTU event")
            local corIdSystemRequest = common.mobile.getSession(id):SendRPC("SystemRequest", {
              requestType = "PROPRIETARY" }, ptuFileName)
            common.mobile.getSession(id):ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
            :Do(function() os.remove(ptuFileName) end)
          end)
        :Times(AtMost(1))
      end
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.app.registerNoPTU, { 1 })
runner.Step("Register App2", common.app.register, { 2 })

runner.Title("Test")
runner.Step("Successful PTU via a mobile app", policyTableUpdate)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
