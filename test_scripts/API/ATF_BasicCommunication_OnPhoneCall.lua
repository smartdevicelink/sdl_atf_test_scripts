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
function BC_OnPhoneCall_Notification(self, Description, Method, Params, Case)
	
	if (Description == "isActive = true" or Description == "isActive = false") then count = 1 else count = 0 end

	if (Case == nil) then
		self.hmiConnection:SendNotification( Method, Params)
	elseif Case == 1 then
		--HMI doen't send BasicCommunication.OnPhoneCall notification
	elseif Case == 2 then
		self.hmiConnection:Send('')
	elseif Case == 3 then
		self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication","params":{"isActive":false}}')
	elseif Case == 4 then
		self.hmiConnection:Send('{"jsonrpc":"2.0","method""BasicCommunication.OnPhoneCall","params":{"isActive":false}}')		
	end
	
	--Resume the applications to the previous-to-phonecall state on HMI (as SDL does not send BC.ActivateApp or BC.OnResumeAudioSource to HMI after the phone call is ended
	if (Description == "isActive = false") then
		EXPECT_HMICALL("BasicCommunication.ActivateApp")
		:Times(0)
		
		EXPECT_HMICALL("BasicCommunication.OnResumeAudioSource")
		:Times(0)		
	end

	EXPECT_NOTIFICATION("OnHMIStatus")
	:Times(count)
	
	commonTestCases:DelayedExp(5000)
	
end


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
-----------------Check notification BasicCommunication.OnPhoneCall from HMI------------------
---------------------------------------------------------------------------------------------	

	--Description: TC's checks processing 
		--HMI sends BasicCommunication.OnPhoneCall with isActive = true
		--HMI sends BasicCommunication.OnPhoneCall with isActive = false
		--HMI sends BasicCommunication.OnPhoneCall with Empty method
		--HMI sends BasicCommunication.OnPhoneCall with Empty isActive
		--HMI sends BasicCommunication.OnPhoneCall with Missing isActive parameter
		--HMI sends BasicCommunication.OnPhoneCall with Wrong type of method
		--HMI sends BasicCommunication.OnPhoneCall with Wrong type of isActive
		--HMI doen't BasicCommunication.OnPhoneCall notification
		--HMI sends BasicCommunication.OnPhoneCall with Missing all parameters
		--HMI sends BasicCommunication.OnPhoneCall with Missing Method parameter
		--HMI sends BasicCommunication.OnPhoneCall with Invalid Json

		--Requirement id in JAMA: 
				--APPLINK-24441: https://adc.luxoft.com/svn/APPLINK/doc/technical/HOW-TOs_and_Guidelines/FORD.SmartDeviceLink.SDL_Integration_Guidelines.docx (6.25)
				
		----------------------------------------------------------------------------------------------		

		local TestData = {
			{description = "isActive = true",				method = "BasicCommunication.OnPhoneCall" , 	parameter = {isActive = true}				},
			{description = "isActive = false",				method = "BasicCommunication.OnPhoneCall" , 	parameter = {isActive = false}				},
			{description = "Empty method", 					method = "" , 									parameter = {isActive = true} 				},
			{description = "Empty isActive", 				method = "BasicCommunication.OnPhoneCall" , 	parameter = {isActive = ""}		 			}, 
			{description = "Missing isActive parameter", 	method = "BasicCommunication.OnPhoneCall" , 	parameter = {isActive = nil}	 			}, 
			{description = "Wrong type of method", 			method = 1234 ,									parameter = {isActive = true}		 		}, 
			{description = "Wrong type of isActive", 		method = "BasicCommunication.OnPhoneCall" , 	parameter = {isActive = 1234}			 	},
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
				BC_OnPhoneCall_Notification(self, TestData[i].description, TestData[i].method, TestData[i].parameter, TestData[i].case)
			end
			
		end
