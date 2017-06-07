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
	local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
	local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
	config.SDLStoragePath = commonPreconditions:GetPathToSDL() .. "storage/"
	DefaultTimeout = 3
	local iTimeout = 3000

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
---------------------------------------- Local functions ------------------------------------
---------------------------------------------------------------------------------------------
	local function userPrint( color, message)
	  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
	end


---------------------------------------------------------------------------------------------
------------------------------------ Common variables ---------------------------------------
---------------------------------------------------------------------------------------------
	local RPCs = commonFunctions:cloneTable(isReady.RPCs)
	local mobile_request = commonFunctions:cloneTable(isReady.mobile_request)
	local NotTestedInterfaces = commonFunctions:cloneTable(isReady.NotTestedInterfaces)
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

--Not applicable

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------
-- Not applicable 

----------------------------------------------------------------------------------------------
----------------------------------------TEST BLOCK II-----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

-- Not applicable

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

	--List of CRQs:	
		--CRQ #1) 
			-- VR:  APPLINK-25042: [VR Interface] VR.IsReady(false) -> HMI respond with successfull resultCode to splitted RPC
			-- UI:  APPLINK-25102: [UI Interface] UI.IsReady(false) -> HMI respond with successfull resultCode to splitted RPC
			-- TTS: APPLINK-25133: [TTS Interface] TTS.IsReady(false) -> HMI respond with successfull resultCode to splitted RPC
			-- VehicleInfo: Not applicable
			-- Navigation: Not applicable
		--CRQ #2) 
			-- VR:  APPLINK-25043: [VR Interface] VR.IsReady(false) -> HMI respond with errorCode to splitted RPC
			-- UI:  APPLINK-25100: [UI Interface] UI.IsReady(false) -> HMI respond with errorCode to splitted RPC
			-- TTS: APPLINK-25134: [TTS Interface] TTS.IsReady(false) -> HMI respond with errorCode to splitted RPC
			-- VehicleInfo: Not applicable
			-- Navigation:  Not applicable
		
		

		
	local TestCaseName = TestedInterface .."_IsReady_response_availabe_false"
		
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup(TestCaseName)
		
	isReady:StopStartSDL_HMI_MOBILE(self, 0, TestCaseName)
		
			
	-----------------------------------------------------------------------------------------------
	--CRQ #1) 
			-- VR:  APPLINK-25042: [VR Interface] VR.IsReady(false) -> HMI respond with successfull resultCode to splitted RPC
			-- UI:  APPLINK-25102: [UI Interface] UI.IsReady(false) -> HMI respond with successfull resultCode to splitted RPC
			-- TTS: APPLINK-25133: [TTS Interface] TTS.IsReady(false) -> HMI respond with successfull resultCode to splitted RPC
			-- VehicleInfo: Not applicable
			-- Navigation: Not applicable
	-- Verification criteria:
		-- In case SDL receives TestedInterface.IsReady (available=false) from HMI
		-- and mobile app sends RPC to SDL that must be split to:
		-- -> TestedInterface RPC
		-- -> any other <Interface>.RPC
		-- SDL must:
		-- transfer only <Interface>.RPC to HMI (in case <Interface> is supported by system)
		-- respond with 'UNSUPPORTED_RESOURCE, success:true,' + 'info: TestedInterface is not supported by system' to mobile app IN CASE <Interface>.RPC was successfully processed by HMI (please see list with resultCodes below)
	
	-----------------------------------------------------------------------------------------------	
	commonSteps:RegisterAppInterface("Precondition_RegisterAppInterface_"..TestCaseName)
		
	-- Description: Activation app for precondition
	commonSteps:ActivationApp( nil, "Precondition_ActivationApp_"..TestCaseName)

	commonSteps:PutFile("PutFile_MinLength", "a")
	commonSteps:PutFile("PutFile_icon.png", "icon.png")
	commonSteps:PutFile("PutFile_action.png", "action.png")

	-- For VehicleInfo specified requirements are not applicable.
	if(TestedInterface ~= "VehicleInfo") then
		--local function VR_IsReady_response_availabe_false_check_split_RPC_Other_Interfaces_Responds_SUCCESS(TestCaseName)
		local function Interface_IsReady_response_availabe_false_check_split_RPC_Other_Interfaces_Responds_SUCCESS(TestCaseName)

			-- List of successful resultCodes (success:true)
			local TestData = {
								{resultCode = "SUCCESS", 		info = TestedInterface .." is not supported by system", value = 0},
								{resultCode = "WARNINGS", 		info = TestedInterface .." is not supported by system", value = 21},
								{resultCode = "WRONG_LANGUAGE", info = TestedInterface .." is not supported by system", value = 16},
								{resultCode = "RETRY", 			info = TestedInterface .." is not supported by system", value = 7},
								{resultCode = "SAVED", 			info = TestedInterface .." is not supported by system", value = 25}
							}

			-- All applicable RPCs
			for i = 1, #TestData do
			--for i = 1, 1 do
				for count_RPC = 1, #RPCs do
					local mob_request = mobile_request[count_RPC]
					local hmi_call = RPCs[count_RPC]
					local other_interfaces_call = {}			
					local hmi_method_call = TestedInterface.."."..hmi_call.name
					local vrCmd = ""
					local local_menuparams = ""

					if(mob_request.splitted == true) then
						if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then
											
							--Precondition: for RPC PerformInteraction: CreateInteractionChoiceSet
							if(mob_request.name == "PerformInteraction") then
								if(TestedInterface ~= "VR") then
									Test["Precondition_PerformInteraction_CreateInteractionChoiceSet_" .. TestData[i].value.."_"..TestCaseName] = function(self)
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
										:Timeout(iTimeout)
									end
								end
							end	-- if(mob_request.name == "PerformInteraction")					
					

							Test["TC01_"..TestCaseName .. "_"..mob_request.name.."_UNSUPPORTED_RESOURCE_true_Incase_OtherInterfaces_responds_" .. TestData[i].resultCode] = function(self)
								userPrint(33, "Testing RPC = "..mob_request.name)
								-- if(TestData[i].resultCode == "SAVED") then
								-- 	 print ("\27[31m ATF defect should be created for HMI result_code SAVED. Please investigate! \27[0m")
								-- end
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
								else
									--APPLINK-29183
									local DataID = 0
									cid = self.mobileSession:SendRPC("Alert", { 
																				alertText1 = "alertText1", alertText2 = "alertText2", alertText3 = "alertText3",
                                        							            ttsChunks = { { text = "TTSChunk", type = "TEXT",} },
                                        										duration = 3000,
                                        										playTone = false,
                                        										progressIndicator = false})
									EXPECT_HMICALL("UI.Alert", {})
									:Do(function(_,data)						
										self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..TestData[i].value..'}}')
									end)

									EXPECT_HMICALL("TTS.Speak", {})
									:Times(0)

								end
									
								--hmi side: expect Interface.RPC request 	
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
					 							if ( local_params.grammarID ~= nil ) then 
											  		if (mob_request.name == "DeleteCommand") then
											  			local_params.grammarID =  grammarID  
													else
											  			local_params.grammarID[1] =  grammarID  
											  		end
											  	end
											--======================================================================================================
											if(hmi_method_call == "VR.PerformInteraction") then
												--APPLINK-17062
												EXPECT_HMICALL(local_interface.."."..local_rpc,{})
												:Times(0)
											else
								 				EXPECT_HMICALL(local_interface.."."..local_rpc, local_params)
												:Do(function(_,data)
													--hmi side: sending Interface.RPC response 
													--self.hmiConnection:SendResponse(data.id, data.method, TestData[i].resultCode, {})
													self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..TestData[i].value..'}}')	
												end)	
											end
							 			end --if (local_rpc == hmi_call.name) then
							 		end--for cnt_rpc = 1, #NotTestedInterfaces[cnt].usedRPC do
								end--for cnt = 1, #NotTestedInterfaces do

								if(mob_request.name == "Alert" or mob_request.name == "PerformAudioPassThru" or mob_request.name == "AlertManeuver" ) then
									local SpeakId
									
									--hmi side: TTS.Speak request 
									EXPECT_HMICALL("TTS.Speak", {})
									:Do(function(_,data)
										self.hmiConnection:SendNotification("TTS.Started")
										SpeakId = data.id
										local function speakResponse()
											self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak","code":'..TestData[i].value..'}}')
											--self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
											self.hmiConnection:SendNotification("TTS.Stopped")
										end
											RUN_AFTER(speakResponse, 2000)

										end)
								end
								
								--hmi side: expect there is no request is sent to the testing interface.
								EXPECT_HMICALL(hmi_method_call, {})
								:Times(0)
								
								if(hmi_method_call == "VR.PerformInteraction") then
									--APPLINK-17062
									--mobile side: expect RPC response
									EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_ID"})
									:Timeout(iTimeout)
								else
									--mobile side: expect RPC response
									EXPECT_RESPONSE(cid, {success = true, resultCode = "UNSUPPORTED_RESOURCE", info = TestData[i].info})
									:Timeout(iTimeout)
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
						end --if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then
					end --if(mob_request.splitted == true) then
				end --for count_RPC = 1, #RPCs do
			end --for i = 1, #TestData do
		end

		--VR_IsReady_response_availabe_false_check_split_RPC_Other_Interfaces_Responds_SUCCESS("VR_IsReady_availabe_false_split_RPC_SUCCESS")
		Interface_IsReady_response_availabe_false_check_split_RPC_Other_Interfaces_Responds_SUCCESS(TestedInterface .."_IsReady_availabe_false_split_RPC_SUCCESS")
	else
		print("\27[31m This case is not applicable for "..TestedInterface .." \27[0m")
	end -- if( (TestedInterface ~= "VehicleInfo") then
		
		
	-----------------------------------------------------------------------------------------------	
	--CRQ #2) 
			-- VR:  APPLINK-25043: [VR Interface] VR.IsReady(false) -> HMI respond with errorCode to splitted RPC
			-- UI:  APPLINK-25100: [UI Interface] UI.IsReady(false) -> HMI respond with errorCode to splitted RPC
			-- TTS: APPLINK-25134: [TTS Interface] TTS.IsReady(false) -> HMI respond with errorCode to splitted RPC
			-- VehicleInfo: Not applicable
			-- Navigation:  Not applicable
	--Verification criteria:
		-- In case SDL receives TestedInterface.IsReady (available=false) from HMI
		-- and mobile app sends RPC to SDL that must be split to:
		-- -> TestedInterface RPC
		-- -> any other <Interface>.RPC 
		-- SDL must:
		-- transfer only <Interface>.RPC to HMI (in case <Interface> is supported by system)
		-- respond with '<received_errorCode_from_HMI>' to mobile app IN CASE <Interface>.RPC got any erroneous resultCode from HMI (please see list with resultCodes below)
	-----------------------------------------------------------------------------------------------	
	-- Updated according to APPLINK-26900
	-- For VehicleInfo specified requirements are not applicable.
	if (TestedInterface ~= "VehicleInfo")  then	

		--local function VR_IsReady_response_availabe_false_check_split_RPC_Other_Interfaces_Responds_Error(TestCaseName)
		local function Interface_IsReady_response_availabe_false_check_split_RPC_Other_Interfaces_Responds_Error(TestCaseName)
				
				-- List of erroneous resultCodes (success:false)
				local TestData = {
				
							{resultCode = "UNSUPPORTED_REQUEST", 		info = "Error message", value = 1},
							{resultCode = "UNSUPPORTED_REQUEST", 		info = nil, 			value = 1},
							{resultCode = "DISALLOWED", 				info = "Error message", value = 3},
							{resultCode = "DISALLOWED", 				info = nil, 			value = 3},
							{resultCode = "USER_DISALLOWED", 			info = "Error message", value = 23},
							{resultCode = "USER_DISALLOWED", 			info = nil,				value = 23},
							{resultCode = "REJECTED", 					info = "Error message", value = 4},
							{resultCode = "REJECTED", 					info = nil, 			value = 4},
							{resultCode = "ABORTED", 					info = "Error message", value = 5},
							{resultCode = "ABORTED", 					info = nil, 			value = 5},
							{resultCode = "IGNORED", 					info = "Error message", value = 6},
							{resultCode = "IGNORED", 					info = nil, 			value = 6},
							{resultCode = "IN_USE", 					info = "Error message", value = 8},
							{resultCode = "DATA_NOT_AVAILABLE", 		info = "Error message", value = 9},
							{resultCode = "DATA_NOT_AVAILABLE", 		info = nil, 			value = 9},
							{resultCode = "TIMED_OUT", 					info = "Error message", value = 10},
							{resultCode = "TIMED_OUT", 					info = nil, 			value = 10},
							{resultCode = "INVALID_DATA", 				info = "Error message", value = 11},
							{resultCode = "INVALID_DATA", 				info = nil, 			value = 11},
							{resultCode = "CHAR_LIMIT_EXCEEDED", 		info = "Error message", value = 12},
							{resultCode = "CHAR_LIMIT_EXCEEDED", 		info = nil, 			value = 12},
							{resultCode = "INVALID_ID", 				info = "Error message", value = 13},
							{resultCode = "INVALID_ID", 				info = nil, 			value = 13},
							{resultCode = "DUPLICATE_NAME", 			info = "Error message", value = 14},
							{resultCode = "DUPLICATE_NAME", 			info = nil, 			value = 14},
							{resultCode = "APPLICATION_NOT_REGISTERED", info = "Error message", value = 15},
							{resultCode = "APPLICATION_NOT_REGISTERED", info = nil, 			value = 15},
							{resultCode = "OUT_OF_MEMORY", 				info = "Error message", value = 17},
							{resultCode = "OUT_OF_MEMORY", 				info = nil, 			value = 17},
							{resultCode = "TOO_MANY_PENDING_REQUESTS", 	info = "Error message", value = 18},
							{resultCode = "TOO_MANY_PENDING_REQUESTS", 	info = nil, 			value = 18},
							{resultCode = "GENERIC_ERROR", 				info = "Error message", value = 22},
							{resultCode = "GENERIC_ERROR", 				info = nil, 			value = 22},
							{resultCode = "TRUNCATED_DATA", 			info = "Error message", value = 24},
							{resultCode = "TRUNCATED_DATA", 			info = nil, 			value = 24},
							{resultCode = "UNSUPPORTED_RESOURCE", 		info = "Error message", value = 2},
							{resultCode = "UNSUPPORTED_RESOURCE", 		info = nil, 			value = 2},
							{resultCode = "NOT_RESPOND", 				info = "Error message", value = 33},
							{resultCode = "NOT_RESPOND", 				info = nil, 			value = 33},
							{resultCode = "IsNotExist", 				info = "Error message", value = 26},
							{resultCode = "IsNotExist", 				info = nil, 			value = 26}
						}		
			
				-- All RPCs		
				for i = 1, #TestData do
				--for i = 1, 1 do
					for count_RPC = 1, #RPCs do
						local mob_request = mobile_request[count_RPC]
						local hmi_call = RPCs[count_RPC]
						local other_interfaces_call = {}			
						local hmi_method_call = TestedInterface.."."..hmi_call.name
						
						if(mob_request.splitted == true) then
							if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then
							--if( i == 1) then
								-- Precondition: for RPC DeleteCommand
								if(mob_request.name == "DeleteCommand") then
									Test["Precondition_AddCommand_1_"..TestCaseName] = function(self)
										--mobile side: sending AddCommand request
										local cid
										if(TestedInterface == "UI") then
											cid = self.mobileSession:SendRPC("AddCommand",
																							{
																								cmdID = i,
																								vrCommands = {"vrCommands_"..i},
																								--menuParams = {position = 1, menuName = "Command 1"}
																							})
											--hmi side: expect VR.AddCommand request
											EXPECT_HMICALL("VR.AddCommand", 
											{ 
												cmdID = i,
												type = "Command",
												vrCommands = {"vrCommands_"..i}
											})
											:Do(function(_,data)
												--hmi side: sending VR.AddCommand response
												self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})						
												grammarID = data.params.grammarID
											end)
										else
											cid = self.mobileSession:SendRPC("AddCommand",
																							{
																								cmdID = i,
																								--vrCommands = {"vrCommands_1"},
																								menuParams = {position = 1, menuName = "Command "..i}
																							})
											--hmi side: expect UI.AddCommand request 
											EXPECT_HMICALL("UI.AddCommand", 
											{ 
												cmdID = i,		
												menuParams = {position = 1, menuName ="Command "..i}
											})
											:Do(function(_,data)
												--hmi side: sending UI.AddCommand response
												self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
											end)
										end
											
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
									if(TestedInterface ~= "VR") then
										Test["Precondition_PerformInteraction_CreateInteractionChoiceSet_" .. i.."_"..TestCaseName] = function(self)
											--mobile side: sending CreateInteractionChoiceSet request
											local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																				{
																					interactionChoiceSetID = i,
																					choiceSet = {{ 
																										choiceID = i,
																										menuName ="Choice" .. tostring(i),
																										vrCommands = 
																										{ 
																											"VrChoice" .. tostring(i),
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
														cmdID = i,
														type = "Choice",
														vrCommands = {"VrChoice"..tostring(i) }
													})
											:Do(function(_,data)						
												--hmi side: sending VR.AddCommand response
												self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

												grammarID = data.params.grammarID
											end)		
										
											--mobile side: expect CreateInteractionChoiceSet response
											EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true  })
											
											--mobile side: expect OnHashChange notification
											EXPECT_NOTIFICATION("OnHashChange")
									
										end
									end
								end	-- if(mob_request.name == "PerformInteraction")					
							--end --if( i == 1)
						
							Test["TC02_"..TestCaseName .. "_"..mob_request.name.."_" .. TestData[i].resultCode .. "_false_Incase_OtherInterfaces_responds" .. TestData[i].resultCode] = function(self)
								userPrint(33, "Testing RPC = "..mob_request.name)
								--======================================================================================================
								-- Update of used params
									if ( hmi_call.params.appID ~= nil ) then hmi_call.params.appID = self.applications[config.application1.registerAppInterfaceParams.appName] end

									if ( mob_request.params.cmdID      ~= nil ) then mob_request.params.cmdID = i end
									if ( mob_request.params.vrCommands ~= nil ) then mob_request.params.vrCommands =  {"vrCommands_" .. tostring(i)} end
									if ( mob_request.params.menuParams ~= nil ) then mob_request.params.menuParams =  {position = 1, menuName = "Command " .. tostring(i)} end
									if ( mob_request.params.interactionChoiceSetIDList ~= nil ) then mob_request.params.interactionChoiceSetIDList = {i} end
								--======================================================================================================
								
								commonTestCases:DelayedExp(iTimeout)
						
								local cid
								if( (hmi_method_call ~= "TTS.StopSpeaking") ) then
									--mobile side: sending RPC request
									cid = self.mobileSession:SendRPC(mob_request.name, mob_request.params)
								else
									--APPLINK-29183
									local DataID = 0
									cid = self.mobileSession:SendRPC("Alert", { 
																				alertText1 = "alertText1", alertText2 = "alertText2", alertText3 = "alertText3",
                                        							            ttsChunks = { { text = "TTSChunk", type = "TEXT",} },
                                        										duration = 3000,
                                        										playTone = false,
                                        										progressIndicator = false})
									EXPECT_HMICALL("UI.Alert", {})
									:Do(function(_,data)						
										if TestData[i].resultCode == "NOT_RESPOND" then
													--HMI does not respond
										else
											-- self.hmiConnection:SendError(data.id, data.method, TestData[i].resultCode, TestData[i].info)
											-- Use Send() function because it is required to verify resultCode is invalid (not in [0, 25])
											if TestData[i].info == nil then									
												self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..data.method..'"},"code":'..tostring(TestData[i].value)..'}}')				
											else													
												self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..data.method..'"},"message":"'.. TestData[i].info .. '","code":'..tostring(TestData[i].value)..'}}')
											end
										end
									end)

									EXPECT_HMICALL("TTS.Speak", {})
									:Times(0)
								end
									
								--hmi side: expect UI.AddCommand request 
								for cnt = 1, #NotTestedInterfaces do
									
									for cnt_rpc = 1, #NotTestedInterfaces[cnt].usedRPC do
								 		local local_interface = NotTestedInterfaces[cnt].interface
								 		local local_rpc = NotTestedInterfaces[cnt].usedRPC[cnt_rpc].name
								 		local local_params = NotTestedInterfaces[cnt].usedRPC[cnt_rpc].params
								 		
								 		if (local_rpc == hmi_call.name) then
								 			--======================================================================================================
											-- Update of verified params
												if ( local_params.cmdID ~= nil )      then local_params.cmdID = i end
												if ( local_params.vrCommands ~= nil ) then local_params.vrCommands = {"vrCommands_" .. tostring(i)} end
												
												if ( local_params.menuParams ~= nil ) then local_params.menuParams =  {position = 1, menuName ="Command "..tostring(i)} end
				 								if ( local_params.appID ~= nil )      then local_params.appID = self.applications[config.application1.registerAppInterfaceParams.appName] end
				 								if ( local_params.grammarID ~= nil ) then 
											  		if (mob_request.name == "DeleteCommand") then
											  			local_params.grammarID =  grammarID  
													else
											  			local_params.grammarID[1] =  grammarID  
											  		end
											  	end
											--======================================================================================================
											if(hmi_method_call == "VR.PerformInteraction") then
												--APPLINK-17062
												EXPECT_HMICALL(local_interface.."."..local_rpc,{})
												:Times(0)
											else
									 			EXPECT_HMICALL(local_interface.."."..local_rpc, local_params)
												:Do(function(_,data)
													--hmi side: sending Interface.RPC response 
													if TestData[i].resultCode == "NOT_RESPOND" then
														--HMI does not respond
													else
														-- self.hmiConnection:SendError(data.id, data.method, TestData[i].resultCode, TestData[i].info)
														-- Use Send() function because it is required to verify resultCode is invalid (not in [0, 25])
														if TestData[i].info == nil then													
															self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..data.method..'"},"code":'..tostring(TestData[i].value)..'}}')
														else													
															self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..data.method..'"},"message":"'.. TestData[i].info .. '","code":'..tostring(TestData[i].value)..'}}')
														end
													end
												end)	
											end
								 		end
								 	end --for cnt_rpc = 1, #NotTestedInterfaces[cnt].usedRPC do
								end --for cnt = 1, #NotTestedInterfaces do
								
								if(mob_request.name == "Alert" or mob_request.name == "PerformAudioPassThru" or mob_request.name == "AlertManeuver") then
									
									--hmi side: TTS.Speak request 
									EXPECT_HMICALL("TTS.Speak", {})
									:Do(function(_,data)
										self.hmiConnection:SendNotification("TTS.Started")
					
										local function speakResponse()
											--self.hmiConnection:SendError(data.id, data.method, TestData[i].resultCode, TestData[i].info)
											-- Use Send() function because it is required to verify resultCode is invalid (not in [0, 25])
											if TestData[i].info == nil then													
												self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..data.method..'"},"code":'..tostring(TestData[i].value)..'}}')
											else													
												self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..data.method..'"},"message":"'.. TestData[i].info .. '","code":'..tostring(TestData[i].value)..'}}')
											end
											
											
											self.hmiConnection:SendNotification("TTS.Stopped")
										end
											RUN_AFTER(speakResponse, 2000)

										end)
								end
								--hmi side: expect there is no request is sent to the testing interface.
								EXPECT_HMICALL(hmi_method_call, {})
								:Times(0)
								
								--mobile side: expect RPC response
								if ( TestData[i].resultCode == "NOT_RESPOND" ) then
									EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
									:Timeout(12000)
								-- APPLINK-15494 SDL must handle the invalid responses from HMI
								elseif(hmi_method_call == "VR.PerformInteraction") then
									--APPLINK-17062
									--mobile side: expect RPC response
									EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_ID"})
									:Timeout(iTimeout)
								elseif ( TestData[i].resultCode == "IsNotExist" ) then

									EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from "})
								else
									
									EXPECT_RESPONSE(cid, {success = false, resultCode = TestData[i].resultCode})
									:ValidIf (function(_,data)
										-- APPLINK-26900  SDL receives errorCode and with error message from other interface, SDL responds to mobile with info = error message from other interface
										-- APPLINK-28100:
										-- verify info parameter is omitted if HMI does not sent message parameter in response
										-- "Message" is optional param for all responses from HMI side - HMI just provide the info regarding processing of requests. As result, in case HMI provides "message" or not - it will be still valid response
										if TestData[i].info == nil then 
											if data.payload.info ~= nil  then
												commonFunctions:printError(" Expected result: info is omitted; Actual result: info = '" .. data.payload.info .. "'")
												return false
											else
												return true
											end
										else
											if(mob_request.name == "ChangeRegistration") then TestData[i].info = "Error message, Error message" end
											-- APPLINK-26900  SDL receives errorCode and with error message from other interface, SDL responds to mobile with info = error message from other interface
											if data.payload.info ~= TestData[i].info then
												if (data.payload.info ~= nil) then 
													commonFunctions:printError(" Expected result: info = '".. TestData[i].info .."'; Actual result: info = '" .. data.payload.info .. "'")
													return false
												else
													commonFunctions:printError(" Expected result: info = '".. TestData[i].info .."'; Actual result: info is nil'")
													return false
												end

											else
												return true
											end
										end
									end)
									
								end
								
								--mobile side: expect OnHashChange notification is not sent
								EXPECT_NOTIFICATION("OnHashChange")
								:Times(0)
							end
							
							
							end --if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then
						end --if(mob_request.splitted == true) then
					end --for count_RPC = 1, #RPCs do
				end -- for i = 1, #TestData do
		end
			
		--VR_IsReady_response_availabe_false_check_split_RPC_Other_Interfaces_Responds_Error("VR_IsReady_availabe_false_split_RPC_Unsuccess")
		Interface_IsReady_response_availabe_false_check_split_RPC_Other_Interfaces_Responds_Error(TestedInterface .."_IsReady_availabe_false_split_RPC_Unsuccess")
		--end
	else
		print("\27[31m This case is not applicable for "..TestedInterface .." \27[0m")
	end --if (TestedInterface ~= "VehicleInfo")  then
	


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
-- Not applicable

	function Test:Postcondition_RestorePreloadedFile()
		commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
	end

	function Test.Postcondition_StopSDL()
	  StopSDL()
	end

return Test
