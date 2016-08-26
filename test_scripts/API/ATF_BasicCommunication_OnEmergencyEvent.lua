Test = require('connecttest')
require('cardinalities')
local events = require('events')	
local mobile_session = require('mobile_session')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------
function BC_OnEmergencyEvent_Notification(self, Description, Method, Params, Case)
	
	if (Description == "enabled = true" or Description == "enabled = false") then count = 1 else count = 0 end

	if (Case == nil) then
		self.hmiConnection:SendNotification( Method, Params)
	elseif Case == 1 then
		--HMI doen't send BasicCommunication.OnEmergencyEvent notification
	elseif Case == 2 then
		self.hmiConnection:Send('')
	elseif Case == 3 then
		self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication","params":{"enabled":false}}')
	elseif Case == 4 then
		self.hmiConnection:Send('{"jsonrpc":"2.0","method""BasicCommunication.OnEmergencyEvent","params":{"enabled":false}}')		
	end	
	
	if (Description == "enabled = true") then
		audioStreaming = "NOT_AUDIBLE"
	else
		audioStreaming = "AUDIBLE"
	end

	EXPECT_NOTIFICATION("OnHMIStatus", {audioStreamingState = audioStreaming})
	:Times(count)
	
	commonTestCases:DelayedExp(5000)
	
end


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--------------Check notification BasicCommunication.OnEmergencyEvent from HMI----------------
---------------------------------------------------------------------------------------------	

	--Description: TC's checks processing 
		--HMI sends BasicCommunication.OnEmergencyEvent with enabled = true
		--HMI sends BasicCommunication.OnEmergencyEvent with enabled = false
		--HMI sends BasicCommunication.OnEmergencyEvent with Empty method
		--HMI sends BasicCommunication.OnEmergencyEvent with Empty enabled
		--HMI sends BasicCommunication.OnEmergencyEvent with Missing enabled parameter
		--HMI sends BasicCommunication.OnEmergencyEvent with Wrong type of method
		--HMI sends BasicCommunication.OnEmergencyEvent with Wrong type of enabled
		--HMI doen't BasicCommunication.OnEmergencyEvent notification
		--HMI sends BasicCommunication.OnEmergencyEvent with Missing all parameters
		--HMI sends BasicCommunication.OnEmergencyEvent with Missing Method parameter
		--HMI sends BasicCommunication.OnEmergencyEvent with Invalid Json

		--Requirement id in JAMA: 
				--APPLINK-24441: https://adc.luxoft.com/svn/APPLINK/doc/technical/HOW-TOs_and_Guidelines/FORD.SmartDeviceLink.SDL_Integration_Guidelines.docx (6.25)
				
		----------------------------------------------------------------------------------------------		

		local TestData = {
			{description = "enabled = true",				method = "BasicCommunication.OnEmergencyEvent" , 	parameter = {enabled = true}			},
			{description = "enabled = false",				method = "BasicCommunication.OnEmergencyEvent" , 	parameter = {enabled = false}			},
			{description = "Empty method", 					method = "" , 										parameter = {enabled = true} 			},
			{description = "Empty enabled", 				method = "BasicCommunication.OnEmergencyEvent" , 	parameter = {enabled = ""}		 		}, 
			{description = "Missing enabled parameter", 	method = "BasicCommunication.OnEmergencyEvent" , 	parameter = {enabled = nil}	 			}, 
			{description = "Wrong type of method", 			method = 1234 ,										parameter = {enabled = true}		 	}, 
			{description = "Wrong type of enabled", 		method = "BasicCommunication.OnEmergencyEvent" , 	parameter = {enabled = 1234}			},
			{description = "HMI doen't respond", 			_, 												_, 									case = 1}, 
			{description = "Missing all parameters", 		_, 												_, 									case = 2}, 
			{description = "Missing Method parameter", 		_, 												_, 									case = 3},
			{description = "Invalid Json", 					_, 												_, 									case = 4}
		}		

		----------------------------------------------------------------------------------------------				

		commonSteps:ActivationApp()
		
		--Main executing
		for i=1, #TestData do
			
			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("-----------------------I." ..tostring(i).." [" ..TestData[i].description .. "]------------------------------")
			
			Test["BC_" .. TestData[i].description] = function(self)
				BC_OnEmergencyEvent_Notification(self, TestData[i].description, TestData[i].method, TestData[i].parameter, TestData[i].case)
			end
			
		end
