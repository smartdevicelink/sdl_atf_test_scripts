--TODO: APPLINK-29352: Genivi: SDL doesn't accept some error_codes from HMI when they are sending with type of protocol_message "error"
-----------------------------------------------------------------------------------------------
---- – Scope: This script verifies below scenario:
	---- 1. HMI does not sends interface.IsReady() response or sends invalid response
	---- 2. Mobile -> SDL: A split request

	---- CASE 1
	---- 	1. SDL -> HMI(tested interface): request => Tested interface does not respond
	---- 	2. SDL -> HMI(other interface): request => SDL responds with different resultCode:
	---- 	3. SDL -> Mobile: "GENERIC_ERROR, success:false"

	---- CASE 2
	---- 	1. SDL -> HMI(tested interface): request => Tested interface responds with UNSUPPORTED_RESOURCE
	---- 	2. SDL -> HMI(other interface): request => SDL responds with different successfull resultCode
	---- 	3. SDL -> Mobile: "UNSUPPORTED_RESUORCE, success:true, info: "TestedInterface is not supported by system."

	---- CASE 3
	---- 	1. SDL -> HMI(tested interface): request => Tested interface responds with UNSUPPORTED_RESOURCE
	---- 	2. SDL -> HMI(other interface): request => SDL responds with different erroneous resultCode
	---- 	3. SDL -> Mobile: "UNSUPPORTED_RESUORCE, success:false, info: "TestedInterface is not supported by system."
-----------------------------------------------------------------------------------------------
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
		
	DefaultTimeout = 3
	local iTimeout = 2000
	local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
	config.SDLStoragePath = commonPreconditions:GetPathToSDL() .. "storage/"

---------------------------------------------------------------------------------------------
------------------------- General Precondition before ATF start -----------------------------
---------------------------------------------------------------------------------------------
	-- Precondition: remove policy table and log files
	commonSteps:DeleteLogsFileAndPolicyTable()

	local print_msg = ""

	if(Tested_resultCode ~= nil) then
		print_msg = "Test will be executed for resultCode = " .. Tested_resultCode .. "; "
	else
		Tested_resultCode = "AllTested"
		print_msg = "Test will be executed for all resultCodes; "
	end
	
	if(Tested_wrongJSON == nil) then
		Tested_wrongJSON = true
	end

	if(Tested_wrongJSON == true) then
		print_msg = print_msg .. "All wrong JSON formats will be tested."
	else
		print_msg = print_msg .. "Wrong JSON formats won't be tested."
	end

	print("====================== ".. print_msg .. " ======================")

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
----------------------------------- Local functions -----------------------------------------
---------------------------------------------------------------------------------------------	
	local function userPrint( color, message)
	  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
	end
---------------------------------------------------------------------------------------------
-------------------------------------------Common variables-----------------------------------
---------------------------------------------------------------------------------------------
	local RPCs           	  = commonFunctions:cloneTable(isReady.RPCs)
	local mobile_request 	  = commonFunctions:cloneTable(isReady.mobile_request)
	local NotTestedInterfaces = commonFunctions:cloneTable(isReady.NotTestedInterfaces)

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
	-- VR:          APPLINK-20918: [GENIVI] VR interface: SDL behavior in case HMI does not respond to IsReady_request or respond with "available" = false
	-- UI:          APPLINK-25085: [GENIVI] UI interface: SDL behavior in case HMI does not respond to IsReady_request or respond with "available" = false
	-- TTS:         APPLINK-25117: [GENIVI] TTS interface: SDL behavior in case HMI does not respond to IsReady_request or respond with "available" = false
	-- Navigation:  APPLINK-25169: [GENIVI] Navigation interface: SDL behavior in case HMI does not respond to IsReady_request or respond with "available" = false
	-- VehicleInfo: APPLINK-25200: [GENIVI] VehicleInfo interface: SDL behavior in case HMI does not respond to IsReady_request or respond with "available" = false

-----------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------
	--CRQ #1: 
	-- VR:  APPLINK-25044: [VR Interface] HMI does NOT respond to IsReady and mobile app sends RPC that must be splitted
	-- UI:  APPLINK-25099: [UI Interface] HMI does NOT respond to IsReady and mobile app sends RPC that must be splitted
	-- TTS: APPLINK-25139: [TTS Interface] HMI does NOT respond to IsReady and mobile app sends RPC that must be splitted
	-- VehicleInfo: Not applicable
	-- Navigation:  Not applicable
	-- Verification criteria:
		-- In case HMI does NOT respond to TestedInterface.IsReady_request
		-- and mobile app sends RPC to SDL that must be split to
		-- -> tested interface RPC
		-- -> any other <Interface>.RPC
		-- SDL must:
		-- transfer both tested interface RPC and <Interface>.RPC to HMI (in case <Interface> is supported by system)
		-- respond with '<received_resultCode_from_HMI>' to mobile app (please see list with resultCodes below)	
	-----------------------------------------------------------------------------------------------
	-- IsExecutedAllResultCodes:
	 							-- false: Test will be executed only for result code SUCCESS
	 							-- true:  Test will be executed for all possible result codes defined in structure TestData
	-- IsExecutedAllRelatedRPCs:
								-- false: Test will be executed only for first RPC
								-- true:  Test will be executed for all defined RPCs in structure RPCs
	local function Splitted_Interfaces_RPCs(TestCaseName, IsExecutedAllResultCodes, IsExecutedAllRelatedRPCs)
		
		--CASE 1: Tested interface does not respond
		local function checksplit_Interfaces_RPCs_TestedInterface_does_not_Respond(TestCaseName)
			local TestData = {}
			if(IsExecutedAllResultCodes == true) then
				TestData = {
				
						{success = true, resultCode = "SUCCESS", 					 expected_resultCode = "SUCCESS", value = 0},
						{success = true, resultCode = "WARNINGS", 					 expected_resultCode = "WARNINGS", value = 21},
						{success = true, resultCode = "WRONG_LANGUAGE", 			 expected_resultCode = "WRONG_LANGUAGE", value = 16},
						{success = true, resultCode = "RETRY", 						 expected_resultCode = "RETRY", value = 7},
						{success = true, resultCode = "SAVED", 						 expected_resultCode = "SAVED", value = 25},
								
						{success = false, resultCode = "", 							 expected_resultCode = "GENERIC_ERROR", value = 22},
						{success = false, resultCode = "ABC", 						 expected_resultCode = "INVALID_DATA", value = 11},
						
						{success = false, resultCode = "UNSUPPORTED_REQUEST", 		 expected_resultCode = "UNSUPPORTED_REQUEST", value = 1},
						{success = false, resultCode = "DISALLOWED", 				 expected_resultCode = "DISALLOWED", value = 3},
						{success = false, resultCode = "USER_DISALLOWED", 			 expected_resultCode = "USER_DISALLOWED", value = 23},
						{success = false, resultCode = "REJECTED", 					 expected_resultCode = "REJECTED", value = 4},
						{success = false, resultCode = "ABORTED", 					 expected_resultCode = "ABORTED", value = 5},
						{success = false, resultCode = "IGNORED", 					 expected_resultCode = "IGNORED", value = 6},
						{success = false, resultCode = "IN_USE", 					 expected_resultCode = "IN_USE", value = 8},
						{success = false, resultCode = "DATA_NOT_AVAILABLE",         expected_resultCode = "DATA_NOT_AVAILABLE", value = 0},
						{success = false, resultCode = "TIMED_OUT", 				 expected_resultCode = "TIMED_OUT", value = 10},
						{success = false, resultCode = "INVALID_DATA", 				 expected_resultCode = "INVALID_DATA", value = 11},
						{success = false, resultCode = "CHAR_LIMIT_EXCEEDED", 		 expected_resultCode = "CHAR_LIMIT_EXCEEDED", value = 12},
						{success = false, resultCode = "INVALID_ID", 				 expected_resultCode = "INVALID_ID", value = 13},
						{success = false, resultCode = "DUPLICATE_NAME", 		     expected_resultCode = "DUPLICATE_NAME", value = 14},
						{success = false, resultCode = "APPLICATION_NOT_REGISTERED", expected_resultCode = "APPLICATION_NOT_REGISTERED", value = 15},
						{success = false, resultCode = "OUT_OF_MEMORY", 			 expected_resultCode = "OUT_OF_MEMORY", value = 17},
						{success = false, resultCode = "TOO_MANY_PENDING_REQUESTS",  expected_resultCode = "TOO_MANY_PENDING_REQUESTS", value = 18},
						{success = false, resultCode = "GENERIC_ERROR", 			 expected_resultCode = "GENERIC_ERROR", value = 22},
						{success = false, resultCode = "TRUNCATED_DATA", 			 expected_resultCode = "TRUNCATED_DATA", value = 24},
					}
			else
				TestData = { {success = true, resultCode = "SUCCESS", 				expected_resultCode = "SUCCESS", value = 0} }
			end
			
			
			-- All RPCs
			for i = 1, #TestData do
				local grammarID = 1

				for count_RPC = 1, #RPCs do
					local mob_request = mobile_request[count_RPC]
					local hmi_call = RPCs[count_RPC]
					local other_interfaces_call = {}			
					local hmi_method_call = TestedInterface.."."..hmi_call.name
					

					if(mob_request.splitted == true) then						
						if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then
							-- Preconditions should be executed only once.
							
								-- --Precondition: for RPC DeleteCommand: AddCommand 1
								--if(mob_request.name == "DeleteCommand" and TestData[i].resultCode == "SUCCESS") then
								if(mob_request.name == "DeleteCommand" ) then --and TestData[i].success == false) then
									Test["Precondition_AddCommand_"..TestData[i].value.."_"..TestCaseName] = function(self)
										--mobile side: sending AddCommand request
										local cid = self.mobileSession:SendRPC("AddCommand",
										{
											cmdID = TestData[i].value,
											vrCommands = {"vrCommands_"..TestData[i].value},
											menuParams = {position = 1, menuName = "Command "..TestData[i].value}
										})
										
										--hmi side: expect VR.AddCommand request
										EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = TestData[i].value,
											type = "Command",
											vrCommands = {"vrCommands_"..TestData[i].value}
										})
										:Do(function(_,data)
											--hmi side: sending VR.AddCommand response
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})						
											grammarID = data.params.grammarID
										end)
											
										--hmi side: expect UI.AddCommand request 
										EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = TestData[i].value,		
											menuParams = {position = 1, menuName ="Command "..TestData[i].value}
										})
										:Do(function(_,data)
											--hmi side: sending UI.AddCommand response
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
										end)
											
											
										--mobile side: expect AddCommand response
										EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

										--mobile side: expect OnHashChange notification
										if(mob_request.hashChange == true) then
											EXPECT_NOTIFICATION("OnHashChange")
											:Timeout(iTimeout)
										else
											EXPECT_NOTIFICATION("OnHashChange")
											:Times(0)
										end
									end
								end						
							
								--Precondition: for RPC PerformInteraction: CreateInteractionChoiceSet
								if(mob_request.name == "PerformInteraction") then
									Test["Precondition_PerformInteraction_CreateInteractionChoiceSet_" .. i.."_"..TestCaseName] = function(self)
										--mobile side: sending CreateInteractionChoiceSet request
										local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																			{
																				interactionChoiceSetID = TestData[i].value,
																				choiceSet = {{ 
																									choiceID = TestData[i].value,
																									menuName ="Choice" .. tostring(TestData[i].value),
																									vrCommands = 
																									{ 
																										"VrChoice" .. tostring(TestData[i].value),
																									}, 
																									image =
																									{ 
																										value ="icon.png",
																										imageType ="STATIC",
																									}
																							}}
																			})
									
										--hmi side: expect VR.AddCommand
										EXPECT_HMICALL("VR.AddCommand", 
												{ 
													cmdID = TestData[i].value,
													type = "Choice",
													vrCommands = {"VrChoice"..tostring(TestData[i].value) }
												})
										:Do(function(_,data)						
											--hmi side: sending VR.AddCommand response
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
											grammarID = data.params.grammarID
										end)		
									
										--mobile side: expect CreateInteractionChoiceSet response
										EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true  })

										EXPECT_NOTIFICATION("OnHashChange")

									end
								end	-- if(mob_request.name == "PerformInteraction")					
							
							Test["TC01_"..TestCaseName .. "_"..mob_request.name.."_"..TestedInterface.."_does_not_responds_OtherInterfaces_respond_".. tostring(TestData[i].resultCode)] = function(self)
								userPrint(33, "Testing RPC = "..RPCs[count_RPC].name)
								--======================================================================================================
								-- Update of used params
									if ( hmi_call.params.appID ~= nil ) then hmi_call.params.appID = self.applications[config.application1.registerAppInterfaceParams.appName] end

									if ( mob_request.params.cmdID      ~= nil ) then mob_request.params.cmdID = TestData[i].value end
									if ( mob_request.params.vrCommands ~= nil ) then mob_request.params.vrCommands =  {"vrCommands_" .. tostring(TestData[i].value)} end
									if ( mob_request.params.menuParams ~= nil ) then mob_request.params.menuParams =  {position = 1, menuName = "Command " .. tostring(TestData[i].value)} end

									if ( mob_request.params.interactionChoiceSetIDList ~= nil ) then mob_request.params.interactionChoiceSetIDList = {TestData[i].value} end
								--======================================================================================================
								commonTestCases:DelayedExp(iTimeout)
								local cid
								if( (hmi_method_call ~= "TTS.StopSpeaking") ) then
									--mobile side: sending RPC request
									cid = self.mobileSession:SendRPC(mob_request.name, mob_request.params)
								else -- TTS.StopSpeaking 
									cid = self.mobileSession:SendRPC("Alert", { 
																				alertText1 = "alertText1", alertText2 = "alertText2", alertText3 = "alertText3",
                                        							            ttsChunks = { { text = "TTSChunk", type = "TEXT",} },
                                        										duration = 3000,
                                        										playTone = false,
                                        										progressIndicator = false})
									EXPECT_HMICALL("UI.Alert", {})
									:Do(function(_,data)						

										--hmi side: sending VR.AddCommand response
										self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
									end)	
									
									EXPECT_HMICALL("TTS.Speak", {})
									:Do(function(_,data) 
									 	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
									end)
								end
								
								--hmi side: expect OtherInterfaces.RPC request
								for cnt = 1, #NotTestedInterfaces do

									for cnt_rpc = 1, #NotTestedInterfaces[cnt].usedRPC do
										local local_interface = NotTestedInterfaces[cnt].interface
										local local_rpc = NotTestedInterfaces[cnt].usedRPC[cnt_rpc].name
										local local_params = NotTestedInterfaces[cnt].usedRPC[cnt_rpc].params
								 		
										if (local_rpc == hmi_call.name) then
											--======================================================================================================
											-- Update of verified params
												if ( local_params.cmdID ~= nil )      then local_params.cmdID = TestData[i].value end
												if ( local_params.vrCommands ~= nil ) then local_params.vrCommands = {"vrCommands_" .. tostring(TestData[i].value)} end
												
												if ( local_params.menuParams ~= nil ) then local_params.menuParams =  {position = 1, menuName ="Command "..tostring(TestData[i].value)} end
				 								if ( local_params.appID ~= nil )      then local_params.appID = self.applications[config.application1.registerAppInterfaceParams.appName] end
				 								if ( local_params.choiceSet ~= nil )  then local_params.choiceSet = { { choiceID = TestData[i].value, menuName = "Choice" ..tostring(TestData[i].value)  }} end
				 								if ( local_params.grammarID ~= nil )  then 
											  		if (mob_request.name == "DeleteCommand" ) then
											  			local_params.grammarID =  grammarID  
													else
											  			local_params.grammarID[1] =  grammarID  
											  		end

											  	end
											--======================================================================================================
											if ( (TestData[i].success == false) and (mob_request.name == "DeleteSubMenu") ) then
												EXPECT_HMICALL(local_interface.."."..local_rpc, local_params)
												:Times(0)
											else									
												EXPECT_HMICALL(local_interface.."."..local_rpc, local_params)
												:Do(function(_,data)
													--hmi side: sending NotTestedInterface.RPC response
													if (TestData[i].resultCode == "") then
														-- HMI does not respond					
													else
														if TestData[i].success == true then 
															self.hmiConnection:SendResponse(data.id, data.method, TestData[i].resultCode, {})
														else
															--self.hmiConnection:SendError(data.id, data.method, TestData[i].resultCode, "error message")
															self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..data.method..'"},"code":'..tostring(TestData[i].value)..'}}')
														end						
													end
												end)
											end

										end -- if (local_rpc == hmi_call.name) then
									end --for cnt_rpc = 1, #NotTestedInterfaces[cnt].usedRPC do
								end --for cnt = 1, #NotTestedInterfaces do
								
								-- hmi side: sending tested interface response
								--======================================================================================================
								-- Update of verified params
									if ( hmi_call.params.cmdID ~= nil )      then hmi_call.params.cmdID = TestData[i].value end
									if ( hmi_call.params.type ~= nil ) 		 then hmi_call.params.type = "Command" end
									if ( hmi_call.params.menuParams ~= nil ) then hmi_call.params.menuParams =  {position = 1, menuName ="Command "..tostring(TestData[i].value)} end
									if ( hmi_call.params.vrCommands ~= nil ) then hmi_call.params.vrCommands = {"vrCommands_" .. tostring(TestData[i].value)} end
									if ( hmi_call.params.choiceSet ~= nil)   then hmi_call.params.choiceSet = { { choiceID = TestData[i].value, menuName = "Choice"..tostring(TestData[i].value) } } end
									if ( hmi_call.params.grammarID ~= nil )  then 
										if (mob_request.name == "DeleteCommand" ) then hmi_call.params.grammarID = grammarID  
										else hmi_call.params.grammarID[1] = grammarID  end
									end
								--======================================================================================================
								if ( TestData[i].success == false and (mob_request.name == "DeleteSubMenu")) then
									EXPECT_HMICALL(hmi_method_call, hmi_call.params)	
									:Times(0)
								else
									if (hmi_method_call == "TTS.StopSpeaking")  then hmi_call.params = nil end 
									EXPECT_HMICALL(hmi_method_call, hmi_call.params)
									:Do(function(_,data)
										if(mob_request.name == "AddCommand") then grammarID = data.params.grammarID end
										-- HMI does not respond							
									end)	
								end				

								if(mob_request.name == "Alert" or mob_request.name == "PerformAudioPassThru") then
									local SpeakId
									
									--hmi side: TTS.Speak request 
									EXPECT_HMICALL("TTS.Speak", {})
									:Do(function(_,data)
										self.hmiConnection:SendNotification("TTS.Started")
										SpeakId = data.id
										local function speakResponse()
											--self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
											self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak","code":'..TestData[i].value..'}}')
											self.hmiConnection:SendNotification("TTS.Stopped")
										end
											RUN_AFTER(speakResponse, 2000)

									end)
								end
								
								if ( TestData[i].success == false ) then
									if( mob_request.name == "DeleteSubMenu" ) then
										-- According to APPLINK-27079
										--mobile side: expect RPC response
										EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_ID"})
									--TODO: Update when APPLINK-13698 is resolved
									elseif(mob_request.name == "PerformInteraction") then
										EXPECT_RESPONSE(cid, {})
										:Times(0)
										:Timeout(11000)
										
									elseif(mob_request.name == "UnsubscribeVehicleData") then
										-- According to APPLINK-27872 and APPLINK-20043
										-- mobile side: expect RPC response
										EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED"})
									else
										--mobile side: expect AddCommand response
										EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
										--:Timeout(12000)
										:Timeout(15000)
									end
								else
									--TODO: Update when APPLINK-13698 is resolved
									if(mob_request.name == "PerformInteraction") then
										EXPECT_RESPONSE(cid, {})
										:Times(0)
										:Timeout(11000)
									else
										--mobile side: expect response to mobile
										EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
										--:Timeout(12000)
										:Timeout(15000)
									end
								end

								--mobile side: expect OnHashChange notification
								EXPECT_NOTIFICATION("OnHashChange")
								:Times(0)

								if (hmi_method_call == "TTS.StopSpeaking")  then hmi_call.params = {} end 
							end

							if(IsExecutedAllRelatedRPCs == false) then
								break --use break to exit the second for loop "for count_RPC = 1, #RPCs do"
							end
						end --if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then

					end --if(mob_request.splitted == true) then
				end --for count_RPC = 1, #RPCs do
			end -- for i = 1, #TestData do
		end
			
		checksplit_Interfaces_RPCs_TestedInterface_does_not_Respond(TestCaseName)

		--CASE 2: Other interfaces respond successful resultCodes. Tested interface responds UNSUPPORTED_RESOURCE
		--local function checksplit_VR_RPCs_VR_Responds_UNSUPPORTED_RESOURCE_Others_respond_success_resultCodes(TestCaseName)
		local function checksplit_TestedInterface_RPCs_Responds_UNSUPPORTED_RESOURCE_Others_respond_success_resultCodes(TestCaseName)
			local TestData = {}
			if(IsExecutedAllResultCodes == true) then
				TestData = {
					{resultCode = "SUCCESS", value = 0},
					{resultCode = "WARNINGS", value = 21},
					{resultCode = "WRONG_LANGUAGE", value = 16},
					{resultCode = "RETRY", value = 7},
					{resultCode = "SAVED", value = 25}
				}
			else
				TestData = { {resultCode = "SUCCESS", value = 0} }
			end
				
			-- 1. All RPCs
			for i = 1, #TestData do
				local grammarID = 1
			--for i = 1, 1 do
				for count_RPC = 1, #RPCs do
					local mob_request = mobile_request[count_RPC]
					local hmi_call = RPCs[count_RPC]
					local other_interfaces_call = {}			
					local hmi_method_call = TestedInterface.."."..hmi_call.name
					

					if(mob_request.splitted == true) then
						if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then
							-- Preconditions should be executed only once.
							--Precondition: for RPC PerformInteraction: CreateInteractionChoiceSet
								if(mob_request.name == "PerformInteraction") then
										Test["Precondition_PerformInteraction_Precondition_CreateInteractionChoiceSet_" .. TestData[i].value ..TestCaseName] = function(self)
											--mobile side: sending CreateInteractionChoiceSet request
											local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																					{
																						interactionChoiceSetID = TestData[i].value + 1,
																						choiceSet = {{ 
																											choiceID = TestData[i].value + 1,
																											menuName ="Choice" .. tostring(TestData[i].value + 1),
																											vrCommands = 
																											{ 
																												"VrChoice" .. tostring(TestData[i].value + 1),
																											}, 
																											image =
																											{ 
																												value ="icon.png",
																												imageType ="STATIC",
																											}
																									}}
																					})
											
											--hmi side: expect VR.AddCommand
											EXPECT_HMICALL("VR.AddCommand", 
														{ 
															cmdID = TestData[i].value + 1,
															type = "Choice",
															vrCommands = {"VrChoice"..tostring(TestData[i].value + 1) }
														})
											:Do(function(_,data)						
												--hmi side: sending VR.AddCommand response
												self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
												grammarID = data.params.grammarID
											end)		
											
											--mobile side: expect CreateInteractionChoiceSet response
											EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true  })

											EXPECT_NOTIFICATION("OnHashChange")
										end
								end
							
							Test["TC02_"..TestCaseName .. "_"..mob_request.name.."_"..TestedInterface.."_responds_UNSUPPORTED_RESOURCE_OtherInterfaces_respond_".. tostring(TestData[i].resultCode)] = function(self)
								userPrint(33, "Testing RPC = "..RPCs[count_RPC].name)
								commonTestCases:DelayedExp(iTimeout)
								--======================================================================================================
								-- Update of used params
								
								if ( mob_request.params.interactionChoiceSetIDList ~= nil) then mob_request.params.interactionChoiceSetIDList = {TestData[i].value + 1}end 
								if ( mob_request.params.appName ~= nil )                   then mob_request.params.appName = config.application1.registerAppInterfaceParams.appName end
								if ( mob_request.params.cmdID ~= nil )                     then mob_request.params.cmdID = TestData[i].value + 1 end
					 			if ( mob_request.params.menuParams ~= nil )                then mob_request.params.menuParams = {position = 1, menuName ="Command ".. tostring(TestData[i].value + 1)} end
					 			
					 			if ( mob_request.params.vrCommands ~= nil )                then mob_request.params.vrCommands = {"vrCommands_" .. tostring(TestData[i].value + 1)}	end
					 			if ( mob_request.params.appID ~= nil )                     then mob_request.params.appID = self.applications[config.application1.registerAppInterfaceParams.appName] end
					 			
								--======================================================================================================
								local cid
								if( (hmi_method_call ~= "TTS.StopSpeaking") ) then
									--mobile side: sending AddCommand request
									cid = self.mobileSession:SendRPC(mob_request.name, mob_request.params)
								else
									local DataID = 0
									cid = self.mobileSession:SendRPC("Alert", { 
																				alertText1 = "alertText1", alertText2 = "alertText2", alertText3 = "alertText3",
                                        							            ttsChunks = { { text = "TTSChunk", type = "TEXT",} },
                                        										duration = 3000,
                                        										playTone = false,
                                        										progressIndicator = false})
									EXPECT_HMICALL("UI.Alert", {})
									:Do(function(_,data)						

										DataID = data.id
									end)

									EXPECT_HMICALL("TTS.Speak", {})
									:Do(function(_,data)	

										-- UI.Response: SUCCESS
										self.hmiConnection:SendResponse(DataID, "UI.Alert", "SUCCESS", {})					

										local function speakResponse()
											self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..TestData[i].value..'}}')	
										end
									
										RUN_AFTER(speakResponse, 2000)
									end)
								end
									
								--hmi side: expect NotTested_Interface.RPC request
								for cnt = 1, #NotTestedInterfaces do
									for cnt_rpc = 1, #NotTestedInterfaces[cnt].usedRPC do
										
								 		local local_interface = NotTestedInterfaces[cnt].interface
								 		local local_rpc = NotTestedInterfaces[cnt].usedRPC[cnt_rpc].name
								 		local local_params = NotTestedInterfaces[cnt].usedRPC[cnt_rpc].params

									 		
								 		if (local_rpc == hmi_call.name) then
								 			--======================================================================================================
											-- Update of verified params
												if ( local_params.cmdID ~= nil )      then local_params.cmdID = (TestData[i].value + 1) end
												if ( local_params.menuParams ~= nil ) then local_params.menuParams =  {position = 1, menuName ="Command "..tostring(TestData[i].value + 1)} end
					 							if ( local_params.appID ~= nil )      then local_params.appID = self.applications[config.application1.registerAppInterfaceParams.appName] end
					 							if ( local_params.appHMIType ~= nil ) then local_params.appHMIType = config.application1.registerAppInterfaceParams.appHMIType end
					 							if ( local_params.appName ~= nil )    then local_params.appName = config.application1.registerAppInterfaceParams.appName end
					 							if ( local_params.vrCommands ~= nil ) then local_params.vrCommands = { "vrCommands_" .. tostring(TestData[i].value + 1) }end
					 							if ( local_params.choiceSet ~= nil)   then local_params.choiceSet = { { choiceID = (TestData[i].value + 1), menuName = "Choice"..tostring(TestData[i].value + 1) } } end
					 							if ( local_params.grammarID ~= nil ) then 
											  		if (mob_request.name == "DeleteCommand") then
											  			local_params.grammarID =  grammarID  
													else
											  			local_params.grammarID[1] =  grammarID  
											  		end
											  	end

											--======================================================================================================
											
											EXPECT_HMICALL(local_interface.."."..local_rpc, local_params)
											:Do(function(_,data)
												if(local_rpc == "AddCommand" and local_interface == "VR") then
													grammarID = data.params.grammarID
												end
												--hmi side: sending NotTestedInterface.RPC response
												--self.hmiConnection:SendResponse(data.id, data.method, TestData[i].resultCode, {})
												self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..TestData[i].value..'}}')	

											end)
								 		end --if (local_rpc == hmi_call.name) then
								 	end --for cnt_rpc = 1, #NotTestedInterfaces[cnt].usedRPC do
								end --for cnt = 1, #NotTestedInterfaces do
								

								-- hmi side: sending tested interface response
								--======================================================================================================
								-- Update of verified params
									if ( hmi_call.params.appID ~= nil )      				   then hmi_call.params.appID = self.applications[config.application1.registerAppInterfaceParams.appName] end
									if ( hmi_call.params.cmdID ~= nil ) 	 then hmi_call.params.cmdID = TestData[i].value + 1 end
									if ( hmi_call.params.type ~= nil ) 		 then hmi_call.params.type = "Command" end
									if ( hmi_call.params.vrCommands ~= nil ) then hmi_call.params.vrCommands = {"vrCommands_" .. tostring(TestData[i].value + 1)} end
									if ( hmi_call.params.menuParams ~= nil ) then hmi_call.params.menuParams.menuName = "Command " .. tostring(TestData[i].value + 1) end
									if ( hmi_call.params.choiceSet ~= nil)   then hmi_call.params.choiceSet = { { choiceID = (TestData[i].value + 1), menuName = "Choice"..tostring(TestData[i].value + 1) } } end
									if ( hmi_call.params.grammarID ~= nil ) then 
										if (mob_request.name == "DeleteCommand") then hmi_call.params.grammarID =  grammarID  
										else hmi_call.params.grammarID[1] =  grammarID  end
									end
								
								--======================================================================================================
								if (hmi_method_call == "TTS.StopSpeaking")  then hmi_call.params = nil end 

								EXPECT_HMICALL(hmi_method_call, hmi_call.params)
								:Do(function(_,data)
									if(hmi_method_call == "VR.AddCommand") then grammarID = data.params.grammarID end
									--hmi side: sending HMI response
									self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "error message")	
									--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..TestData[i].value..'}}')					
								end)		

								if(mob_request.name == "Alert" or mob_request.name == "PerformAudioPassThru" or mob_request.name == "AlertManeuver") then
									local SpeakId
									
									--hmi side: TTS.Speak request 
									EXPECT_HMICALL("TTS.Speak", {})
									:Do(function(_,data)
										self.hmiConnection:SendNotification("TTS.Started")
										SpeakId = data.id
										local function speakResponse()
											--self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
											self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"message":"error message", "method":"'..data.method..'","code":'..TestData[i].value..'}}')
											self.hmiConnection:SendNotification("TTS.Stopped")
										end
											RUN_AFTER(speakResponse, 2000)

										end)
								end
								local hmi_info = "error message"

								if (hmi_method_call == "TTS.StopSpeaking") then
									--mobile side: expect mobile response
									EXPECT_RESPONSE(cid, { success = true, resultCode = TestData[i].resultCode})
									:Timeout(12000)
								else
									--mobile side: expect mobile response
									EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = hmi_info})
									:Timeout(12000)
								end

								--mobile side: expect OnHashChange notification
								if(mob_request.hashChange == true) then
									EXPECT_NOTIFICATION("OnHashChange")
									:Timeout(iTimeout)
								else
									EXPECT_NOTIFICATION("OnHashChange")
									:Times(0)
								end
							end

							if(IsExecutedAllRelatedRPCs == false) then
								break --use break to exit the second for loop "for count_RPC = 1, #RPCs do"
							end
						end -- if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then
					end --if(mob_request.splitted == true) then

				end -- for count_RPC = 1, #RPCs do
			end -- for i = 1, #TestData do
		end
		
		checksplit_TestedInterface_RPCs_Responds_UNSUPPORTED_RESOURCE_Others_respond_success_resultCodes(TestCaseName)

		
		--CASE 3: Other interfaces respond unsuccessful resultCodes. Tested interface responds UNSUPPORTED_RESOURCE
		local function checksplit_Interface_RPCs_Responds_UNSUPPORTED_RESOURCE_Others_respond_unsuccess_resultCodes(TestCaseName)

			-- List of erroneous resultCodes (success:false)
			local TestData = {
			
								{resultCode = "UNSUPPORTED_REQUEST", value = 1			},
								{resultCode = "DISALLOWED", value = 3				},
								{resultCode = "USER_DISALLOWED", value = 23			},
								{resultCode = "REJECTED", value = 4					},
								{resultCode = "ABORTED", value = 5					},
								{resultCode = "IGNORED", value = 6					},
								{resultCode = "IN_USE", value = 8					},
								--{resultCode = "VEHICLE_DATA_NOT_AVAILABLE", value = 0},
								{resultCode = "TIMED_OUT", 	value = 10				},
								{resultCode = "INVALID_DATA", value = 11				},
								{resultCode = "CHAR_LIMIT_EXCEEDED", 	value = 12	},
								{resultCode = "INVALID_ID", 	value = 13			},
								{resultCode = "DUPLICATE_NAME", value = 14			},
								{resultCode = "APPLICATION_NOT_REGISTERED", value = 15},
								{resultCode = "OUT_OF_MEMORY", 		value = 17		},
								{resultCode = "TOO_MANY_PENDING_REQUESTS",value = 18 	},
								{resultCode = "GENERIC_ERROR", 		value = 22		},
								{resultCode = "TRUNCATED_DATA", 	value = 24		},
								{resultCode = "UNSUPPORTED_RESOURCE", value = 2		}
							}
									
			-- 1. All RPCs
			for i = 1, #TestData do
				local grammarID = 1	
			--for i = 1, 1 do
				for count_RPC = 1, #RPCs do
					local mob_request = commonFunctions:cloneTable(mobile_request[count_RPC])
					local hmi_call    = commonFunctions:cloneTable(RPCs[count_RPC])
					local other_interfaces_call = {}			
					local hmi_method_call = TestedInterface.."."..hmi_call.name

					if(mob_request.splitted == true) then
								
						if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then
							
						-- Preconditions should be executed only once.
							--Precondition: for RPC DeleteCommand: AddCommand 1
							if(mob_request.name == "DeleteCommand") then
								Test["Precondition_AddCommand_"..(TestData[i].value + 2).."_"..TestCaseName] = function(self)
									--mobile side: sending AddCommand request
									local cid = self.mobileSession:SendRPC("AddCommand",
									{
										cmdID = TestData[i].value + 2,
										vrCommands = {"vrCommands_"..TestData[i].value + 2},
										menuParams = {position = 1, menuName = "Command "..TestData[i].value + 2}
									})
										
									--hmi side: expect VR.AddCommand request
									EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = TestData[i].value + 2,
										type = "Command",
										vrCommands = {"vrCommands_"..TestData[i].value + 2}
									})
									:Do(function(_,data)
										--hmi side: sending VR.AddCommand response
										self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})						
										grammarID = data.params.grammarID
									end)
									
									--hmi side: expect UI.AddCommand request 
									EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = TestData[i].value + 2,		
										menuParams = {position = 1, menuName ="Command "..TestData[i].value + 2}
									})
									:Do(function(_,data)
										--hmi side: sending UI.AddCommand response
										self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
									end)
									
									
									--mobile side: expect AddCommand response
									EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})


									--mobile side: expect OnHashChange notification
									if(mob_request.hashChange == true) then
										EXPECT_NOTIFICATION("OnHashChange")
										:Timeout(iTimeout)
									else
										EXPECT_NOTIFICATION("OnHashChange")
										:Times(0)
									end
								end
							end
							--Precondition: for RPC PerformInteraction: CreateInteractionChoiceSet
							if(mob_request.name == "PerformInteraction") then
								Test["Precondition_PerformInteraction_CreateInteractionChoiceSet_" .. i ..TestCaseName] = function(self)
										
									--mobile side: sending CreateInteractionChoiceSet request
									local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																		{
																			interactionChoiceSetID = TestData[i].value + 2,
																			choiceSet = {{ 
																								choiceID = TestData[i].value + 2,
																								menuName ="Choice" .. tostring(TestData[i].value + 2),
																								vrCommands = 
																								{ 
																									"VrChoice" .. tostring(TestData[i].value + 2),
																								} 
																								--image =
																								--{ 
																									--value ="icon.png",
																									--imageType ="STATIC",
																								--}
																						}}
																		})
								
									--hmi side: expect VR.AddCommand
									EXPECT_HMICALL("VR.AddCommand", 
														{ 
															cmdID = TestData[i].value + 2,
															type = "Choice",
															vrCommands = {"VrChoice"..tostring(TestData[i].value + 2) }
														})
									:Do(function(_,data)						
											--hmi side: sending VR.AddCommand response
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
											grammarID = data.params.grammarID
									end)		
											
									--mobile side: expect CreateInteractionChoiceSet response
									EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true  })
									EXPECT_NOTIFICATION("OnHashChange")
								end
							end --if(mob_request.name == "PerformInteraction") then
						
							Test["TC03_"..TestCaseName .. "_"..mob_request.name.."_"..TestedInterface.."_responds_UNSUPPORTED_RESOURCE_OtherInterfaces_respond_".. tostring(TestData[i].resultCode)] = function(self)
								userPrint(33, "Testing RPC = "..RPCs[count_RPC].name)
								
								--======================================================================================================
								-- Update of used params
									if ( hmi_call.params.appID ~= nil )         then hmi_call.params.appID = self.applications[config.application1.registerAppInterfaceParams.appName] end
									if ( mob_request.params.cmdID ~= nil )      then mob_request.params.cmdID = (TestData[i].value + 2) end
						 			if ( mob_request.params.menuParams ~= nil ) then mob_request.params.menuParams =  {position = 1, menuName ="Command "..tostring(TestData[i].value + 2)} end
						 			if ( mob_request.params.vrCommands ~= nil ) then mob_request.params.vrCommands = {"vrCommands_" .. tostring(TestData[i].value + 2)} end
						 			if ( mob_request.params.interactionChoiceSetIDList ~= nil ) then mob_request.params.interactionChoiceSetIDList = {TestData[i].value + 2} end

								--======================================================================================================
						
								commonTestCases:DelayedExp(iTimeout)
								local cid
								if( (hmi_method_call ~= "TTS.StopSpeaking") ) then
									--mobile side: sending RPC request
									cid = self.mobileSession:SendRPC(mob_request.name, mob_request.params)
								else -- TTS.StopSpeaking 
									local DataID = 0
									cid = self.mobileSession:SendRPC("Alert", { 
																				alertText1 = "alertText1", alertText2 = "alertText2", alertText3 = "alertText3",
                                        							            ttsChunks = { { text = "TTSChunk", type = "TEXT",} },
                                        										duration = 3000,
                                        										playTone = false,
                                        										progressIndicator = false})
									EXPECT_HMICALL("UI.Alert", {})
									:Do(function(_,data)						

										DataID = data.id
									end)

									EXPECT_HMICALL("TTS.Speak", {})
									:Do(function(_,data)	

										-- UI.Response: SUCCESS
										self.hmiConnection:SendResponse(DataID, "UI.Alert", "SUCCESS", {})					

										local function speakResponse()
											--TTS.Speak
											self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..TestData[i].value..'}}')	
										end
									
										RUN_AFTER(speakResponse, 2000)
									end)	
								end
									
								--======================================================================================================
								-- Update of verified params
									if( hmi_call.params.cmdID ~= nil )       then hmi_call.params.cmdID = (TestData[i].value + 2) end
									if( hmi_call.params.type ~= nil )        then hmi_call.params.type = "Command" end
									if( hmi_call.params.vrCommands ~= nil )  then hmi_call.params.vrCommands = {"vrCommands_" .. tostring(TestData[i].value + 2)} end
									if( hmi_call.params.menuParams ~= nil )  then hmi_call.params.menuParams =  {position = 1, menuName ="Command "..tostring(TestData[i].value + 2)} end
									if( hmi_call.params.choiceSet ~= nil)    then hmi_call.params.choiceSet = { { choiceID = TestData[i].value + 2, menuName = "Choice"..tostring(TestData[i].value + 2) } } end
									if ( hmi_call.params.grammarID ~= nil ) then 
										if (mob_request.name == "DeleteCommand") then hmi_call.params.grammarID =  grammarID  
										else hmi_call.params.grammarID[1] =  grammarID  end
									end
								-- Update of verified params
								--======================================================================================================
								if (hmi_method_call == "TTS.StopSpeaking")  then hmi_call.params = nil end 

								--hmi side: expect TestedInterface.RPC request
								EXPECT_HMICALL(hmi_method_call, hmi_call.params)
								:Do(function(_,data)
									--hmi side: sending VR.AddCommand response
									self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "error message")
								end)
								

								for cnt = 1, #NotTestedInterfaces do
									for cnt_rpc = 1, #NotTestedInterfaces[cnt].usedRPC do
								 		local local_interface = NotTestedInterfaces[cnt].interface
								 		local local_rpc       = NotTestedInterfaces[cnt].usedRPC[cnt_rpc].name
								 		local local_params    = NotTestedInterfaces[cnt].usedRPC[cnt_rpc].params
								 		
								 		if (local_rpc == hmi_call.name) then
								 			--======================================================================================================
											-- Update of verified params
									 			if ( local_params.cmdID ~= nil )       then local_params.cmdID = TestData[i].value + 2 end
									 			if ( local_params.menuParams ~= nil )  then local_params.menuParams =  {position = 1, menuName ="Command "..tostring(TestData[i].value + 2)} end
									 			if ( local_params.appID ~= nil )       then local_params.appID = self.applications[config.application1.registerAppInterfaceParams.appName] end
									 			if ( local_params.vrCommands ~= nil )  then local_params.vrCommands = {"vrCommands_" .. tostring(TestData[i].value + 2)} end
									 			if ( local_params.choiceSet ~= nil)    then local_params.choiceSet = { { choiceID = TestData[i].value + 2, menuName = "Choice"..tostring(TestData[i].value + 2) } } end
									 			if ( local_params.grammarID ~= nil ) then 
													if (mob_request.name == "DeleteCommand") then local_params.grammarID =  grammarID  
																							 else local_params.grammarID[1] =  grammarID  end
												end
											--======================================================================================================
											
											--hmi side: expect OtherInterfaces.RPC request 
											EXPECT_HMICALL(local_interface.."."..local_rpc, local_params)
											:Do(function(_,data)
												--hmi side: sending UI.AddCommand response
												--self.hmiConnection:SendError(data.id, data.method, TestData[i].resultCode, "error message 2")
												self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..data.method..'"},"message":"error message 2","code":'..tostring(TestData[i].value)..'}}')
											end)
								 		end -- if (local_rpc == hmi_call.name) then
								 	end --for cnt_rpc = 1, #NotTestedInterfaces[cnt].usedRPC do
								end --for cnt = 1, #NotTestedInterfaces do

								if(mob_request.name == "Alert" or mob_request.name == "PerformAudioPassThru" or mob_request.name == "AlertManeuver") then
									local SpeakId
									
									--hmi side: TTS.Speak request 
									EXPECT_HMICALL("TTS.Speak", {})
									:Do(function(_,data)
										self.hmiConnection:SendNotification("TTS.Started")
										SpeakId = data.id
										local function speakResponse()
											self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..data.method..'"},"code":'..tostring(TestData[i].value)..'}}')
											--self.hmiConnection:SendError(SpeakId, "TTS.Speak", TestData[i].resultCode, { })
											self.hmiConnection:SendNotification("TTS.Stopped")
										end
											RUN_AFTER(speakResponse, 2000)

										end)
								end
								
								
								if(mob_request.name == "Alert") then
									--APPLINK-17008
									EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
									:Timeout(12000)
								elseif (hmi_method_call == "TTS.StopSpeaking") then
									--mobile side: expect mobile response
									EXPECT_RESPONSE(cid, { success = true, resultCode = TestData[i].resultCode})
									:Timeout(12000)
								else
									--TODO: APPLINK-27931: C;arification is expected
									--mobile side: expect AddCommand response
									EXPECT_RESPONSE(cid, { success = false, resultCode = TestData[i].resultCode})
									:ValidIf (function(_,data)
										if data.payload.info == "error message, error message 2" or data.payload.info == "error message 2, error message" then
											return true
										else
											commonFunctions:printError(" Expected 'info' = 'error message, error message 2' or 'error message 2, error message'; Actual 'info' = '" .. tostring(data.payload.info) .."'")
											return false
										end
									end)
									:Timeout(12000)
								end

								--mobile side: expect OnHashChange notification
								EXPECT_NOTIFICATION("OnHashChange")
								:Times(0)
							end

							if(IsExecutedAllRelatedRPCs == false) then
								break --use break to exit the second for loop "for count_RPC = 1, #RPCs do"
							end
						end --if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then
					end --if(mob_request.splitted == true) then
				end --for count_RPC = 1, #RPCs do
			end -- for i = 1, #TestData do
		end
		
		checksplit_Interface_RPCs_Responds_UNSUPPORTED_RESOURCE_Others_respond_unsuccess_resultCodes(TestCaseName)

	end

	for i=1, #TestData do
	--	for i=1, 1 do
		local TestCaseName = "Case_" .. TestData[i].caseID .. "_IsReady_" ..TestData[i].description
				
		
		
		if( i == 1) then
			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup(TestCaseName)
		
			isReady:StopStartSDL_HMI_MOBILE(self, TestData[i].caseID, TestCaseName)

			-- Description: Register app for precondition
			commonSteps:RegisterAppInterface("Precondition_RegisterAppInterface_" .. TestCaseName)
		
			-- Description: Activation app for precondition
			commonSteps:ActivationApp(nil, "Precondition_ActivationApp_" .. TestCaseName)

			commonSteps:PutFile("PutFile_MinLength", "a")
			commonSteps:PutFile("PutFile_icon.png", "icon.png")
			commonSteps:PutFile("PutFile_action.png", "action.png")

			-- execute test for all resultCodes and all related RPCs of the testing interface
			Splitted_Interfaces_RPCs(TestCaseName, true, true)
		else
			-- Tested_wrongJSON is defined in general lua script for execution
			-- if Tested_wrongJSON is not defined by default will be set to true. Test will be executed.
			if(Tested_wrongJSON == true) then

				--Print new line to separate new test cases group
				commonFunctions:newTestCasesGroup(TestCaseName)
		
				isReady:StopStartSDL_HMI_MOBILE(self, TestData[i].caseID, TestCaseName)

				-- Description: Register app for precondition
				commonSteps:RegisterAppInterface("Precondition_RegisterAppInterface_" .. TestCaseName)
		
				-- Description: Activation app for precondition
				commonSteps:ActivationApp(nil, "Precondition_ActivationApp_" .. TestCaseName)

				commonSteps:PutFile("PutFile_MinLength", "a")
				commonSteps:PutFile("PutFile_icon.png", "icon.png")
				commonSteps:PutFile("PutFile_action.png", "action.png")

				-- execute test for only one resultCode (SUCCESS) and the first related RPC of the testing interface
				Splitted_Interfaces_RPCs(TestCaseName, false, false)
			end
		end
		
	
	end


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
--Not applicable

	function Test:Postcondition_RestorePreloadedFile()
		commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
	end

	function Test.Postcondition_Stop()
	  StopSDL()
	end

return Test