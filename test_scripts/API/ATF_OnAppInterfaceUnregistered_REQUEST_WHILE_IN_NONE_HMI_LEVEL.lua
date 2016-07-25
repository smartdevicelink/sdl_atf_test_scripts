--NOTE:session:ExpectNotification("notification_name", { argument_to_check }) is chanegd to session:ExpectNotification("notification_name", {{ argument_to_check }}) due to defect APPLINK-17030 
--After this defect is done, please reverse to session:ExpectNotification("notification_name", { argument_to_check })
-------------------------------------------------------------------------------------------------------------------
--Set "AppHMILevelNoneTimeScaleMaxRequests" = 1
-------------------------------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local module = require('testbase')
--------------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 8000)
end

---------------------------------------------------------------------------------------------------------------
-- Requirement Id: APPLINK-16147 and SDLAQ-CRS-886
---------------------------------------------------------------------------------------------------------------
--APPLINK-18426
--Verification: OnAppInterfaceUnregistered notification with REQUEST_WHILE_IN_NONE_HMI_LEVEL reason.
--------------------------------------------------------------------------------------------------------------
--NOTE: TC will be run correctly (returns OnAppInterfaceUnregistered(REQUEST_WHILE_IN_NONE_HMI_LEVEL)) when APPLINK-22795 is completed

commonFunctions:newTestCasesGroup("TC_APPLINK_ APPLINK-18426: OnAppInterfaceUnregistered(REQUEST_WHILE_IN_NONE_HMI_LEVEL)")
	
function Test:APPLINK_18426()

	local AppNotRegisteredReqCount = 0
	for i = 1,10 do			
		local cid = self.mobileSession:SendRPC("ListFiles", {} )
	end
	
	EXPECT_RESPONSE("ListFiles")
	:ValidIf(function(exp,data)			
		if 
			data.payload.resultCode == "APPLICATION_NOT_REGISTERED" then
			AppNotRegisteredReqCount = AppNotRegisteredReqCount+1
			print(" \27[32m ListFiles response came with resultCode APPLICATION_NOT_REGISTERED \27[0m")
			return true
		elseif				
		   exp.occurences  ==10 and AppNotRegisteredReqCount == 0 then			   
		  print(" \27[36m Response ListFiles with resultCode APPLICATION_NOT_REGISTERED did not came \27[0m")
		  return false
		elseif 
		  data.payload.resultCode == "SUCCESS" then
			print(" \27[32m ListFiles response came with resultCode SUCCESS \27[0m")
			return true
		else
			print(" \27[36m ListFiles response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
			return false
		end
	end)
	:Times(AtMost(10))
		
	--hmi side: expect BasicCommunication.OnAppUnregistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID =  self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
			
	--mobile side: expect notification
	self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "REQUEST_WHILE_IN_NONE_HMI_LEVEL"}})
	
	DelayedExp()
end	

--NOTE: function RegisterAgain_AfterAppIsUnregistered should work after APPLINK-16147 is implemeted 
-- function Test:RegisterAgain_AfterAppIsUnregistered()
	-- local cid= self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
	-- EXPECT_RESPONSE(cid, { success = false, resultCode = "TOO_MANY_PENDING_REQUESTS"})
-- end