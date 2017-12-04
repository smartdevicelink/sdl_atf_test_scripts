---------------------------------------------------------------------------------------------------
-- Script covers https://github.com/SmartDeviceLink/sdl_core/issues/1714
-- SDL core should be capable of sending binary data using the OnSystemRequest RPC for any requestType.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/System/commonSystem')
local json = require("modules/json")

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
local function onSystemRequest(request_type, self)
  local f = io.open(f_name, "w")
  f:write(exp_binary_data)
  f:close()

  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = request_type, fileName = f_name, appID = self.applications["Test Application"] })
  self.mobileSession1:ExpectNotification("OnSystemRequest", { requestType = request_type })
  :ValidIf(function(_, d)
      local actual_binary_data = common.convertTableToString(d.binaryData, 1)
      return exp_binary_data == actual_binary_data
    end)
end

local function onSystemRequest_PROPRIETARY(self)
  local f = io.open(f_name, "w")
  f:write(exp_binary_data)
  f:close()

  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = "PROPRIETARY", fileName = f_name, appID = self.applications["Test Application"] })
  self.mobileSession1:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
  :ValidIf(function(_, d)
      local binary_data = json.decode(d.binaryData)
      local actual_binary_data = common.convertTableToString(binary_data["HTTPRequest"]["body"], 1)
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
runner.Step("RAI with PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, value in pairs(request_types) do
  runner.Step("OnSystemRequest_with_request_type_" .. tostring(value), onSystemRequest, { value })
end
runner.Step("OnSystemRequest_with_request_type_PROPRIETARY", onSystemRequest_PROPRIETARY)

runner.Title("Postconditions")
runner.Step("Delete file", deleteFile)
runner.Step("Stop SDL", common.postconditions)
