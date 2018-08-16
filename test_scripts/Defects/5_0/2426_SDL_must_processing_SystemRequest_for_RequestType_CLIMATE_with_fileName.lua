---------------------------------------------------------------------------------------------------
-- Script verifies issue https://github.com/smartdevicelink/sdl_core/issues/2426

--   Start SDL and HMI
--   Connect mobile and create mobile session
--   Register mobile app and activated
--   Mobile app send SystemRequest( RequestType: CLIMATE, fileName:(binary file)

--	Expected Behavior
-- 		SDL must processing SystemRequest for RequestType: CLIMATE, fileName:(binary file) with resultCode:"SUCCESS" on the mobile app

--  Observed Behavior
--		SDL respond with resultCode:"REJECTED" to mobile app

---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local commonSystem = require('test_scripts/API/System/commonSystem')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local request_types = {
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

local temp_file = os.tmpname()
local expected_data = "{ \"policy_table\": { 100 } }"


--[[ Local Functions ]]
local function step(req_type)
  local f = io.open(temp_file, "w")
  f:write(expected_data)
  f:close()

  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
    { 
    	requestType = req_type,
    	fileName = temp_file
    })
  common.getMobileSession():ExpectNotification("OnSystemRequest", { requestType = req_type })
  :ValidIf(function(_, d)
      local actual_binary_data = commonSystem.convertTableToString(d.binaryData, 1)
      return expected_data == actual_binary_data
    end)
end

local function clear()
	os.remove(temp_file)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, value in pairs(request_types) do
  runner.Step("OnSystemRequest with request_type" .. tostring(value), step, { value })
end

runner.Title("Postconditions")
runner.Step("Delete temp file", clear)
runner.Step("Stop SDL", common.postconditions)
