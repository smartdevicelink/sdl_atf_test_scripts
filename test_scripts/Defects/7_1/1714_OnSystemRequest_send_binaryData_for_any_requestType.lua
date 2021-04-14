---------------------------------------------------------------------------------------------------
-- Script covers https://github.com/SmartDeviceLink/sdl_core/issues/1714
-- SDL core should be capable of sending binary data using the OnSystemRequest RPC for any requestType.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
runner.isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local request_types = {
  "HTTP" ,
  "FILE_RESUME" ,
  "AUTH_REQUEST" ,
  "AUTH_CHALLENGE" ,
  "AUTH_ACK" ,
  "QUERY_APPS" ,
  "LAUNCH_APP" ,
  "LOCK_SCREEN_ICON_URL" ,
  "TRAFFIC_MESSAGE_CHANNEL" ,
  "DRIVER_PROFILE" ,
  "VOICE_SEARCH" ,
  "NAVIGATION" ,
  "PHONE" ,
  "CLIMATE" ,
  "SETTINGS" ,
  "VEHICLE_DIAGNOSTICS" ,
  "EMERGENCY" ,
  "MEDIA" ,
  "FOTA" ,
}

local f_name = os.tmpname()
local exp_binary_data = "{ \"policy_table\": { } }"

--[[ Local Functions ]]
local function onSystemRequest(request_type)
  local f = io.open(f_name, "w")
  f:write(exp_binary_data)
  f:close()

  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = request_type, fileName = f_name, appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnSystemRequest", { requestType = request_type })
  :ValidIf(function(_, d)
      local actual_binary_data = d.binaryData
      return exp_binary_data == actual_binary_data
    end)
end

local function onSystemRequest_PROPRIETARY()
  local f = io.open(f_name, "w")
  f:write(exp_binary_data)
  f:close()

  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = "PROPRIETARY", fileName = f_name, appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
  :ValidIf(function(_, d)
      local binary_data = common.json.decode(d.binaryData)
      local actual_binary_data = binary_data["HTTPRequest"]["body"]
      return exp_binary_data == actual_binary_data
    end)
end

local function deleteFile()
  os.remove(f_name)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, value in pairs(request_types) do
  runner.Step("OnSystemRequest_with_request_type_" .. tostring(value), onSystemRequest, { value })
end
runner.Step("OnSystemRequest_with_request_type_PROPRIETARY", onSystemRequest_PROPRIETARY)

runner.Title("Postconditions")
runner.Step("Delete file", deleteFile)
runner.Step("Stop SDL", common.postconditions)
