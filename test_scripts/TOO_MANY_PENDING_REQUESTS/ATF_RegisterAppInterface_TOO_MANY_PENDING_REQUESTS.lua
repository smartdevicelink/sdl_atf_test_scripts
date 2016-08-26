Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')

local sessions = {}
local TooManyPenReqCount = 0

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 5000)
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

function Test:Precondition_StartSession1()
  -- Connected expectation
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection)

  self.mobileSession1:StartService(7)
    :Do(function(_,data)
      table.insert(sessions,self.mobileSession1)
    end)
end

function Test:Precondition_StartSession2()
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection)

  self.mobileSession2:StartService(7)
    :Do(function(_,data)
      table.insert(sessions,self.mobileSession2)
    end)
end


function Test:Precondition_StartSession3()
  -- Connected expectation
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
  self.mobileSession3:StartService(7)
    :Do(function(_,data)
      table.insert(sessions,self.mobileSession3)
    end)
end



function Test:Precondition_StartSession4()
  -- Connected expectation
  self.mobileSession4 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
  self.mobileSession4:StartService(7)
    :Do(function(_,data)
      table.insert(sessions,self.mobileSession4)
    end)

end



function Test:Precondition_StartSession5()
  -- Connected expectation
  self.mobileSession5 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
  self.mobileSession5:StartService(7)
    :Do(function(_,data)
      table.insert(sessions,self.mobileSession5)
    end)

end

function Test:Precondition_StartSession6()
  -- Connected expectation
  self.mobileSession6 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
    self.mobileSession6:StartService(7)
    :Do(function(_,data)
      table.insert(sessions,self.mobileSession6)
    end)

end


function Test:Precondition_StartSession7()
  -- Connected expectation
  self.mobileSession7 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
    self.mobileSession7:StartService(7)
    :Do(function(_,data)
      table.insert(sessions,self.mobileSession7)
    end)

end


function Test:Precondition_StartSession8()
  -- Connected expectation
  self.mobileSession8 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
    self.mobileSession8:StartService(7)
    :Do(function(_,data)
      table.insert(sessions,self.mobileSession8)
    end)

end


function Test:Precondition_StartSession9()
  -- Connected expectation
  self.mobileSession9 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
    self.mobileSession9:StartService(7)
    :Do(function(_,data)
      table.insert(sessions,self.mobileSession9)
    end)

end

function Test:Precondition_StartSession10()
  -- Connected expectation
  self.mobileSession10 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
    self.mobileSession10:StartService(7)
    :Do(function(_,data)
      table.insert(sessions,self.mobileSession10)
    end)

end

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------
--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

    --Requirement id in JAMA: SDLAQ-CRS-361

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.

    function Test:RegisterAppInterface_TooManyPendingRequest()

      for ii = 1, #sessions do
        --sending RegisterAppInterface request
        sessions[ii]:SendRPC("RegisterAppInterface",
                                    {
                                      syncMsgVersion = 
                                      { 
                                        majorVersion = 2,
                                        minorVersion = 1,
                                      }, 
                                      appName = "Name"..ii,
                                      isMediaApplication = true,
                                      languageDesired ="EN-US",
                                      hmiDisplayLanguageDesired ="EN-US",
                                      appID = "id"..ii,
                                    
                                    })
      end

      EXPECT_ANY_SESSION_NOTIFICATION("RegisterAppInterface")
      :ValidIf(function(exp,data)
      	if 
          data.rpcFunctionId == 1 and
      		data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
            TooManyPenReqCount = TooManyPenReqCount+1
            print(" \27[32m RegisterAppInterface response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m ")
      		  return true
        elseif 
           exp.occurences == #sessions and TooManyPenReqCount == 0 then 
          print(" \27[36m Response RegisterAppInterface with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
          return false
        elseif 
          data.rpcFunctionId == 1 and
          data.payload.resultCode == "SUCCESS" then
            print(" \27[32m RegisterAppInterface response came with resultCode SUCCESS \27[0m")
            return true
        elseif
          data.rpcFunctionId == 1 then
             print(" \27[36m RegisterAppInterface response came with resultCode "..tostring(data.payload.resultCode .."\27[0m"))
            return false
        end
      end)
      :Times(AtLeast(#sessions))

      EXPECT_ANY_SESSION_NOTIFICATION("OnAppInterfaceUnregistered")
      :Times(0)

      DelayedExp()

    end


--End Test suit ResultCodeCheck













