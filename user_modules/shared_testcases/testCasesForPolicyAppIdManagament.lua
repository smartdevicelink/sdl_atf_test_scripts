---------------------------------------------------------------------------------------------
-- Policy: AppID Management common module
---------------------------------------------------------------------------------------------
config.defaultProtocolVersion = 2

local common = {}
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

------------------------------------------------------------------------------------------------------------------------
-- The function is used only in case when PTU PROPRIETARY should have as result: UP_TO_DATE
-- The funcion will be used when PTU is triggered.
-- 1. It is assumed that notification is recevied:
-- EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
-- 2. It is assumed that request/response is received: EXPECT_HMICALL("BasicCommunication.PolicyUpdate",
-- 3. Function will use default endpoints
-- Difference with PROPRIETARY flow is clarified in "Can you clarify is PTU flows for External_Proprietary
-- and Proprietary have differences?"
-- But this should be checked in appropriate scripts
--TODO(istoimenova): functions with External_Proprietary should be merged at review of common functions.
function common:updatePolicyTable(test, file)
  local requestId = test.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
    local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
      .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
      test.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {
          requestType = "PROPRIETARY",
          fileName = pts_file_name
        })
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local corIdSystemRequest = test.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY" }, file)
          EXPECT_HMICALL("BasicCommunication.SystemRequest",{ requestType = "PROPRIETARY" }, file)
          :Do(function(_, data)
              EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
              test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
              test.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = data.params.fileName } )
            end)
          EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          EXPECT_HMICALL("VehicleInfo.GetVehicleData", { odometer = true })
        end)

    end)
end

return common
