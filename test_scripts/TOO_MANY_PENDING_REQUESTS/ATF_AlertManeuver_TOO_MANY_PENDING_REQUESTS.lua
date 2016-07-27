Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')


local n = 0

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

 commonSteps:ActivationApp()

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------
--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

    --Requirement id in JAMA: SDLAQ-CRS-677

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.

    function Test:RegisterAppInterface_TooManyPendingRequest()
      for ii = 1, 10 do
        --mobile side: AlertManeuver request 
        self.mobileSession:SendRPC("AlertManeuver",
                                {
                                     
                                  ttsChunks = 
                                  { 
                                    
                                    { 
                                      text ="FirstAlert",
                                      type ="TEXT",
                                    }, 
                                    
                                    { 
                                      text ="SecondAlert",
                                      type ="TEXT",
                                    }, 
                                  }, 
                                  softButtons = 
                                  { 
                                    
                                    { 
                                      type = "TEXT",
                                      text = "Close", 
                                      isHighlighted = true,
                                      softButtonID = 821,
                                      systemAction = "DEFAULT_ACTION",
                                    }, 
                                    
                                    { 
                                      type = "TEXT",
                                      text = "AnotherClose", 
                                      isHighlighted = false,
                                      softButtonID = 822,
                                      systemAction = "DEFAULT_ACTION",
                                    },
                                  }
                                
                                })
      end
    end

    function Test:RegisterAppInterface_TooManyPendingRequest2()
      EXPECT_RESPONSE("AlertManeuver")
      :ValidIf(function(exp,data)
      	if 
      		data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
            n = n+1
            print(" \27[32m AlertManeuver response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
      		  return true
        elseif 
           exp.occurences == 7 and n == 0 then 
          print(" \27[36m Response AlertManeuver with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
          return false
        elseif 
          data.payload.resultCode == "GENERIC_ERROR" then
            print(" \27[32m AlertManeuver response came with resultCode GENERIC_ERROR \27[0m")
            return true
        else
            print(" \27[36m AlertManeuver response came with resultCode "..tostring(data.payload.resultCode.. "\27[0m"))
            return false
        end
      end)
      :Times(AtMost(10))
      :Timeout(15000)

      EXPECT_HMINOTIFICATION("OnAppInterfaceUnregistered")
      :Times(0)
      :Timeout(15000)


      DelayedExp(15000)

    end


--End Test suit ResultCodeCheck













