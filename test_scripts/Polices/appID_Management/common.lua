---------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------

local Common = {}

  local policy_file_path = "/tmp/fs/mp/images/ivsu_cache/"
  local policy_file_name = "PolicyTableUpdate"

  function Common:UpdatePolicyTable(test, file) 
    -- HMI->SDL: SDL.GetURLs(service_type = 7)
    local requestId = test.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })      
    -- SDL->HMI: GetURLs(SUCCESS, urls: [appId, url])
    EXPECT_HMIRESPONSE(requestId, {result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
    :Do(function(_, _)
      -- HMI->SDL: BC.OnSystemRequest(request_type=PROPRIETARY, url, appId, fileName)
      test.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = policy_file_name
        }
      )
    end)
    -- SDL->MOB: OnSystemRequest(request_type=PROPRIETARY, url, binary_header + policies_snapshot)
    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" }) 
    :Do(function(_, _)       
      -- MOB->SDL: SystemRequest(request_type=PROPRIETARY, fileName + policies update)      
      local corIdSystemRequest = test.mobileSession:SendRPC("SystemRequest",
        {     
          requestType = "PROPRIETARY",
          fileName = policy_file_name
        },
        file)          
      -- SDL->HMI: SystemRequest(request_type=PROPRIETARY, PTUFileName, appId)
      EXPECT_HMICALL("BasicCommunication.SystemRequest")      
      :Do(function(_, data)       
        -- HMI->SDL: SUCCESS: SystemRequest
        test.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
        -- HMI->SDL: SDL.OnReceivedPolicyTable(PTUFileName)
        test.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
          {          
            --policyfile = "/home/dboltovskyi/git/open/sdl_core_build_4.2.0/bin/ivsu_cache/PolicyTableUpdate"
            policyfile = policy_file_path .. policy_file_name
          }
        )             
      end)
      -- SDL->HMI: OnStatusUpdate(UP_TO_DATE)
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
      -- SDL->MOB: SUCCESS: SystemRequest
      EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})  
      :Do(function(_, _)
        requestId = test.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})        
        EXPECT_HMIRESPONSE(requestId)        
      end)
    end)    
  end

return Common