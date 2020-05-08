Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')


---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
require('user_modules/AppTypes')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

APIName = "DeleteFile" -- use for above required scripts.


local iTimeout = 5000

local str255Chars = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

local appID0
local iPutFile_SpaceAvailable = 0
local iSpaceAvailable_BeforePutFile = 0
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
local appIDAndDeviceMac = config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
--local strAppFolder = config.SDLStoragePath..appIDAndDeviceMac
strAppFolder = config.pathToSDL ..  "storage/"..appIDAndDeviceMac

--Process different audio states for media and non-media application
local audibleState

if commonFunctions:isMediaApp() then
	audibleState = "AUDIBLE"
else
	audibleState = "NOT_AUDIBLE"
end
---------------------------------------------------------------------------------------------
-------------------------------------------Common functions-------------------------------------
---------------------------------------------------------------------------------------------
--Description: Function used to check file is existed on expected path
	--file_name: file want to check	
function file_check(file_name)	
  local file_found=io.open(file_name, "r")      

  if file_found==nil then
    return false
  else
    return true
  end
end

-- Test case sending request and checking results in case SUCCESS
local function TC_DeleteFile_SUCCESS(self, strTestCaseName, strFileName, strFileType)

	Test[strTestCaseName] = function(self)
	
		--mobile side: sending DeleteFile request
		local cid = self.mobileSession:SendRPC("DeleteFile",
		{
			syncFileName = strFileName
		})
		
		
		--hmi side: expect BasicCommunication.OnFileRemoved request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved",
		{
			fileName = strAppFolder .. strFileName,
			fileType = strFileType,
			appID = self.applications[config.application1.registerAppInterfaceParams.appName]
		})
		
		--mobile side: expect DeleteFile response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil })
		:ValidIf (function(_,data)
			if data.payload.spaceAvailable == nil then
				commonFunctions:printError("spaceAvailable parameter is missed")
				return false
			else 
				if file_check(strAppFolder .. strFileName) == true then	
					print(" \27[36m File is not delete from storage \27[0m ")
					return false
				else 
					return true
				end				
			end
		end)					
	end
end

-- Test case sending request and checking results and spaceAvailable in case SUCCESS
local function TC_DeleteFile_Check_spaceAvailable_SUCCESS(self, strTestCaseName, strFileName, strFileType)

	Test[strTestCaseName] = function(self)
	
		--mobile side: sending DeleteFile request
		local cid = self.mobileSession:SendRPC("DeleteFile",
		{
			syncFileName = strFileName
		})
		
		
		--hmi side: expect BasicCommunication.OnFileRemoved request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved",
		{
			fileName = strAppFolder .. strFileName,
			fileType = strFileType,
			appID = self.applications[config.application1.registerAppInterfaceParams.appName]
		})
				

		--mobile side: expect DeleteFile response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", spaceAvailable = iSpaceAvailable_BeforePutFile, info = nil})		
		:Do(function(_,data)
			--Store spaceAvailable value
			--iSpaceAvailable_BeforePutFile = data.payload.spaceAvailable
			--commonFunctions:printError("DeleteFile:spaceAvailable: " .. data.payload.spaceAvailable )
		end)		
	end
end

-- Put file to prepare for delete file step.
function putfile(self, strFileName, strFileType, blnPersistentFile, blnSystemFile, strFileNameOnMobile)

	local strTestCaseName, strSyncFileName, strFileNameOnLocal1	
	if type(strFileName) == "table" then
		strTestCaseName = "PutFile_"..strFileName.reportName
		strSyncFileName = strFileName.fileName
	elseif type(strFileName) == "string" then
		strTestCaseName = "PutFile_"..strFileName
		strSyncFileName = strFileName
	else 
		commonFunctions:printError("Error: putfile function, strFileName is wrong value type: " .. tostring(strFileName))
	end
	
	if strFileNameOnMobile ==nil then
		strFileNameOnMobile = "action.png"
	end
	
	Test[strTestCaseName] = function(self)
	
		--mobile side: sending Futfile request
		local cid = self.mobileSession:SendRPC("PutFile",
												{
													syncFileName = strSyncFileName,
													fileType	= strFileType, 
													persistentFile = blnPersistentFile,
													systemFile = blnSystemFile
												},
												"files/"..strFileNameOnMobile)

		--mobile side: expect Futfile response
		EXPECT_RESPONSE(cid, { success = true})
		:Do(function(_,data)
			--Store spaceAvailable value
			iPutFile_SpaceAvailable = data.payload.spaceAvailable				
		end)
		:ValidIf(function(_, data)
			if file_check(strAppFolder .. strSyncFileName) == false and systemFile == false then	
				print(" \27[36m File is not put to storage \27[0m ")
				return false
			else 
				return true
			end	
		end)
	end
end	


local function ExpectOnHMIStatusWithAudioStateChanged(self, request, timeout, level)

	if request == nil then  request = "BOTH" end
	if level == nil then  level = "FULL" end
	if timeout == nil then timeout = 10000 end

	if 
		level == "FULL" then 
			if 
				self.isMediaApplication == true or 
				Test.appHMITypes["NAVIGATION"] == true then 

					if request == "BOTH" then
						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
								{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "VRSESSION"},
								{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})		    
							:Times(6)
					elseif request == "VR" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", 		hmiLevel = level, audioStreamingState = "ATTENUATED"  },
								{ systemContext = "MAIN", 		hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "VRSESSION",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "VRSESSION",  hmiLevel = level, audioStreamingState = "AUDIBLE"    },
								{ systemContext = "MAIN",  		hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							:Times(5)
						    :Timeout(timeout)
					elseif request == "MANUAL" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"  },
								{ systemContext = "HMI_OBSCURED", hmiLevel = level, audioStreamingState = "ATTENUATED" },
								{ systemContext = "HMI_OBSCURED", hmiLevel = level, audioStreamingState = "AUDIBLE" },
								{ systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							:Times(4)
						    :Timeout(timeout)
					end
			elseif 
				self.isMediaApplication == false then

					if request == "BOTH" then
						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})		    
							:Times(3)
						    :Timeout(timeout)
					elseif request == "VR" then
						--any OnHMIStatusNotifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "VRSESSION",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "MAIN",  		hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    })
							:Times(2)
						    :Timeout(timeout)
					elseif request == "MANUAL" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})		    
							:Times(2)
					end
			end
	elseif
		level == "LIMITED" then

			if 
				self.isMediaApplication == true or 
				Test.appHMITypes["NAVIGATION"] == true then 

					if request == "BOTH" then
						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
								{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})		    
							:Times(3)
					elseif request == "VR" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", 		hmiLevel = level, audioStreamingState = "ATTENUATED"  },
								{ systemContext = "MAIN", 		hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "MAIN",  		hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							:Times(3)
						    :Timeout(timeout)
					elseif request == "MANUAL" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"  },
								{ systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							:Times(2)
						    :Timeout(timeout)
					end
			elseif 
				self.isMediaApplication == false then

					EXPECT_NOTIFICATION("OnHMIStatus")
					    :Times(0)

				    DelayedExp(1000)
			end

	elseif 
		level == "BACKGROUND" then 
		    EXPECT_NOTIFICATION("OnHMIStatus")
		    :Times(0)

		    DelayedExp(1000)
	end

end

local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = ctx })
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
		
	commonSteps:DeleteLogsFileAndPolicyTable()
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")

	--1. Activate application
	commonSteps:ActivationApp()

	--2. Update policy to allow request
	--TODO: Will be updated after policy flow implementation
	--policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------
	--Check:
		-- request with all parameters
		-- request with only mandatory parameters
		-- request with all combinations of conditional-mandatory parameters (if exist)
		-- request with one by one conditional parameters (each case - one conditional parameter)
		-- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
		-- request with all parameters are missing
		-- request with fake parameters (fake - not from protocol, from another request)
		-- request is sent with invalid JSON structure
		-- different conditions of correlationID parameter (invalid, several the same etc.)
		

	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		commonFunctions:printError("****************************** I TEST BLOCK: Check of mandatory/conditional request's parameters (mobile protocol) ******************************")
	end
	
	--Begin test suit PositiveRequestCheck
	--Description:
		-- request with all parameters
		-- request with only mandatory parameters
		-- request with all combinations of conditional-mandatory parameters (if exist)
		-- request with one by one conditional parameters (each case - one conditional parameter)
		-- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
		-- request with all parameters are missing
		-- request with fake parameters (fake - not from protocol, from another request)
		-- request is sent with invalid JSON structure
		-- different conditions of correlationID parameter (invalid, several the same etc.)
	
				
		--Begin test case PositiveRequestCheck.1
		--Description: check request with all parameters
		
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-150

			--Verification criteria: 
			
			--Precondition: PutFile
			putfile(self, "test.png", "GRAPHIC_PNG")
			
			TC_DeleteFile_SUCCESS(self, "DeleteFile_test.png", "test.png", "GRAPHIC_PNG")				

		--End test case CommonRequestCheck.1
		
		
		--Begin test case PositiveRequestCheck.2
		--Description: check request with only mandatory parameters --> The same as CommonRequestCheck.1

		--End test case PositiveRequestCheck.2


		--Skipped CommonRequestCheck.3-4: There next checks are not applicable:
			-- request with all combinations of conditional-mandatory parameters (if exist)
			-- request with one by one conditional parameters (each case - one conditional parameter)

			
		
		--Begin test case CommonRequestCheck.5
		--Description: This test is intended to check request with missing mandatory parameters one by one (each case - missing one mandatory parameter)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-715

			--Verification criteria: SDL responses invalid data
	
			function Test:DeleteFile_missing_mandatory_parameters_syncFileName_INVALID_DATA()
					
				--mobile side: sending DeleteFile request
				local cid = self.mobileSession:SendRPC("DeleteFile",
				{
				
				})
				
				--mobile side: expect DeleteFile response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = nil})
				:Timeout(iTimeout)
			 
			end					

		--End test case CommonRequestCheck.5
				
		

		--Begin test case PositiveRequestCheck.6
		--Description: check request with all parameters are missing
			--> The same as PositiveRequestCheck.5

		--End test case PositiveRequestCheck.6		

		
		--Begin test case PositiveRequestCheck.7
		--Description: check request with fake parameters (fake - not from protocol, from another request)

			--Begin test case CommonRequestCheck.7.1
			--Description: Check request with fake parameters

				--Requirement id in JAMA/or Jira ID: APPLINK-4518

				--Verification criteria: According to xml tests by Ford team all fake parameters should be ignored by SDL

				--Precondition: PutFile
				putfile(self, "test.png", "GRAPHIC_PNG")				
				
				function Test:DeleteFile_FakeParameters_SUCCESS()

					--mobile side: sending DeleteFile request
					local cid = self.mobileSession:SendRPC("DeleteFile",
					{
						fakeParameter = 123,
						syncFileName = "test.png"

					})
					
					
					--hmi side: expect BasicCommunication.OnFileRemoved request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved",
					{
						fileName = strAppFolder .. "test.png",
						fileType = "GRAPHIC_PNG",
						appID = self.applications[config.application1.registerAppInterfaceParams.appName]
					})
					:ValidIf(function(_,data)
						if data.params.fakeParameter then
								commonFunctions:printError(" SDL re-sends fake parameters to HMI in BasicCommunication.OnFileRemoved")
								return false
						else 
							return true
						end
					end)
					
							
					--mobile side: expect DeleteFile response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })	
					
				end

			--End test case CommonRequestCheck.7.1
			
			--Begin test case CommonRequestCheck.7.2
			--Description: Check request with parameters of other request

				--Requirement id in JAMA/or Jira ID: APPLINK-4518

				--Verification criteria: SDL ignores parameters of other request

				--Precondition: PutFile
				putfile(self, "test.png", "GRAPHIC_PNG")
				
				function Test:DeleteFile_ParametersOfOtherRequest_SUCCESS()

					--mobile side: sending DeleteFile request
					local cid = self.mobileSession:SendRPC("DeleteFile",
					{
						syncFileName = "test.png",
						ttsChunks = { 
							TTSChunk = 
							{ 
								text ="SpeakFirst",
								type ="TEXT",
							}, 
							TTSChunk = 
							{ 
								text ="SpeakSecond",
								type ="TEXT",
							}
						}
					})
					
					
					--hmi side: expect BasicCommunication.OnFileRemoved request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved",
					{
						fileName = strAppFolder .. "test.png",
						fileType = "GRAPHIC_PNG",
						appID = self.applications[config.application1.registerAppInterfaceParams.appName]
					})
					:ValidIf(function(_,data)
						if data.params.ttsChunks then
								commonFunctions:printError(" SDL re-sends parameters of other request to HMI in BasicCommunication.OnFileRemoved")
								return false
						else 
							return true
						end
					end)
					
							
					--mobile side: expect DeleteFile response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })	
					
				end

			--End test case CommonRequestCheck.7.2
			
		--End test case PositiveRequestCheck.7			

		

		
		--Begin test case CommonRequestCheck.8.
		--Description: Check request is sent with invalid JSON structure

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-715

			--Verification criteria: The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.

			--Precondition: PutFile
			putfile(self, "test.png", "GRAPHIC_PNG")	
			
			-- missing ':' after syncFileName
			--payload          = '{"syncFileName":"test.png"}'
			local  payload          = '{"syncFileName" "test.png"}'
			commonTestCases:VerifyInvalidJsonRequest(33, payload)
			
		--End test case CommonRequestCheck.8
			

		--Begin test case CommonRequestCheck.9
		--Description: check request correlation Id is duplicated

			--Requirement id in JAMA/or Jira ID: 

			--Verification criteria: SDL responses SUCCESS

			--Precondition: PutFile
			putfile(self, "test1.png", "GRAPHIC_PNG")
			putfile(self, "test2.png", "GRAPHIC_PNG")
			
			function Test:DeleteFile_Duplicated_CorrelationID_SUCCESS()
				
				--mobile side: sending DeleteFile request
				local cid = self.mobileSession:SendRPC("DeleteFile",
				{
					syncFileName = "test1.png"
				})
				
				

				local msg = 
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 33, --DeleteFileID
					rpcCorrelationId = cid,
					payload          = '{"syncFileName":"test2.png"}'
				}
				
				--hmi side: expect BasicCommunication.OnFileRemoved request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved",
				{
					fileName = strAppFolder .. "test1.png",
					fileType = "GRAPHIC_PNG",
					appID = self.applications[config.application1.registerAppInterfaceParams.appName]
				},
				{
					fileName = strAppFolder .. "test2.png",
					fileType = "GRAPHIC_PNG",
					appID = self.applications[config.application1.registerAppInterfaceParams.appName]
				}
				)
				:Times(2)
				:Do(function(exp,data)
						if exp.occurences == 1 then 
							self.mobileSession:Send(msg)
						end
					end)
						

				--mobile side: expect DeleteFile response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Times(2)
												
			end

		--End test case CommonRequestCheck.9
		-----------------------------------------------------------------------------------------

					
	--End test suit PositiveRequestCheck	
	



---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------


	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--

	
		--check of each request parameter value in bound and boundary conditions
	
	
		--Write NewTestBlock to ATF log
		function Test:NewTestBlock()
			commonFunctions:printError("****************************** II TEST BLOCK: Positive request check ******************************")
		end			
		
		
		--Begin test suit PositiveRequestCheck
		--Description: check of each request parameter value in bound and boundary conditions
		
			--Begin test case PositiveRequestCheck.1
			--Description: Check request with syncFileName parameter value in bound and boundary conditions
		
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-150
				--Verification criteria: DeleteFile response is SUCCESS


				arrFileType = {"GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG", "AUDIO_WAVE", "AUDIO_MP3", "AUDIO_AAC", "BINARY", "JSON"}
				arrPersistentFile = {false, true}
				arrSystemFile = {false}
				arrFileName = {
					{fileName = "a", reportName = "min_length_a"}, 
					{fileName = "test", reportName = "middle_length_test"}, 
					{fileName = str255Chars, reportName = "max_length_255_characters"}
				}
				

				for j = 1, #arrFileName do
					for n = 1, #arrFileType do
						for m = 1, #arrPersistentFile do
							for i = 1, #arrSystemFile do
							
								-- Precondition
								Test["ListFiles"] = function(self)
								
									--mobile side: sending ListFiles request
									local cid = self.mobileSession:SendRPC("ListFiles", {} )
									
									--mobile side: expect DeleteFile response
									EXPECT_RESPONSE(cid, 
										{
											success = true, 
											resultCode = "SUCCESS"
										}
									)
									:Do(function(_,data)
										--Store spaceAvailable value
										iSpaceAvailable_BeforePutFile = data.payload.spaceAvailable
										--commonFunctions:printError("ListFiles: spaceAvailable: " .. data.payload.spaceAvailable)
									end) 
								end
				
								--Precondition: PutFile
								putfile(self, arrFileName[j], arrFileType[n], arrPersistentFile[m], arrSystemFile[i])
								
								strTestCaseName = "DeleteFile_" .. tostring(arrFileName[j].reportName) .. "_FileType_" .. tostring(arrFileType[n]) .. "_PersistentFile_" .. tostring(arrPersistentFile[m]) .. "_SystemFile_" .. tostring(arrSystemFile[i])
								TC_DeleteFile_Check_spaceAvailable_SUCCESS(self, strTestCaseName, arrFileName[j].fileName, arrFileType[n])
								
							end
						end
					end
				end

				
			--End test suit PositiveRequestCheck.1

			
		--End test suit PositiveRequestCheck


	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- parameters with values in boundary conditions

		--Write NewTestBlock to ATF log
		function Test:NewTestBlock()
			commonFunctions:printError("****************************** II TEST BLOCK: Positive response check ******************************")
			commonFunctions:printError("There is no response from HMI for this request. => Skipped this part.")
			os.execute("sleep "..tonumber(5))
		end			
		
		
		--Begin test suit PositiveResponseCheck
		--Description: Check positive responses 

			--There is response from HMI => Ignore this check.
			
			
		--End test suit PositiveResponseCheck



----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--
	
		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Write NewTestBlock to ATF log
		function Test:NewTestBlock()
			commonFunctions:printError("****************************** III TEST BLOCK: Negative request check ******************************")
		end		
		
	--Begin test suit NegativeRequestCheck
	--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.
	
		--Begin test case NegativeRequestCheck.1
		--Description: check of syncFileName parameter value out bound

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-150 -> SDLAQ-CRS-715

			--Verification criteria: SDL returns INVALID_DATA

			--Begin test case NegativeRequestCheck.1.1
			--Description: check of syncFileName parameter value out lower bound
	
				function Test:DeleteFile_empty_outLowerBound_INVALID_DATA()
				
					--mobile side: sending DeleteFile request
					local cid = self.mobileSession:SendRPC("DeleteFile",
					{
						syncFileName = ""
					})
					
					
					--hmi side: expect BasicCommunication.OnFileRemoved request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved", {} )
					:Timeout(iTimeout)
					:Times(0)

					--mobile side: expect DeleteFile response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})		
				end
			
			--End test case NegativeRequestCheck.1.1

			--Begin test case NegativeRequestCheck.1.2
			--Description: check of syncFileName parameter value out upper bound (256 characters)
	
				function Test:DeleteFile_outUpperBound_OfPutFileName_256_INVALID_DATA()
				
					--mobile side: sending DeleteFile request
					local cid = self.mobileSession:SendRPC("DeleteFile",
					{
						syncFileName = str255Chars .. "x"
					})
					
					
					--hmi side: expect BasicCommunication.OnFileRemoved request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved", {} )
					:Timeout(iTimeout)
					:Times(0)

					--mobile side: expect DeleteFile response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})		
				end
			
			--End test case NegativeRequestCheck.1.2	
			
			--Begin test case NegativeRequestCheck.1.3
			--Description: check of syncFileName parameter value out upper bound (501 characters)
	
				function Test:DeleteFile_outUpperBound_501_INVALID_DATA()
				
					--mobile side: sending DeleteFile request
					local cid = self.mobileSession:SendRPC("DeleteFile",
					{
						syncFileName = str255Chars .. str255Chars .. "x"
					})
					
					
					--hmi side: expect BasicCommunication.OnFileRemoved request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved", {} )
					:Timeout(iTimeout)
					:Times(0)

					--mobile side: expect DeleteFile response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})		
				end
			
			--End test case NegativeRequestCheck.1.3	
			
		--End test case NegativeRequestCheck.1

		
		--Begin test case NegativeRequestCheck.2
		--Description: check of syncFileName parameter is invalid values(empty, missing, nonexistent, duplicate, invalid characters)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-150 -> SDLAQ-CRS-715

			--Verification criteria: SDL returns INVALID_DATA

			--Begin test case NegativeRequestCheck.2.1
			--Description: check of syncFileName parameter is invalid values(empty)	
				--It is covered in out lower bound case

			--End test case NegativeRequestCheck.2.1
			

			--Begin test case NegativeRequestCheck.2.2
			--Description: check of syncFileName parameter is invalid values(missing)

				--It is covered by DeleteFile_missing_mandatory_parameters_syncFileName_INVALID_DATA
			
			--End test case NegativeRequestCheck.2.2
			
			--Begin test case NegativeRequestCheck.2.3
			--Description: check of syncFileName parameter is invalid values(nonexistent)
			
				Test["DeleteFile_syncFileName_nonexistentValue_INVALID_DATA"] = function(self)
								
					--mobile side: sending DeleteFile request
					local cid = self.mobileSession:SendRPC("DeleteFile",
					{
						syncFileName = "nonexistentValue"
					})
					
					
					--hmi side: expect BasicCommunication.OnFileRemoved request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved", {})
					:Timeout(iTimeout)
					:Times(0)			

					--mobile side: expect DeleteFile response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})
					:Timeout(iTimeout)				
				end
				
			--End test case NegativeRequestCheck.2.3

			--Begin test case NegativeRequestCheck.2.4
			--Description: check of syncFileName parameter is invalid values(duplicate)
			
				--It is not applicable

			--End test case NegativeRequestCheck.2.4

			--Begin test case NegativeRequestCheck.2.5
			--Description: check of syncFileName parameter is invalid values(invalid characters)
			
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-715, APPLINK-8083

				--Verification criteria: SDL returns INVALID_DATA			
			
				--Begin test case NegativeRequestCheck.2.5.1
				--Description: newline character
				
					--Precondition
					putfile(self, "test1.png", "GRAPHIC_PNG")
				
					Test["DeleteFile_syncFileName_invalid_characters_newline_INVALID_DATA"] = function(self)
									
						--mobile side: sending DeleteFile request
						local cid = self.mobileSession:SendRPC("DeleteFile",
						{
							syncFileName = "te\nst1.png"
						})
						
						--hmi side: expect BasicCommunication.OnFileRemoved request
						EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved", {} )
						:Timeout(iTimeout)
						:Times(0)				

						--mobile side: expect DeleteFile response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})						
						:Timeout(12000)	
						
					end
			
				--End test case NegativeRequestCheck.2.5.1

				--Begin test case NegativeRequestCheck.2.5.2
				--Description: newline character
				
					Test["DeleteFile_syncFileName_invalid_characters_tab_INVALID_DATA"] = function(self)
									
						--mobile side: sending DeleteFile request
						local cid = self.mobileSession:SendRPC("DeleteFile",
						{
							syncFileName = "te\tst1.png"
						})
											
						--hmi side: expect BasicCommunication.OnFileRemoved request
						EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved", {} )
						:Timeout(iTimeout)
						:Times(0)

						--mobile side: expect DeleteFile response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})						
						:Timeout(12000)					
					end
			
				--End test case NegativeRequestCheck.2.5.2
				
			--End test case NegativeRequestCheck.2.5			

		--End test case NegativeRequestCheck.2

		
		--Begin test case NegativeRequestCheck.3
		--Description: check of syncFileName parameter is wrong type

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-150 -> SDLAQ-CRS-715

			--Verification criteria: SDL returns INVALID_DATA
			
			Test["DeleteFile_syncFileName_wrongType_INVALID_DATA"] = function(self)
							
				--mobile side: sending DeleteFile request
				local cid = self.mobileSession:SendRPC("DeleteFile",
				{
					syncFileName = 123
				})
				
								
				--hmi side: expect BasicCommunication.OnFileRemoved request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved",
				{
					syncFileName = "ON\nSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Times(0)
				
				--mobile side: expect DeleteFile response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})						
				:Timeout(iTimeout)	
				
			end
			
		--End test case NegativeRequestCheck.3
		
		
		--Begin test case NegativeRequestCheck.4
		--Description: request is invalid json		
		
			--payload 		= '{"syncFileName":"test.png"}'
			local Payload 		= '{"syncFileName", "test.png"}'
					  
			commonTestCases:VerifyInvalidJsonRequest(33, Payload)
							
		--End test case NegativeRequestCheck.4
		
		--Begin test case NegativeRequestCheck.5
		--Description: Delete system file.	
		
			--Requirement id in JAMA/or Jira ID: APPLINK-14119

			--Verification criteria: SDL returns INVALID_DATA
			
				arrFileType = {"GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG", "AUDIO_WAVE", "AUDIO_MP3", "AUDIO_AAC", "BINARY", "JSON"}
				arrPersistentFile = {false, true}
				--Defect: APPLINK-14212: DeleteFile response: spaceAvailable parameter is wrong value
				arrSystemFile = {true}
				arrFileName = {
					{fileName = "a", reportName = "min_length_a"}, 
					{fileName = "test", reportName = "middle_length_test"}, 
					{fileName = str255Chars, reportName = "max_length_255_characters"}
				}
				

				for j = 1, #arrFileName do
					for n = 1, #arrFileType do
						for m = 1, #arrPersistentFile do
							for i = 1, #arrSystemFile do
							
				
								--Precondition: PutFile
								putfile(self, arrFileName[j], arrFileType[n], arrPersistentFile[m], arrSystemFile[i])
								
								strTestCaseName = "DeleteFile_" .. tostring(arrFileName[j].reportName) .. "_FileType_" .. tostring(arrFileType[n]) .. "_PersistentFile_" .. tostring(arrPersistentFile[m]) .. "_SystemFile_" .. tostring(arrSystemFile[i])
								
								Test[strTestCaseName] = function(self)
	
									--mobile side: sending DeleteFile request
									local cid = self.mobileSession:SendRPC("DeleteFile",
									{
										syncFileName = arrFileName[j].fileName
									})
									

									--mobile side: expect DeleteFile response
									EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})											
								end
								
							end
						end
					end
				end		
				
		--End test case NegativeRequestCheck.5
		
	--End test suit NegativeRequestCheck


	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--
		
		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Write NewTestBlock to ATF log
		function Test:NewTestBlock()
			commonFunctions:printError("****************************** III TEST BLOCK: Negative response check ******************************")
			commonFunctions:printError("There is no response from HMI for this request. => Skipped this part.")
			
		end	

		
	--Begin test suit NegativeResponseCheck
	--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

		--There is no response from HMI for this request. => Skipped this part.
	
	--End test suit NegativeResponseCheck
		

		
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------	

	--Check all uncovered pairs resultCodes+success
	
	
	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		commonFunctions:printError("****************************** IV TEST BLOCK: Result code check ******************************")
	end	
		

	--Begin test suit ResultCodeCheck
	--Description: check result code of response to Mobile (SDLAQ-CRS-713)
		
		--Begin test case ResultCodeCheck.1
		--Description: Check resultCode: SUCCESS

			--It is covered by test case CommonRequestCheck.1
			
		--End test case resultCodeCheck.1
		

		--Begin test case resultCodeCheck.2
		--Description: Check resultCode: INVALID_DATA

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-715

			--Verification criteria: SDL response INVALID_DATA resultCode to Mobile
			
			-- It is covered by DeleteFile_empty_outLowerBound_INVALID_DATA
			
		--End test case resultCodeCheck.2
		

		--Begin test case resultCodeCheck.3
		--Description: Check resultCode: OUT_OF_MEMORY

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-716

			--Verification criteria: SDL returns OUT_OF_MEMORY result code for DeleteFile request IN CASE SDL lacks memory RAM for executing it.
			
			--ToDo: Can not check this case.	
			
		--End test case resultCodeCheck.3
		

		--Begin test case resultCodeCheck.4
		--Description: Check resultCode: TOO_MANY_PENDING_REQUESTS

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-717

			--Verification criteria: The system has more than 1000 requests  at a time that haven't been responded yet.The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all further requests, until there are less than 1000 requests at a time that have not been responded by the system yet.
			
			--Move to another script: ATF_DeleteFile_TOO_MANY_PENDING_REQUESTS.lua
			
		--End test case resultCodeCheck.4
		

		--Begin test case resultCodeCheck.5
		--Description: Check resultCode: APPLICATION_NOT_REGISTERED

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-718

			--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED result code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.	
					
			-- Unregister application
			commonSteps:UnregisterApplication()
			
			--Send DeleteFile when application not registered yet.			
			function Test:DeleteFile_resultCode_APPLICATION_NOT_REGISTERED()
							
				--mobile side: sending DeleteFile request
				local cid = self.mobileSession:SendRPC("DeleteFile",
				{
					syncFileName = "test.png"
				})
								
				--hmi side: expect BasicCommunication.OnFileRemoved request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved", {} )
				:Timeout(iTimeout)
				:Times(0)
				

				--mobile side: expect DeleteFile response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "APPLICATION_NOT_REGISTERED", info = nil})
				:Timeout(iTimeout)					
			end
			
			-- Register application again
			commonSteps:RegisterAppInterface()	
		
			--ToDo: Work around to help script continnue running due to error with UnregisterApplication and RegisterAppInterface again. Remove it when it is not necessary.
			commonSteps:RegisterAppInterface()

			-- Activate app again
			commonSteps:ActivationApp()
			
		--End test case resultCodeCheck.5
		

		--Begin test case resultCodeCheck.6
		--Description: Check resultCode: REJECTED 
				
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-719, SDLAQ-CRS-2281

			--Verification criteria: 
				--1. In case app in HMI level of NONE sends DeleteFile_request AND the number of requests more than value of 'DeleteFileRequest' param defined in .ini file SDL must respond REJECTED result code to this mobile app

			-- Precondition 1: Put 6 files
			putfile(self, "test1.png", "GRAPHIC_PNG")
			putfile(self, "test2.png", "GRAPHIC_PNG")
			putfile(self, "test3.png", "GRAPHIC_PNG")
			putfile(self, "test4.png", "GRAPHIC_PNG")
			putfile(self, "test5.png", "GRAPHIC_PNG")
			putfile(self, "test6.png", "GRAPHIC_PNG")

			-- Precondition 2: Change app to NONE HMI level
			commonSteps:DeactivateAppToNoneHmiLevel()
			
			-- Precondition 3: Send DeleteFile 5 times
			TC_DeleteFile_SUCCESS(self, "DeleteFile_NONE_HMI_LEVEL_test1_png_SUCCESS", "test1.png", "GRAPHIC_PNG")	
			TC_DeleteFile_SUCCESS(self, "DeleteFile_NONE_HMI_LEVEL_test2_png_SUCCESS", "test2.png", "GRAPHIC_PNG")	
			TC_DeleteFile_SUCCESS(self, "DeleteFile_NONE_HMI_LEVEL_test3_png_SUCCESS", "test3.png", "GRAPHIC_PNG")	
			TC_DeleteFile_SUCCESS(self, "DeleteFile_NONE_HMI_LEVEL_test4_png_SUCCESS", "test4.png", "GRAPHIC_PNG")	
			TC_DeleteFile_SUCCESS(self, "DeleteFile_NONE_HMI_LEVEL_test5_png_SUCCESS", "test5.png", "GRAPHIC_PNG")	

						
			Test["DeleteFile_NONE_HMI_LEVEL_test6_png_REJECTED"] = function(self)

				--mobile side: sending DeleteFile request
				local cid = self.mobileSession:SendRPC("DeleteFile",
				{
					syncFileName = "test6.png"
				})
				
				--hmi side: expect BasicCommunication.OnFileRemoved request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved", {} )
				:Times(0)
						
				--mobile side: expect DeleteFile response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })		
			end

			-- Activate app again
			commonSteps:ActivationApp()
			
			TC_DeleteFile_SUCCESS(self, "DeleteFile_FULL_HMI_LEVEL_test6_png_SUCCESS", "test6.png", "GRAPHIC_PNG")	
		


		
		--End test case resultCodeCheck.6
		
		
		--Begin test case resultCodeCheck.7
		--Description: Check resultCode: GENERIC_ERROR

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-720

			--Verification criteria:  GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occurred.
			
			--ToDo: Don't know how to produce this case.
			
		--End test case resultCodeCheck.7
		

		--Begin test case resultCodeCheck.8
		--Description: Check resultCode: UNSUPPORTED_REQUEST

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1041 (APPLINK-9867 question)

			--Verification criteria: The platform doesn't support file operations, the UNSUPPORTED_REQUEST responseCode is obtained. General request result is success=false.
			
			--ToDo: This requirement is not applicable because current SDL supports DeleteFile API
			
		--End test case resultCodeCheck.8

		
	--End test suit resultCodeCheck



----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
	-- requests without responses from HMI
	-- invalid structure of response
	-- several responses from HMI to one request
	-- fake parameters
	-- HMI correlation id check 
	-- wrong response with correct HMI id

	
	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		commonFunctions:printError("****************************** V TEST BLOCK: HMI negative cases ******************************")
		commonFunctions:printError("There is no response from HMI for this request. => Skipped this part.")
	end		

	--Begin test suit HMINegativeCheck
	--Description: Check negative response from HMI
		
		--There is no response from HMI for this request. => Skipped this part.						
			
	--End test suit HMINegativeCheck


	
----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

	-- Check different request sequence with timeout, emulating of user's actions


	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		commonFunctions:printError("****************************** VI TEST BLOCK: Sequence with emulating of user's action(s) ******************************")
	end	
	
	--Begin test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		-- with emulating of user's actions
		
		
		--Begin test case SequenceCheck.1
		--Description: Check scenario in test case TC_DeleteFile_01: Delete files from SDL Core with next file types:
							-- GRAPHIC_BMP
							-- GRAPHIC_JPEG
							-- GRAPHIC_PNG
							-- AUDIO_WAVE
							-- AUDIO_MP3

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-150

			--Verification criteria: DeleteFile request is sent for a file already stored in the app's local cache on SDL (app's folder on SDL) and not marked as persistent file on SDL during current ignition/session cycle, the result of the request is deleting the corresponding file from the app's folder on SDL.

						
			-- Precondition: PutFile icon_bmp.bmp, icon_jpg.jpeg, icon_png.png, tone_wave.wav, tone_mp3.mp3		
			putfile(self, "icon_bmp.bmp", "GRAPHIC_BMP", false, false, "icon_bmp.bmp")
			putfile(self, "icon_jpg.jpeg", "GRAPHIC_JPEG", false, false, "icon_jpg.jpeg")
			putfile(self, "icon_png.png", "GRAPHIC_PNG", false, false, "icon_png.png")
			putfile(self, "tone_wave.wav", "AUDIO_WAVE", false, false, "tone_wave.wav")
			putfile(self, "tone_mp3.mp3", "AUDIO_MP3", false, false, "tone_mp3.mp3")
			
			
			Test["ListFile_ContainsPutFiles"] = function(self)
			
				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )
				
				--mobile side: expect DeleteFile response
				EXPECT_RESPONSE(cid, 
					{
						success = true, 
						resultCode = "SUCCESS",
						filenames = 
						{
							"icon_bmp.bmp",
							"icon_jpg.jpeg",
							"icon_png.png",
							"tone_mp3.mp3",
							"tone_wave.wav"
						}
					}
				)
			end
			
			
			TC_DeleteFile_SUCCESS(self, "TC_DeleteFile_01_icon_bmp.bmp", "icon_bmp.bmp", "GRAPHIC_BMP")
			TC_DeleteFile_SUCCESS(self, "TC_DeleteFile_01_icon_jpg.jpeg", "icon_jpg.jpeg", "GRAPHIC_JPEG")
			TC_DeleteFile_SUCCESS(self, "TC_DeleteFile_01_icon_png.png", "icon_png.png", "GRAPHIC_PNG")
			TC_DeleteFile_SUCCESS(self, "TC_DeleteFile_01_tone_wave.wav", "tone_wave.wav", "AUDIO_WAVE")
			TC_DeleteFile_SUCCESS(self, "TC_DeleteFile_01_tone_mp3.mp3", "tone_mp3.mp3", "AUDIO_MP3")
			
			Test["ListFile_WihtoutDeletedFiles"] = function(self)
			
				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )
				
				--mobile side: expect DeleteFile response
				EXPECT_RESPONSE(cid, 
					{
						success = true, 
						resultCode = "SUCCESS"
					}
				)
				:ValidIf(function(_,data)
					local removedFileNames = 
					{
						"icon_bmp.bmp",
						"icon_jpg.jpeg",
						"icon_png.png",
						"tone_mp3.mp3",
						"tone_wave.wav"
					}
					local blnResult = true
					if data.payload.filenames ~= nil then
						for i = 1, #removedFileNames do
							for j =1, #data.payload.filenames do
								if removedFileNames[i] == data.payload.filenames[j] then
									commonFunctions:printError("Failed: " .. removedFileNames[i] .. " is still in result of ListFiles request")
									blnResult = false
									break
								end						
							end
						end
					else 
						print( " \27[32m ListFiles response came without  filenames \27[0m " )
						return true
					end
					
					return blnResult
				end)
			end
				
				
		--End test case SequenceCheck.1
		
		----------------------------------------------------------------------------------------------
		--Print new line to separate new test cases
		commonFunctions:newTestCasesGroup("Test case: TC_OnFileRemoved_01")  
		--Begin test case SequenceCheck.2
		--Description: Cover TC_OnFileRemoved_01

			--Requirement id in JAMA/or Jira ID: SDLAQ-TC-329

			--Verification criteria: Checking sending OnFileRemoved notification by Core to HMI and changing  app icon to default after deleting  file which was set for app icon. (Checking  for GRAPHIC_BMP, GRAPHIC_JPEG, GRAPHIC_PNG image types).  
			local function TC_OnFileRemoved_01(imageFile, imageTypeValue)
				putfile(self, imageFile, imageTypeValue,_,_,imageFile)
							
				function Test:SetAppIcon()
					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = imageFile })
					
					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						appID = self.applications[config.application1.registerAppInterfaceParams.appName],
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = strAppFolder .. imageFile
						}				
					})
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})				
					end)
					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })	
				end

				TC_DeleteFile_SUCCESS(self, "DeleteFile_"..imageFile, imageFile, imageTypeValue)	
			end
			local imageFile = {{fileName = "action.png", fileType ="GRAPHIC_PNG"}, 
								{fileName = "action.bmp", fileType ="GRAPHIC_BMP"}, 
								{fileName = "action.jpeg", fileType ="GRAPHIC_JPEG"}}
								
			for i=1,#imageFile do		
				TC_OnFileRemoved_01(imageFile[i].fileName, imageFile[i].fileType)		
			end
		--End test case SequenceCheck.2
		
		----------------------------------------------------------------------------------------------
		--Print new line to separate new test cases
		commonFunctions:newTestCasesGroup("Test case: TC_OnFileRemoved_02")  
		--Begin test case SequenceCheck.3
		--Description: Cover TC_OnFileRemoved_02

			--Requirement id in JAMA/or Jira ID: SDLAQ-TC-330

			--Verification criteria: Checking sending OnFileRemoved notification by Core to HMI and changing  Show image  to default after deleting  file which was set for Show image. (Checking  for GRAPHIC_BMP, GRAPHIC_JPEG, GRAPHIC_PNG image types).
			local function TC_OnFileRemoved_02(imageFile, imageTypeValue)
				putfile(self, imageFile, imageTypeValue,_,_,imageFile)					

				function Test:Show()
					--mobile side: sending Show request
					local cidShow = self.mobileSession:SendRPC("Show", {
																		mediaClock = "12:34",
																		mainField1 = "Show Line 1",
																		mainField2 = "Show Line 2",
																		mainField3 = "Show Line 3",
																		mainField4 = "Show Line 4",
																		graphic =
																		{
																			value = imageFile,
																			imageType = "DYNAMIC"
																		},
																		secondaryGraphic =
																		{
																			value = imageFile,
																			imageType = "DYNAMIC"
																		},
																		statusBar = "new status bar",
																		mediaTrack = "Media Track"
																	})
					--hmi side: expect UI.Show request
					EXPECT_HMICALL("UI.Show", { 
												graphic =
												{
													imageType = "DYNAMIC",
													value = strAppFolder..imageFile
												},
												secondaryGraphic = 
												{
													imageType = "DYNAMIC",
													value = strAppFolder..imageFile
												},
												showStrings = 
												{
													{
														fieldName = "mainField1",
														fieldText = "Show Line 1"
													},
													{
														fieldName = "mainField2",
														fieldText = "Show Line 2"
													},
													{
														fieldName = "mainField3",
														fieldText = "Show Line 3"
													},
													{
														fieldName = "mainField4",
														fieldText = "Show Line 4"
													},
													{
														fieldName = "mediaClock",
														fieldText = "12:34"
													},
													{
														fieldName = "mediaTrack",
														fieldText = "Media Track"
													},
													{
														fieldName = "statusBar",
														fieldText = "new status bar"
													}
												}
											})
					:Do(function(_,data)
						--hmi side: sending UI.Show response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect Show response
					EXPECT_RESPONSE(cidShow, { success = true, resultCode = "SUCCESS" })
				end
				
				TC_DeleteFile_SUCCESS(self, "DeleteFile_"..imageFile, imageFile, imageTypeValue)	
			end

			local imageFile = {{fileName = "action.png", fileType ="GRAPHIC_PNG"},
								{fileName = "action.bmp", fileType ="GRAPHIC_BMP"}, 
								{fileName = "action.jpeg", fileType ="GRAPHIC_JPEG"}}						

			for i=1,#imageFile do		
				TC_OnFileRemoved_02(imageFile[i].fileName, imageFile[i].fileType)	
			end			
		--End test case SequenceCheck.3
		
		-----------------------------------------------------------------------------------------
		--Print new line to separate new test cases
		commonFunctions:newTestCasesGroup("Test case: TC_OnFileRemoved_03")  		
		--Begin test case SequenceCheck.4
		--Description: Cover TC_OnFileRemoved_03

			--Requirement id in JAMA/or Jira ID: SDLAQ-TC-331

			--Verification criteria: Checking sending OnFileRemoved notification by Core to HMI and changing the Command icon to default after deleting file which was set for the icon of this Command. (Checking  for GRAPHIC_BMP, GRAPHIC_JPEG, GRAPHIC_PNG image types).
			function Test:AddSubMenu()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 10,
															position = 500,
															menuName ="TestMenu"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu", 
								{ 
									menuID = 10,
									menuParams = {
										position = 500,
										menuName ="TestMenu"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
					
				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })


				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end	
			local function TC_OnFileRemoved_03(imageFile, imageTypeValue, commandID)
				putfile(self, imageFile, imageTypeValue,_,_,imageFile)
							
				function Test:AddCommand()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = commandID,
																menuParams = 	
																{ 
																	parentID = 10,
																	position = 0,
																	menuName ="TestCommand"..commandID
																}, 
																cmdIcon = 	
																{ 
																	value = imageFile,
																	imageType ="DYNAMIC"
																}
															})
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = commandID,
										cmdIcon = 
										{
											value = strAppFolder..imageFile,
											imageType = "DYNAMIC"
										},
										menuParams = 
										{ 
											parentID = 10,	
											position = 0,
											menuName ="TestCommand"..commandID
										}
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
						
					
					--mobile side: expect AddCommand response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
				function Test:OpenOptionsMenu()
					SendOnSystemContext(self,"MENU")
					EXPECT_NOTIFICATION("OnHMIStatus",{ hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MENU"})
				end				
				
				TC_DeleteFile_SUCCESS(self, "DeleteFile_"..imageFile, imageFile, imageTypeValue)
				function Test:BackToMain()
					SendOnSystemContext(self,"MAIN")
					EXPECT_NOTIFICATION("OnHMIStatus",{ hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
				end	
			end
			local imageFile = {{fileName = "action.png", fileType ="GRAPHIC_PNG"}, 
								{fileName = "action.bmp", fileType ="GRAPHIC_BMP"}, 
								{fileName = "action.jpeg", fileType ="GRAPHIC_JPEG"}}						
			for i=1,#imageFile do		
				TC_OnFileRemoved_03(imageFile[i].fileName, imageFile[i].fileType, i+10)		
			end		
		--End test case SequenceCheck.4
		
		-----------------------------------------------------------------------------------------
		--Print new line to separate new test cases
		commonFunctions:newTestCasesGroup("Test case: TC_OnFileRemoved_04")  		
		--Begin test case SequenceCheck.5
		--Description: Cover TC_OnFileRemoved_04

			--Requirement id in JAMA/or Jira ID: SDLAQ-TC-332

			--Verification criteria: Checking sending OnFileRemoved notification by Core to HMI and changing the SoftButton icon to default after deleting file which was set for the icon of this SoftButton. (Checking  for GRAPHIC_BMP, GRAPHIC_JPEG, GRAPHIC_PNG image types).
			local function TC_OnFileRemoved_04(imageFile, imageTypeValue)
				putfile(self, imageFile, imageTypeValue,_,_,imageFile)					

				function Test:ShowWithSoftButton()
					--mobile side: sending Show request
					local cidShow = self.mobileSession:SendRPC("Show", {
																		mediaClock = "12:34",
																		mainField1 = "Show Line 1",
																		mainField2 = "Show Line 2",
																		mainField3 = "Show Line 3",
																		mainField4 = "Show Line 4",
																		graphic =
																		{
																			value = imageFile,
																			imageType = "DYNAMIC"
																		},
																		secondaryGraphic =
																		{
																			value = imageFile,
																			imageType = "DYNAMIC"
																		},
																		statusBar = "new status bar",
																		mediaTrack = "Media Track",
																		softButtons =
																		{
																			{
																				text = "",
																				systemAction = "DEFAULT_ACTION",
																				type = "IMAGE",
																				isHighlighted = true,																
																				image =
																				{
																				   imageType = "DYNAMIC",
																				   value = imageFile
																				},																
																				softButtonID = 1
																			}
																		}
					})
					--hmi side: expect UI.Show request
					EXPECT_HMICALL("UI.Show", { 
												graphic =
												{
													imageType = "DYNAMIC",
													value = strAppFolder..imageFile
												},
												secondaryGraphic = 
												{
													imageType = "DYNAMIC",
													value = strAppFolder..imageFile
												},
												showStrings = 
												{
													{
														fieldName = "mainField1",
														fieldText = "Show Line 1"
													},
													{
														fieldName = "mainField2",
														fieldText = "Show Line 2"
													},
													{
														fieldName = "mainField3",
														fieldText = "Show Line 3"
													},
													{
														fieldName = "mainField4",
														fieldText = "Show Line 4"
													},
													{
														fieldName = "mediaClock",
														fieldText = "12:34"
													},
													{
														fieldName = "mediaTrack",
														fieldText = "Media Track"
													},
													{
														fieldName = "statusBar",
														fieldText = "new status bar"
													}
												},
												softButtons =
												{
													{														
														systemAction = "DEFAULT_ACTION",
														type = "IMAGE",
														isHighlighted = true,											
														--[[ TODO: update after resolving APPLINK-16052
														image =
														{
														   imageType = "DYNAMIC",
														   value = strAppFolder..imageFile
														},]]																
														softButtonID = 1
													}
												}
											})
					:Do(function(_,data)
						--hmi side: sending UI.Show response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect Show response
					EXPECT_RESPONSE(cidShow, { success = true, resultCode = "SUCCESS" })
				end
				
				TC_DeleteFile_SUCCESS(self, "DeleteFile_"..imageFile, imageFile, imageTypeValue)	
			end

			local imageFile = {{fileName = "action.png", fileType ="GRAPHIC_PNG"},
								{fileName = "action.bmp", fileType ="GRAPHIC_BMP"}, 
								{fileName = "action.jpeg", fileType ="GRAPHIC_JPEG"}}						

			for i=1,#imageFile do		
				TC_OnFileRemoved_04(imageFile[i].fileName, imageFile[i].fileType)	
			end		
		--End test case SequenceCheck.5
		
		-----------------------------------------------------------------------------------------
		--Print new line to separate new test cases
		commonFunctions:newTestCasesGroup("Test case: TC_OnFileRemoved_05")  		
		--Begin test case SequenceCheck.6
		--Description: Cover TC_OnFileRemoved_05

			--Requirement id in JAMA/or Jira ID: SDLAQ-TC-333

			--Verification criteria: Checking sending OnFileRemoved notification by Core to HMI and changing the Turn icon of TurnList to default after deleting file which was set for the icon of this Turn. (Checking  for GRAPHIC_BMP, GRAPHIC_JPEG, GRAPHIC_PNG image types).
			local function TC_OnFileRemoved_05(imageFile, imageTypeValue)
				putfile(self, imageFile, imageTypeValue,_,_,imageFile)					

				function Test:UpdateTurnList()
					--mobile side: send UpdateTurnList request 	 	
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", {
																								turnList = 	
																								{
																									{
																										navigationText ="Text",
																										turnIcon =	
																										{ 
																											value = imageFile,
																											imageType ="DYNAMIC",
																										}
																									}
																								}
																							})
											
					--hmi side: expect Navigation.UpdateTurnList request 
					EXPECT_HMICALL("Navigation.UpdateTurnList"--[[ TODO: update after resolving APPLINK-16052, 
					{	
						turnList = 
						{	
							{
								navigationText =
								{
									fieldText = "Text",
									fieldName = "turnText"
								},
								turnIcon =	
								{ 
									value =strAppFolder..imageFile,
									imageType ="DYNAMIC",
								}	
							}
						}
					}]])
					:Do(function(_,data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)
					
					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end
				
				TC_DeleteFile_SUCCESS(self, "DeleteFile_"..imageFile, imageFile, imageTypeValue)	
			end

			local imageFile = {{fileName = "action.png", fileType ="GRAPHIC_PNG"},
								{fileName = "action.bmp", fileType ="GRAPHIC_BMP"}, 
								{fileName = "action.jpeg", fileType ="GRAPHIC_JPEG"}}						

			for i=1,#imageFile do		
				TC_OnFileRemoved_05(imageFile[i].fileName, imageFile[i].fileType)	
			end	
		--End test case SequenceCheck.6	
		
		-----------------------------------------------------------------------------------------
		--Print new line to separate new test cases
		commonFunctions:newTestCasesGroup("Test case: TC_OnFileRemoved_06")  				
		--Begin test case SequenceCheck.7
		--Description: Cover TC_OnFileRemoved_06

			--Requirement id in JAMA/or Jira ID: SDLAQ-TC-334

			--Verification criteria: Checking sending OnFileRemoved notification by Core to HMI and changing the Turn icon, Next Turn icon to default after deleting file which was set for the Turn icon and Next Turn icon. (Checking  for GRAPHIC_BMP, GRAPHIC_JPEG, GRAPHIC_PNG image types).
			local function TC_OnFileRemoved_06(imageFile, imageTypeValue)
				putfile(self, imageFile, imageTypeValue,_,_,imageFile)					

				function Test:ShowConstantTBT()
					--mobile side: sending ShowConstantTBT request
					cid = self.mobileSession:SendRPC("ShowConstantTBT", {
																			navigationText1 ="navigationText1",
																			navigationText2 ="navigationText2",
																			eta ="12:34",
																			totalDistance ="100miles",
																			turnIcon =	
																			{ 
																				value =imageFile,
																				imageType ="DYNAMIC",
																			}, 
																			nextTurnIcon =	
																			{ 
																				value =imageFile,
																				imageType ="DYNAMIC",
																			}, 
																			distanceToManeuver = 50.5,
																			distanceToManeuverScale = 100.5,
																			maneuverComplete = false,
																			softButtons = 
																			{	
																				{ 
																					type ="BOTH",
																					text ="Close",
																					image =	
																					{ 
																						value =imageFile,
																						imageType ="DYNAMIC",
																					}, 
																					isHighlighted = true,
																					softButtonID = 44,
																					systemAction ="DEFAULT_ACTION",
																				}, 
																			}, 
																		})
					
					--hmi side: expect Navigation.ShowConstantTBT request
					EXPECT_HMICALL("Navigation.ShowConstantTBT", {
																	navigationTexts = {
																		{
																			fieldName = "navigationText1",
																			fieldText = "navigationText1"
																		},
																		{
																			fieldName = "navigationText2",
																			fieldText = "navigationText2"
																		},
																		{
																			fieldName = "ETA",
																			fieldText = "12:34"
																		},
																		{
																			fieldName = "totalDistance",
																			fieldText = "100miles"
																		}
																	},																														
																	turnIcon =	
																	{ 
																		value =strAppFolder..imageFile,
																		imageType ="DYNAMIC",
																	}, 
																	nextTurnIcon =	
																	{ 
																		value =strAppFolder..imageFile,
																		imageType ="DYNAMIC",
																	}, 
																	distanceToManeuver = 50.5,
																	distanceToManeuverScale = 100.5,
																	maneuverComplete = false,
																	softButtons = 
																	{	
																		{ 
																			type ="BOTH",
																			text ="Close",
																			 --[[ TODO: update after resolving APPLINK-16052
																			image =	
																			{ 
																				value =strAppFolder..imageFile,
																				imageType ="DYNAMIC",
																			}, ]]
																			isHighlighted = true,
																			softButtonID = 44,
																			systemAction ="DEFAULT_ACTION",
																		}, 
																	},
																})
					:Do(function(_,data)
						--hmi side: sending Navigation.ShowConstantTBT response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				end
				
				TC_DeleteFile_SUCCESS(self, "DeleteFile_"..imageFile, imageFile, imageTypeValue)	
			end

			local imageFile = {{fileName = "action.png", fileType ="GRAPHIC_PNG"},
								{fileName = "action.bmp", fileType ="GRAPHIC_BMP"}, 
								{fileName = "action.jpeg", fileType ="GRAPHIC_JPEG"}}						

			for i=1,#imageFile do		
				TC_OnFileRemoved_06(imageFile[i].fileName, imageFile[i].fileType)	
			end
		--End test case SequenceCheck.7
		
		-----------------------------------------------------------------------------------------
		--Print new line to separate new test cases
		commonFunctions:newTestCasesGroup("Test case: TC_OnFileRemoved_07")  				
		--Begin test case SequenceCheck.8
		--Description: Cover TC_OnFileRemoved_07

			--Requirement id in JAMA/or Jira ID: SDLAQ-TC-335

			--Verification criteria: Checking sending OnFileRemoved notification by Core to HMI and changing the VRHelp Item  icon to default after deleting file which was set for the VRHelp Item icon. (Checking  for GRAPHIC_BMP, GRAPHIC_JPEG, GRAPHIC_PNG image types).
			local function TC_OnFileRemoved_07(imageFile, imageTypeValue)
				putfile(self, imageFile, imageTypeValue,_,_,imageFile)					

				function Test:SetGlobalProperties()
					--mobile side: sending SetGlobalProperties request
					cid = self.mobileSession:SendRPC("SetGlobalProperties", {
																			menuTitle = "Menu Title",
																			timeoutPrompt = 
																			{
																				{
																					text = "Timeout prompt",
																					type = "TEXT"
																				}
																			},
																			vrHelp = 
																			{
																				{
																					position = 1,
																					image = 
																					{
																						value = imageFile,
																						imageType = "DYNAMIC"
																					},
																					text = "Help me!"
																				}
																			},
																			menuIcon = 
																			{
																				value = imageFile,
																				imageType = "DYNAMIC"
																			},
																			helpPrompt = 
																			{
																				{
																					text = "Help prompt",
																					type = "TEXT"
																				}
																			},
																			vrHelpTitle = "New VR help title",
																			keyboardProperties = 
																			{
																				keyboardLayout = "QWERTY",
																				keypressMode = "SINGLE_KEYPRESS",
																				limitedCharacterList = 
																				{
																					"a"
																				},
																				language = "EN-US",
																				autoCompleteText = "Daemon, Freedom"
																			}
																		})
					
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
					{
						timeoutPrompt = 
						{
							{
								text = "Timeout prompt",
								type = "TEXT"
							}
						},
						helpPrompt = 
						{
							{
								text = "Help prompt",
								type = "TEXT"
							}
						}
					})			
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:Timeout(iTimeout)
					
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						menuTitle = "Menu Title",
						vrHelp = 
						{
							{
								position = 1,
								 --[[ TODO: update after resolving APPLINK-16052
								image = 
								{
									imageType = "DYNAMIC",
									value = strAppFolder .. imageFile
								},]]
								text = "Help me!"
							}
						},
						menuIcon = 
						{
							imageType = "DYNAMIC",
							value = strAppFolder .. imageFile
						},
						vrHelpTitle = "New VR help title",
						keyboardProperties = 
						{
							keyboardLayout = "QWERTY",
							keypressMode = "SINGLE_KEYPRESS",
							--[[ TODO: update after resolving APPLINK-16047
							limitedCharacterList = 
							{
								"a"
							},]]
							language = "EN-US",
							autoCompleteText = "Daemon, Freedom"
						}
					})			
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:Timeout(iTimeout)
					
					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
				end
				function Test:OpenVRMenu()
					SendOnSystemContext(self,"VRSESSION")
					EXPECT_NOTIFICATION("OnHMIStatus",{ hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "VRSESSION"})
				end	
				TC_DeleteFile_SUCCESS(self, "DeleteFile_"..imageFile, imageFile, imageTypeValue)
				function Test:BackToMain()
					SendOnSystemContext(self,"MAIN")
					EXPECT_NOTIFICATION("OnHMIStatus",{ hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
				end
			end

			local imageFile = {{fileName = "action.png", fileType ="GRAPHIC_PNG"},
								{fileName = "action.bmp", fileType ="GRAPHIC_BMP"}, 
								{fileName = "action.jpeg", fileType ="GRAPHIC_JPEG"}}						

			for i=1,#imageFile do		
				TC_OnFileRemoved_07(imageFile[i].fileName, imageFile[i].fileType)	
			end	
		--End test case SequenceCheck.8
		
		-----------------------------------------------------------------------------------------
		--Print new line to separate new test cases
		commonFunctions:newTestCasesGroup("Test case: TC_OnFileRemoved_08")  				
		--Begin test case SequenceCheck.9
		--Description: Cover TC_OnFileRemoved_08

			--Requirement id in JAMA/or Jira ID: SDLAQ-TC-336

			--Verification criteria: Checking sending OnFileRemoved notification by Core to HMI and changing the Choice  icon to default after deleting file, which was set for the Choice icon, during PerformInteraction. (Checking  for GRAPHIC_BMP, GRAPHIC_JPEG, GRAPHIC_PNG image types).
			local function TC_OnFileRemoved_08(imageFile, imageTypeValue, idValue)
				putfile(self, imageFile, imageTypeValue,_,_,imageFile)					

				function Test:CreateInteractionChoiceSet()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = idValue,
																choiceSet = 
																{	
																	{ 
																		choiceID = idValue,
																		menuName ="Choice"..idValue,
																		vrCommands = 
																		{ 
																			"VRChoice"..idValue,
																		}, 
																		image =
																		{ 
																			value =imageFile,
																			imageType ="DYNAMIC",
																		}, 
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = idValue,
										appID = self.applications[config.application1.registerAppInterfaceParams.appName],
										type = "Choice",
										vrCommands = {"VRChoice"..idValue}
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						grammarIDValue = data.params.grammarID
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
				
				function Test:PerformInteraction()
					local paramsSend = {
						initialText = "StartPerformInteraction",
						initialPrompt = {
											{ 
												text = " Make  your choice ",
												type = "TEXT",
											}
										},
						interactionMode = "MANUAL_ONLY",
						interactionChoiceSetIDList = 
						{ 
							idValue
						},
						helpPrompt = {
										{ 
											text = " Help   Prompt  ",
											type = "TEXT",
										}
									}, 
						timeoutPrompt = {
											{ 
												text = " Time  out  ",
												type = "TEXT",
											}
										},
						timeout = 5000,
						vrHelp = {
									{ 
										text = "  New  VRHelp   ",
										position = 1,	
										image = {
													value = strAppFolder..imageFile,
													imageType = "DYNAMIC",
												}
									}
								},    
						interactionLayout = "ICON_ONLY"
					}
					
					--mobile side: sending PerformInteraction request
					cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{						
						helpPrompt = paramsSend.helpPrompt,
						initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						timeoutPrompt = paramsSend.timeoutPrompt
					})
					:Do(function(_,data)
						--Send notification to start TTS 						
						self.hmiConnection:SendNotification("TTS.Started")
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
					end)								
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{
						timeout = paramsSend.timeout,						
						choiceSet = {
										{
											choiceID = idValue,
											--[[ TODO: update after resolving APPLINK-16052
											image = 
											{
												value = strAppFolder..imageFile,
												imageType = "DYNAMIC",
											},]]
											menuName = "Choice"..idValue
										}
									},
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						}
					})
					:Do(function(_,data)				
						SendOnSystemContext(self,"HMI_OBSCURED")
										
						--mobile side: sending DeleteFile request
						local cid = self.mobileSession:SendRPC("DeleteFile",
						{
							syncFileName = imageFile
						})				
						
						--hmi side: expect BasicCommunication.OnFileRemoved request
						EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved",
						{
							fileName = strAppFolder .. imageFile,
							fileType = imageTypeValue,
							appID = self.applications[config.application1.registerAppInterfaceParams.appName]
						})
						
						--mobile side: expect DeleteFile response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil })
						:ValidIf (function(_,data)
							if data.payload.spaceAvailable == nil then
								commonFunctions:printError("spaceAvailable parameter is missed")
								return false
							else 
								if file_check(strAppFolder .. imageFile) == true then	
									print(" \27[36m File is not delete from storage \27[0m ")
									return false
								else 
									return true
								end				
							end
						end)
						
						local function uiResponse() 
							--hmi side: send UI.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")						
							
							--Send notification to stop TTS 
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 1000)
					end)
								
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self, "MANUAL",_, "FULL")
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
				end
			end

			local imageFile = {{fileName = "action.png", fileType ="GRAPHIC_PNG"},
								{fileName = "action.bmp", fileType ="GRAPHIC_BMP"}, 
								{fileName = "action.jpeg", fileType ="GRAPHIC_JPEG"}}						

			for i=1,#imageFile do		
				TC_OnFileRemoved_08(imageFile[i].fileName, imageFile[i].fileType, i+20)	
			end	
		--End test case SequenceCheck.9
		
		-----------------------------------------------------------------------------------------
		--Print new line to separate new test cases
		commonFunctions:newTestCasesGroup("Test case: TC_OnFileRemoved_09")  				
		--Begin test case SequenceCheck.10
		--Description: Cover TC_OnFileRemoved_09

			--Requirement id in JAMA/or Jira ID: SDLAQ-TC-338

			--Verification criteria: Checking sending OnFileRemoved notification by Core to HMI and changing the Choice  icon to default after deleting file, which was set for the Choice icon, before  PerformInteraction. (Checking  for GRAPHIC_BMP, GRAPHIC_JPEG, GRAPHIC_PNG image types). 
			local function TC_OnFileRemoved_09(imageFile, imageTypeValue, idValue)
				putfile(self, imageFile, imageTypeValue,_,_,imageFile)					

				function Test:CreateInteractionChoiceSet()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = idValue,
																choiceSet = 
																{	
																	{ 
																		choiceID = idValue,
																		menuName ="Choice"..idValue,
																		vrCommands = 
																		{ 
																			"VRChoice"..idValue,
																		}, 
																		image =
																		{ 
																			value =imageFile,
																			imageType ="DYNAMIC",
																		}, 
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = idValue,
										appID = self.applications[config.application1.registerAppInterfaceParams.appName],
										type = "Choice",
										vrCommands = {"VRChoice"..idValue}
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						grammarIDValue = data.params.grammarID
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
				
				TC_DeleteFile_SUCCESS(self, "DeleteFile_"..imageFile, imageFile, imageTypeValue)
				
				function Test:PerformInteraction()
					local paramsSend = {
						initialText = "StartPerformInteraction",
						initialPrompt = {
											{ 
												text = " Make  your choice ",
												type = "TEXT",
											}
										},
						interactionMode = "MANUAL_ONLY",
						interactionChoiceSetIDList = 
						{ 
							idValue
						},
						helpPrompt = {
										{ 
											text = " Help   Prompt  ",
											type = "TEXT",
										}
									}, 
						timeoutPrompt = {
											{ 
												text = " Time  out  ",
												type = "TEXT",
											}
										},
						timeout = 5000,				
						interactionLayout = "ICON_ONLY"
					}
					
					--mobile side: sending PerformInteraction request
					cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{						
						helpPrompt = paramsSend.helpPrompt,
						initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						timeoutPrompt = paramsSend.timeoutPrompt
					})
					:Do(function(_,data)
						--Send notification to start TTS 						
						self.hmiConnection:SendNotification("TTS.Started")
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
					end)								
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{
						timeout = paramsSend.timeout,						
						choiceSet = {
										{
											choiceID = idValue,
											--[[ TODO: update after resolving APPLINK-16052
											image = 
											{
												value = strAppFolder..imageFile,
												imageType = "DYNAMIC",
											},]]
											menuName = "Choice"..idValue
										}
									},
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						}
					})
					:Do(function(_,data)
						--hmi side: send UI.PerformInteraction response
						SendOnSystemContext(self,"HMI_OBSCURED")
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")						
						
						--Send notification to stop TTS 
						self.hmiConnection:SendNotification("TTS.Stopped")							
						SendOnSystemContext(self,"MAIN")						
					end)
								
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self, "MANUAL",_, "FULL")
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
				end
			end

			local imageFile = {{fileName = "action.png", fileType ="GRAPHIC_PNG"},
								{fileName = "action.bmp", fileType ="GRAPHIC_BMP"}, 
								{fileName = "action.jpeg", fileType ="GRAPHIC_JPEG"}}						

			for i=1,#imageFile do		
				TC_OnFileRemoved_09(imageFile[i].fileName, imageFile[i].fileType, i+30)	
			end			
		--End test case SequenceCheck.10		
	--End test suit SequenceCheck	
		
----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	
	-- processing of request/response in different HMIlevels, SystemContext, AudioStreamingState
	
	
	
	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		commonFunctions:printError("****************************** VII TEST BLOCK: Different HMIStatus ******************************")
	end	

	
	--Begin test suit DifferentHMIlevel
	--Description: processing API in different HMILevel

		--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-810

		--Verification criteria: DeleteFile is allowed in NONE, LIMITED, BACKGROUND and FULL HMI level
			
	--Begin test case DifferentHMIlevel.1
		--Description: Check DeleteFile request when application is in NONE HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-810

			--Verification criteria: DeleteFile is allowed in NONE HMI level
			
			-- Precondition 1: Change app to NONE HMI level
			commonSteps:DeactivateAppToNoneHmiLevel()
						
			-- Precondition 2: PutFile
			putfile(self, "test.png", "GRAPHIC_PNG")
			
			TC_DeleteFile_SUCCESS(self, "DeleteFile_HMI_Level_NONE_SUCCESS", "test.png", "GRAPHIC_PNG")
			
			--Postcondition: Activate app
			commonSteps:ActivationApp()

		--End test case DifferentHMIlevel.1
		
		
		--Begin test case DifferentHMIlevel.2
		--Description: Check DeleteFile request when application is in LIMITED HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-810

			--Verification criteria: DeleteFile is allowed in LIMITED HMI level
			
			if commonFunctions:isMediaApp() then
				
				-- Precondition 1: Change app to LIMITED
				commonSteps:ChangeHMIToLimited()

				-- Precondition 2: Put file
				putfile(self, "test.png", "GRAPHIC_PNG")
				
				TC_DeleteFile_SUCCESS(self, "DeleteFile_HMI_Level_LIMITED_SUCCESS", "test.png", "GRAPHIC_PNG")
				
			end
			
		--End test case DifferentHMIlevel.2
		
		
		--Begin test case DifferentHMIlevel.3
		--Description: Check DeleteFile request when application is in BACKGOUND HMI level

			--Requirement id in JAMA/or Jira ID:  SDLAQ-CRS-810

			--Verification criteria: DeleteFile is allowed in BACKGOUND HMI level

			
			-- Precondition 1: Change app to BACKGOUND HMI level
			commonTestCases:ChangeAppToBackgroundHmiLevel()

			-- Precondition 2: Put file
			putfile(self, "test.png", "GRAPHIC_PNG")
			
			TC_DeleteFile_SUCCESS(self, "DeleteFile_HMI_Level_BACKGROUND_SUCCESS", "test.png", "GRAPHIC_PNG")

		--End test case DifferentHMIlevel.3
		
	--End test suit DifferentHMIlevel
	
	--Postcondition: restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()
	
return Test

