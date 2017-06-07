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
-------------------------------------------Common variables-----------------------------------
---------------------------------------------------------------------------------------------
	local RPCs = commonFunctions:cloneTable(isReady.RPCs)
	local mobile_request = commonFunctions:cloneTable(isReady.mobile_request)

---------------------------------------------------------------------------------------------
-------------------------------------------Local functions-----------------------------------
---------------------------------------------------------------------------------------------
	local function userPrint( color, message)
	  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
	end

    function table.val_to_str ( v )
      if "string" == type( v ) then
        v = string.gsub( v, "\n", "\\n" )
        if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
        	print("1 -> ".. "'" .. v .. "'")
          return "'" .. v .. "'"
        end
        print("v = "..v)
        print("2 ->".. '"' .. string.gsub(v,'"', '\\"' ) .. '"')
        return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
      else

        return --"table" == type( v ) --[[and table.tostring( v )]] or
          tostring( v )
      end
    end

    function table.key_to_str ( k )
      if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
      	print("3->".. k)
        return k
      else
        return "[" .. table.val_to_str( k ) .. "]"
      end
    end

    function table.tostring( tbl )
      local result, done = {}, {}
      for k, v in ipairs( tbl ) do
      	print("4->"..table.val_to_str( v ) )
        table.insert( result, table.val_to_str( v ) )
        done[ k ] = true
      end
      for k, v in pairs( tbl ) do
        if not done[ k ] then
          table.insert( result,
            table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
        end
      end
      return table.concat( result, "," )
    end


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
		-- 1. HMI respond TestedInterface.IsReady (false) -> SDL must return 'UNSUPPORTED_RESOURCE, success:false' to all single VR-related RPC
		-- 2. HMI respond TestedInterface.IsReady (false) and app sends RPC that must be spitted -> SDL must NOT transfer VR portion of spitted RPC to HMI
		-- 3. HMI does NOT respond to '..tested_method..'_request -> SDL must transfer received RPC to HMI even to non-responded VR module
-----------------------------------------------------------------------------------------------


	-----------------------------------------------------------------------------------------------
	--CRQ #1:
	-- VR: APPLINK-20932 (single VR)
	-- UI: APPLINK-25103
	-- TTS: APPLINK-25131
	-- VehicleInfo: APPLINK-25225
	-- Navigation: APPLINK-25185
	-- Verification criteria:
		-- In case SDL does NOT receive TestedInterface_response during <DefaultTimeout> from HMI
		-- and mobile app sends any single interface-related RPC
		-- SDL must:
		-- transfer this interface-related RPC to HMI
		-- respond with <received_resultCode_from_HMI> to mobile app
	-----------------------------------------------------------------------------------------------
	-- IsExecutedAllResultCodes:
	 							-- false: Test will be executed only for result code SUCCESS
	 							-- true:  Test will be executed for all possible result codes defined in structure TestData
	-- IsExecutedAllRelatedRPCs:
								-- false: Test will be executed only for first RPC
								-- true:  Test will be executed for all defined RPCs in structure RPCs
	local function Single_Interface_RPCs(TestCaseName, IsExecutedAllResultCodes, IsExecutedAllRelatedRPCs)

		-- List of all resultCodes
		local TestData = {}
		if(IsExecutedAllResultCodes == true) then
			TestData = {

				-- if and this resultCode is unexpected for this RPC(please see expected <resultCodes> for each RPC at MOBILE_API)
				-- APPLINK-25748: result code should have success: true or false
				{success = true, resultCode = "SUCCESS", 						expected_resultCode = "SUCCESS", value = 0},
				{success = true, resultCode = "WARNINGS", 						expected_resultCode = "WARNINGS", value = 21},
				{success = true, resultCode = "WRONG_LANGUAGE", 				expected_resultCode = "WRONG_LANGUAGE", value = 16},
				{success = true, resultCode = "RETRY", 							expected_resultCode = "RETRY", value = 7},
				{success = true, resultCode = "SAVED", 							expected_resultCode = "SAVED", value = 25},
				{success = true, resultCode = "UNSUPPORTED_RESOURCE", 			expected_resultCode = "UNSUPPORTED_RESOURCE", value = 2},

				{success = false, resultCode = "", 								expected_resultCode = "GENERIC_ERROR", value = 22}, --not respond
				{success = false, resultCode = "ABC", 							expected_resultCode = "INVALID_DATA", value = 11},

				{success = false, resultCode = "UNSUPPORTED_REQUEST",			expected_resultCode = "UNSUPPORTED_REQUEST", value = 1},
				{success = false, resultCode = "DISALLOWED", 					expected_resultCode = "DISALLOWED", value = 3},
				{success = false, resultCode = "USER_DISALLOWED", 				expected_resultCode = "USER_DISALLOWED", value = 23},
				{success = false, resultCode = "REJECTED", 						expected_resultCode = "REJECTED", value = 4},
				{success = false, resultCode = "ABORTED", 						expected_resultCode = "ABORTED", value = 5},
				{success = false, resultCode = "IGNORED", 						expected_resultCode = "IGNORED", value = 6},
				{success = false, resultCode = "IN_USE", 						expected_resultCode = "IN_USE", value = 8},
				{success = false, resultCode = "DATA_NOT_AVAILABLE",	        expected_resultCode = "DATA_NOT_AVAILABLE"},
				{success = false, resultCode = "TIMED_OUT", 					expected_resultCode = "TIMED_OUT", value = 10},
				{success = false, resultCode = "INVALID_DATA", 					expected_resultCode = "INVALID_DATA", value = 11},
				{success = false, resultCode = "CHAR_LIMIT_EXCEEDED", 			expected_resultCode = "CHAR_LIMIT_EXCEEDED", value = 12},
				{success = false, resultCode = "INVALID_ID", 					expected_resultCode = "INVALID_ID", value = 13},
				{success = false, resultCode = "DUPLICATE_NAME", 				expected_resultCode = "DUPLICATE_NAME", value = 14},
				{success = false, resultCode = "APPLICATION_NOT_REGISTERED", 	expected_resultCode = "APPLICATION_NOT_REGISTERED", value = 15},
				{success = false, resultCode = "OUT_OF_MEMORY", 				expected_resultCode = "OUT_OF_MEMORY", value = 17},
				{success = false, resultCode = "TOO_MANY_PENDING_REQUESTS", 	expected_resultCode = "TOO_MANY_PENDING_REQUESTS", value = 18},
				{success = false, resultCode = "GENERIC_ERROR", 				expected_resultCode = "GENERIC_ERROR", value = 22},
				{success = false, resultCode = "TRUNCATED_DATA", 				expected_resultCode = "TRUNCATED_DATA", value = 24}
			}
		else
			TestData = {	{success = true, resultCode = "SUCCESS", expected_resultCode = "SUCCESS", value = 0} }
		end

		local grammarID = 1
		-- 1. All RPCs
		for i = 1, #TestData do
			for count_RPC = 1, #RPCs do
				local mob_request = mobile_request[count_RPC]
				local hmi_call = RPCs[count_RPC]
				local other_interfaces_call = {}
				local hmi_method_call = TestedInterface.."."..hmi_call.name

				if(mob_request.name == "SetGlobalProperties" and TestedInterface == "TTS") then mob_request.single = false end

				if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then
					if(mob_request.single == true)then

						-- Precondition for PerformInteraction
						if(mob_request.name == "PerformInteraction") then
							Test["Precondition_CreateInteractionChoiceSet_" ..tostring(i)] = function (self)
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
																										}
																										-- SDL image verification failed
																										-- image =
																										-- {
																										-- 	value ="icon.png",
																										-- 	imageType ="STATIC",
																										-- }
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
						    end
					    end --if(mob_request.name == "PerformInteraction") then

					    if( (mob_request.name ~= "StartStream") and (mob_request.name ~= "StopStream") and
					    	(mob_request.name ~= "StartAudioStream") and (mob_request.name ~= "StopAudioStream")) then
							Test["TC_"..mob_request.name.."_Only_".. tostring(TestData[i].resultCode).."_"..TestCaseName] = function(self)

							  	local menuparams = ""
							  	local vrCmd = ""
								userPrint(33, "Testing RPC = "..mob_request.name)
								--======================================================================================================
								-- Update and backup used params

									if ( mob_request.params.appName ~= nil )    then mob_request.params.appName = config.application1.registerAppInterfaceParams.appName end
									if ( mob_request.params.cmdID ~= nil ) then mob_request.params.cmdID = i end

									if( TestedInterface == "UI") then
										if ( mob_request.params.vrCommands ~= nil ) then
											vrCmd = mob_request.params.vrCommands
											mob_request.params.vrCommands = nil
										end
									else
										if ( mob_request.params.vrCommands ~= nil ) then
											mob_request.params.vrCommands =  {"vrCommands_" .. tostring(i)}
										end
									end

									if ( TestedInterface == "VR") then
										if (mob_request.params.menuParams ~= nil ) then
											menuparams = mob_request.params.menuParams
											mob_request.params.menuParams =  nil
										end
									else --if( TestedInterface == "UI") then
										if (mob_request.params.menuParams ~= nil ) then
											mob_request.params.menuParams = {position = 1, menuName = "Command " .. tostring(i)}
										end
									end

									if ( mob_request.params.interactionChoiceSetIDList ~= nil) then mob_request.params.interactionChoiceSetIDList = {i} end
								--======================================================================================================
								commonTestCases:DelayedExp(iTimeout)

								--mobile side: sending RPC request
								local cid = self.mobileSession:SendRPC(mob_request.name, mob_request.params)

								--======================================================================================================
								-- Update of verified params
									if ( hmi_call.params.appID ~= nil )          then hmi_call.params.appID = self.applications[config.application1.registerAppInterfaceParams.appName] end
									if ( hmi_call.params.cmdID ~= nil )          then hmi_call.params.cmdID = i end
								  	if ( hmi_call.params.vrCommands ~= nil )     then hmi_call.params.vrCommands =  {"vrCommands_" .. tostring(i)}  end
								  	if ( mob_request.params.menuParams ~= nil )  then hmi_call.params.menuParams = {position = 1, menuName = "Command " .. tostring(i)} end
								  	if ( hmi_call.params.grammarID ~= nil )      then
								  		if (mob_request.name == "DeleteCommand") then
								  			hmi_call.params.grammarID =  grammarID
										else
								  			hmi_call.params.grammarID[1] =  grammarID
								  		end
								  	end
								--======================================================================================================


					 			--hmi side: expect Interface.RPC request
					 			if( (hmi_method_call == "UI.EndAudioPassThru") or (hmi_method_call == "Navigation.SubscribeWayPoints") or (hmi_method_call == "Navigation.UnsubscribeWayPoints") ) then
					 				hmi_call.params = nil
					 			end
					 			if( (TestData[i].success == false) and
					 				(mob_request.name == "DeleteCommand" or mob_request.name == "DeleteSubMenu" or mob_request.name == "UnsubscribeWayPoints" or mob_request.name == "UnsubscribeVehicleData") ) then
					 				EXPECT_HMICALL( hmi_method_call, hmi_call.params)
					 				:Times(0)
					 			else
									EXPECT_HMICALL( hmi_method_call, hmi_call.params)
									:Do(function(_,data)
										if(mob_request.name == "AddCommand") then grammarID = data.params.grammarID end

										--hmi side: sending response
										if (TestData[i].resultCode == "") then
											-- HMI does not respond
										else
											if TestData[i].success == true then
												if(hmi_call.mandatory_params ~= nil) then
													if(mob_request.name == "GetWayPoints") then hmi_call.string_mandatory_params = '"appID" : '.. tostring(self.applications[config.application1.registerAppInterfaceParams.appName]) end
													--print("mandatory_params = "..mandatory_params)
													self.hmiConnection:SendResponse(data.id, data.method, TestData[i].resultCode, hmi_call.mandatory_params )
												else
													--self.hmiConnection:SendResponse(data.id, data.method, TestData[i].resultCode, {})
													self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..tostring(TestData[i].value)..'}}')
												end
											else
												if(mob_request.name == "GetWayPoints") then hmi_call.string_mandatory_params = '"appID" : '.. tostring(self.applications[config.application1.registerAppInterfaceParams.appName]) 
												end
												if(hmi_call.mandatory_params ~= nil) then
													self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..data.method..'",'..hmi_call.string_mandatory_params..'},"message":"error message","code":'..tostring(TestData[i].value)..'}}')
												else
													self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"'..data.method..'"},"message":"error message","code":'..tostring(TestData[i].value)..'}}')
												end
											end
										end
									end)
								end

								--mobile side: expect AddCommand response and OnHashChange notification
								if TestData[i].success == true then
									EXPECT_RESPONSE(cid, { success = TestData[i].success , resultCode = TestData[i].expected_resultCode })

									--mobile side: expect OnHashChange notification
									if(mob_request.hashChange == true) then
										EXPECT_NOTIFICATION("OnHashChange")
										:Timeout(iTimeout)
									else
										EXPECT_NOTIFICATION("OnHashChange")
										:Times(0)
									end

								else
									if(mob_request.name == "DeleteCommand" or mob_request.name == "DeleteSubMenu") then
										-- According to APPLINK-27079; APPLNIK-19401
										--mobile side: expect RPC response
										EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_ID"})

									elseif(mob_request.name == "UnsubscribeVehicleData" or (mob_request.name == "UnsubscribeWayPoints")) then
										-- According to APPLINK-27872 and APPLINK-20043
										-- mobile side: expect RPC response
										EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED"})
									else
										if (TestData[i].resultCode == "") then
											if mob_request.name == "Slider"  then
												-- Slider has timeout parameter, so we should add default timeout (10000) to Slider's timeout +time for delaty (~1000ms)
												local base_timeout = 11000
												local timeout = mob_request.params.timeout + base_timeout
												EXPECT_RESPONSE(cid, { success = TestData[i].success , resultCode = TestData[i].expected_resultCode}):Timeout(timeout)
											else
												EXPECT_RESPONSE(cid, { success = TestData[i].success , resultCode = TestData[i].expected_resultCode})
											end
										else
											EXPECT_RESPONSE(cid, { success = TestData[i].success , resultCode = TestData[i].expected_resultCode, info = "error message"})
										end
									end

									EXPECT_NOTIFICATION("OnHashChange")
									:Times(0)

								end

			 					--======================================================================================================
			 					--restore values for used parameters
									if(menuparams ~= "") then mob_request.params.menuParams = menuparams end
									if(vrCmd ~= "")      then mob_request.params.VRCommands = vrCmd end
							end

						--TODO: Uncomment when APPLINK-29286 is resolved
						--[[else
							--ToDo: Because of APPLINK-16610 resultCode SUCCESS is separated in other script.
							-- when the defect is fixed if-end will be removed
							if(TestData[i].resultCode ~= "SUCCESS") then

								--Preconditions:
								if(mob_request.name == "StopStream" and TestData[i].success == false) then
									Test["Precondition_StopStream_SUCCESS"] = function(self)
										self.mobileSession:StartService(11)

										EXPECT_HMICALL("Navigation.StartStream")
										:Do(function(_,data)
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
										end)

										self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")

										EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming",{available = true})
										:Times(1)
									end
								end

								if(mob_request.name == "StopAudioStream" and TestData[i].success == false) then
									Test["Precondition_StopAudioStream_SUCCESS"] = function(self)
										self.mobileSession:StartService(10)

										EXPECT_HMICALL("Navigation.StartStream")
										:Do(function(_,data)
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
										end)
										self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")

										EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming",{available = true})
										:Times(1)
									end
								end

								Test["TC_"..mob_request.name.."_Only_".. tostring(TestData[i].resultCode).."_"..TestCaseName] = function(self)
									userPrint(33, "Testing RPC = "..mob_request.name)

										local exTime = 1
										if(TestData[i].success == true) then
											exTime = 1
										else
											exTime = 0
										end

										if (mob_request.name == "StartStream") then
											self.mobileSession:StartService(11)
											self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")
										elseif (mob_request.name == "StopStream") then
											self.mobileSession:StopService(11)
										elseif (mob_request.name == "StartAudioStream") then
											self.mobileSession:StartService(10)
											self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
										elseif (mob_request.name == "StopAudioStream") then
						    				self.mobileSession:StopService(10)
						    			end



										EXPECT_HMICALL(hmi_method_call, {})
										:Do(function(_,data)
											if (TestData[i].resultCode == "") then
												-- HMI does not respond
											else
												if TestData[i].success == true then
													--self.hmiConnection:SendResponse(data.id, data.method, TestData[i].resultCode, {})
													self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","code":'..tostring(TestData[i].value)..'}}')
												else
													self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"'..data.method..'","message":"error message","code":'..tostring(TestData[i].value)..'}}')
												end
											end
										end)

										if (mob_request.name == "StartStream") then

											EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming",{available = true})
											:Times(exTime)
										elseif (mob_request.name == "StopStream") then

											EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming",{available = false})
											:Times(exTime)
										elseif (mob_request.name == "StartAudioStream") then

											EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming",{available = true})
											:Times(exTime)
										elseif (mob_request.name == "StopAudioStream") then

							    			EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming",{available = false})
							    			:Times(exTime)
							    		end
								end
							end --if(TestData[i].resultCode ~= "SUCCESS") then
							]]
						end --  if( (mob_request.name ~= "StartStream") and (mob_request.name ~= "StopStream") and
					end -- if(mob_request.single == true)then
					if(IsExecutedAllRelatedRPCs == false) then
					 	break -- use break to exit the second for loop "for count_RPC = 1, #RPCs do"
					end
				end --if( ( Tested_resultCode == "AllTested" ) or (Tested_resultCode == TestData[i].resultCode) ) then
			end --for count_RPC = 1, #RPCs do
		end -- for i = 1, #TestData do
	end


	for i=1, #TestData do

		local TestCaseName = "Case_" .. TestData[i].caseID .. "_IsReady_" ..TestData[i].description

		if( i == 1) then
			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup(TestCaseName)

			isReady:StopStartSDL_HMI_MOBILE(self, TestData[i].caseID, TestCaseName)

			-- Description: Register app for precondition
			commonSteps:RegisterAppInterface("Precondition_RegisterAppInterface_" .. TestCaseName)

			-- Description: Activation app for precondition
			commonSteps:ActivationApp(nil, "Precondition_ActivationApp_" .. TestCaseName)

			commonSteps:PutFile("Precondition_PutFile_MinLength", "a")
			commonSteps:PutFile("Precondition_PutFile_icon.png", "icon.png")
			commonSteps:PutFile("Precondition_PutFile_action.png", "action.png")

			-- execute test for all resultCodes and all related RPCs of the testing interface
			Single_Interface_RPCs(TestCaseName, true, true)
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

				commonSteps:PutFile("Precondition_PutFile_MinLength", "a")
				commonSteps:PutFile("Precondition_PutFile_icon.png", "icon.png")
				commonSteps:PutFile("Precondition_PutFile_action.png", "action.png")

				-- execute test for only one resultCode (SUCCESS) and the first related RPC of the testing interface
				Single_Interface_RPCs(TestCaseName, false, false)
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

-- Not applicable for '..tested_method..' HMI API.

	function Test.Postcondition_RestorePreloadedFile()
		commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
	end

	function Test.Postcondition_StopSDL()
	  StopSDL()
	end

return Test