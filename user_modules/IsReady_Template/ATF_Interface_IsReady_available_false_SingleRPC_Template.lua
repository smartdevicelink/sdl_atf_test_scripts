--TODO: APPLINK-29352: Genivi: SDL doesn't accept some error_codes from HMI when they are sending with type of protocol_message "error"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

---------------------------------------------------------------------------------------------
---------------------------- Required Shared libraries --------------------------------------
---------------------------------------------------------------------------------------------

	local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
	local commonSteps = require('user_modules/shared_testcases/commonSteps')
	local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
	local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
	local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
	config.SDLStoragePath = commonPreconditions:GetPathToSDL() .. "storage/"
	DefaultTimeout = 3
	local iTimeout = 2000

---------------------------------------------------------------------------------------------
------------------------- General Precondition before ATF start -----------------------------
---------------------------------------------------------------------------------------------
	-- Precondition: remove policy table and log files
	commonSteps:DeleteLogsFileAndPolicyTable()


---------------------------------------------------------------------------------------------
---------------------------- General Settings for configuration----------------------------
---------------------------------------------------------------------------------------------
	Test = require('connecttest')

	require('cardinalities')
	local events = require('events')  
	local mobile_session = require('mobile_session')
	require('user_modules/AppTypes')
	local isReady = require('user_modules/IsReady_Template/isReady')

---------------------------------------------------------------------------------------------
------------------------------------ Common variables ---------------------------------------
---------------------------------------------------------------------------------------------
	local RPCs = commonFunctions:cloneTable(isReady.RPCs)
	local mobile_request = commonFunctions:cloneTable(isReady.mobile_request)

	local function userPrint( color, message)
	  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
	end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

--Not applicable

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

-- Not applicable for '..tested_method..' HMI API.



----------------------------------------------------------------------------------------------
----------------------------------------TEST BLOCK II-----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

-- Not applicable for '..tested_method..' HMI API.

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------

--List of CRQs:
	--APPLINK-20918: [GENIVI] VR interface: SDL behavior in case HMI does not respond to IsReady_request or respond with "available" = false
		-- 1. HMI respond IsReady (false) -> SDL must return 'UNSUPPORTED_RESOURCE, success:false' to all single Interface-related RPC
		-- 2. HMI respond IsReady (false) and app sends RPC that must be spitted -> SDL must NOT transfer Interface portion of spitted RPC to HMI
		-- 3. HMI does NOT respond to IsReady_request -> SDL must transfer received RPC to HMI even to non-responded Interface module

--List of parameters in '..tested_method..' response:
	--Parameter 1: correlationID: type=Integer, mandatory="true"
	--Parameter 2: method: type=String, mandatory="true" (method = IsReady) 
	--Parameter 3: resultCode: type=String Enumeration(Integer), mandatory="true" 
	--Parameter 4: info/message: type=String, minlength="1" maxlength="10" mandatory="false" 
	--Parameter 5: available: type=Boolean, mandatory="true"
-----------------------------------------------------------------------------------------------

	
	
-----------------------------------------------------------------------------------------------				
-- Cases 1: HMI sends IsReady response (available = false)
-----------------------------------------------------------------------------------------------
	for i = 1, #TestData_AvailableFalse do
		local TestCaseName = TestedInterface .."_"..TestData_AvailableFalse[i].description
			
		--Print new line to separate new test cases group

		commonFunctions:newTestCasesGroup(TestCaseName)
			
		isReady:StopStartSDL_HMI_MOBILE_available_false(self, TestData_AvailableFalse[i].caseID, TestData_AvailableFalse[i].value, TestCaseName)
			
		-----------------------------------------------------------------------------------------------
		--CRQ #2) 
		-- VR:  APPLINK-20931: [VR Interface] Conditions for SDL to respond 'UNSUPPORTED_RESOURCE, success:false' to mobile app <= SDL receives IsReady(available=false) from HMI 
		-- UI:  APPLINK-25045
		-- TTS: APPLINK-25140
		-- VehicleInfo: APPLINK-25224
		-- Navigation:  APPLINK-25184
		-- Verification criteria:
			-- In case SDL receives Interface (available=false) from HMI and mobile app sends any single interface-related RPC
			-- SDL must respond "UNSUPPORTED_RESOURCE, success=false, info: "Interface is not supported by system" to mobile app
			-- SDL must NOT transfer this Interface-related RPC to HMI
		-----------------------------------------------------------------------------------------------	
		commonSteps:RegisterAppInterface("Precondition"..i.."_RegisterAppInterface_" .. TestCaseName)
			
		-- Description: Activation app for precondition
		commonSteps:ActivationApp(nil, "Precondition"..i.."_ActivationApp_" .. TestCaseName)

		commonSteps:PutFile("Precondition"..i.."_PutFile_MinLength", "a")
		commonSteps:PutFile("Precondition"..i.."_PutFile_icon.png", "icon.png")
		commonSteps:PutFile("Precondition"..i.."_PutFile_action.png", "action.png")

		local function Interface_IsReady_response_availabe_false_check_single_related_RPC(TestCaseName)
			for count_RPC = 1, #RPCs do
					
				local mob_request = mobile_request[count_RPC]
				local hmi_call = RPCs[count_RPC]
				local hmi_method_call = TestedInterface.."."..hmi_call.name

				if(mob_request.single == true)then
					if( (mob_request.name ~= "StartStream") and (mob_request.name ~= "StopStream") and 
						(mob_request.name ~= "StartAudioStream") and (mob_request.name ~= "StopAudioStream")) then
						-- All applicable RPCs
						if(TestedInterface == "TTS" and (mob_request.name == "SetGlobalProperties") ) then
							mob_request.single = false 
						end
						if(mob_request.single == true) then
							Test["TC_".. RPCs[count_RPC].name .. "_UNSUPPORTED_RESOURCE_false" ..TestCaseName] = function(self)
								userPrint(33, "Testing RPC = "..RPCs[count_RPC].name)
								local menuparams = ""
								local vrCmd = ""
								local ltimeout = ""
								local helpPrompt = ""

								if ( hmi_call.params.appID ~= nil ) then hmi_call.params.appID = self.applications[config.application1.registerAppInterfaceParams.appName] end
									
									
								if ( TestedInterface == "VR") then 
										-- APPLINK-19333: AddCommand should not to be splitted to UI.AddCommand
										if (mob_request.params.menuParams ~= nil ) then 
											menuparams = mob_request.params.menuParams 
											mob_request.params.menuParams =  nil 
										end
								end
								if( TestedInterface == "UI") then
										-- APPLINK-19329: AddCommand should not to be splitted to VR.AddCommand
										if ( mob_request.params.vrCommands ~= nil ) then 
											vrCmd = mob_request.params.vrCommands
											mob_request.params.vrCommands = nil
										end
										if (mob_request.params.timeoutPrompt ~= nil ) then
											ltimeout = mob_request.params.timeoutPrompt
											mob_request.params.timeoutPrompt = nil
										end
										if (mob_request.params.helpPrompt ~= nil ) then
											helpPrompt = mob_request.params.helpPrompt
											mob_request.params.helpPrompt = nil
										end
								end

								commonTestCases:DelayedExp(iTimeout)

								local cid
							
								--mobile side: sending AddCommand request
								cid = self.mobileSession:SendRPC(mob_request.name, mob_request.params)
										
								--hmi side: expect SDL does not send Interface.RPC request
								EXPECT_HMICALL(hmi_method_call, {})
								:Times(0)

								if(mob_request.name == "DeleteCommand" or mob_request.name == "DeleteSubMenu") then
									-- According to APPLINK-27079; APPLNIK-19401
									--mobile side: expect RPC response
									EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_ID"})
									
								elseif(mob_request.name == "UnsubscribeVehicleData" or mob_request.name == "UnsubscribeWayPoints") then
									-- According to APPLINK-27872 and APPLINK-20043; APPLINK-21906
									-- mobile side: expect RPC response
									EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED"})
								
								else
									--mobile side: expect RPC response
									EXPECT_RESPONSE(cid, {success = false, resultCode = "UNSUPPORTED_RESOURCE", info =  TestedInterface .." is not supported by system"})
									
								end

								--mobile side: expect OnHashChange notification
								EXPECT_NOTIFICATION("OnHashChange")
								:Times(0)

								--In some reason when assign global variable to local one and local var becomes nil, global var also becomes nil!!!! The solution is temporary until resolving the problem. 
								if(menuparams ~= "") then mob_request.params.menuParams = menuparams end
								if(vrCmd ~= "") 	 then mob_request.params.vrCommands = vrCmd end
								if(ltimeout ~= "")   then mob_request.params.timeoutPrompt = ltimeout end
								if(helpPrompt ~= "") then mob_request.params.helpPrompt = helpPrompt end
							end		
						end
					elseif ( (mob_request.name == "StartStream") or (mob_request.name == "StartAudioStream") ) then
						Test["TC_".. RPCs[count_RPC].name .. "_UNSUPPORTED_RESOURCE_false" ..TestCaseName] = function(self)
							userPrint(33, "Testing RPC = "..mob_request.name)
							local serType = 11
							if (mob_request.name ~= "StartAudioStream") then
								serType = 10
							end
							local startSession =
													{
														frameType = 0,
														serviceType = serType,
														frameInfo = 1,
														sessionId = self.mobileSession.sessionId,
													}

							self.mobileSession:Send(startSession)
						  
							EXPECT_HMICALL(hmi_method_call, {})
							:Times(0)
								
							if (mob_request.name == "StartStream") then
								self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")	
							else
								self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
							end
								
							EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming")
							:Times(0)

							EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming")
							:Times(0)

							-- prepare event to expect
							local startserviceEvent = events.Event()
								
							startserviceEvent.matches = 
								function(_, data)
									return data.frameType == 0 and
											data.serviceType == serType and
											(data.sessionId == self.mobileSession.sessionId) and
											(data.frameInfo == 2 or -- Start Service ACK
											data.frameInfo == 3) -- Start Service NACK
								end

							local ret = self.mobileSession:ExpectEvent(startserviceEvent, "StartService ACK")
											:ValidIf(function(s, data)
												if data.frameInfo == 2 then -- Start Service ACK
													xmlReporter.AddMessage("StartService", "StartService ACK", "True")
													print ("\27[32m Start Service ACK received \27[0m ")				
													return false
												elseif data.frameInfo == 3 then -- Start Service NACK
													print ("\27[32m Start Service NACK received \27[0m ")			
													return true 
												else 
													print ("\27[32m Start Service ACK / NACK is not received \27[0m ")
													return false 
												end
											end)						
						end
					else 
						print( hmi_method_call .. " can not be tested because preconditions have result UNSUPPORTED_RESOURCE")
					end
				end --if(mob_request.single == true)then	
			end -- for count_RPC = 1, #RPCs do
		end
			
		Interface_IsReady_response_availabe_false_check_single_related_RPC(TestedInterface.."_"..TestData_AvailableFalse[i].description .."_related_RPC")

	end --for i = 1, #TestData_AvailableFalse do
	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------

-- These cases are merged into TEST BLOCK III
	
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Not applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Not applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

-- Not applicable for '..tested_method..' HMI API.


----------------------------------------------------------------------------------------------
-----------------------------------------Postconditions---------------------------------------
----------------------------------------------------------------------------------------------

	function Test:Postcondition_RestorePreloadedFile()
		commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
	end

	Test["ForceKill"] = function (self)
		print("----------------- Postconditions ----------------------------")
		os.execute("ps aux | grep smart | awk \'{print $2}\' | xargs kill -9")
		os.execute("sleep 1")
	end

return Test