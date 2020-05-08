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

APIName = "SetAppIcon" -- use for above required scripts.
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
local appIDAndDeviceMac = config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
config.SDLStoragePath = config.pathToSDL .. "storage/"
local strAppFolder = config.SDLStoragePath..appIDAndDeviceMac
local strIvsu_cacheFolder = "/tmp/fs/mp/images/ivsu_cache/"


local iTimeout = 5000


local str1000Chars = 
	"10123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyza b c                                 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	
local str501Chars = 
	"10123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyza b c                                 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

local str255Chars = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

local FileNames = {"icon.png", "a", "action.png", str255Chars, "app_icon.png"} -- PutFiles
local syncFileName = {"a", "action.png", str255Chars}
local info = {"a", str1000Chars}
local infoName = {"LowerBound", "UpperBound"}
local OutBoundFile = {"", str255Chars.. "a", str501Chars}
local OutBoundFileName = {"Empty", "256Characters", "UpperBound"}
local appID0, appId2

local storagePath = config.SDLStoragePath..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"


---------------------------------------------------------------------------------------------
----------------------------------------Common functions-------------------------------------
---------------------------------------------------------------------------------------------
					
-- check_INVALID_DATA_Result: check response to mobile side incase INVALID_DATA
local function check_INVALID_DATA_resultCode_OnMobile(cid)

	--mobile side: expect SetAppIcon response
	EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
	:Timeout(iTimeout)
	
end		


-- Test case sending request and checking results in case SUCCESS
local function TC_SetAppIcon_SUCCESS(self, strFileName, strTestCaseName)

	Test[strTestCaseName] = function(self)
	
		--mobile side: sending SetAppIcon request
		local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = strFileName })

		--hmi side: expect UI.SetAppIcon request
		EXPECT_HMICALL("UI.SetAppIcon",
		{
			syncFileName = 
			{
				imageType = "DYNAMIC",
				value = storagePath .. strFileName
			}				
		})
		:Timeout(iTimeout)
		:Do(function(_,data)
			--hmi side: sending UI.SetAppIcon response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--mobile side: expect SetAppIcon response
		EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })		
	end
end


function putfiles(sefl, arrFileNames)
	for i=1,#arrFileNames do	
		Test["Precondition_PutFile_"..arrFileNames[i]] = function(self)
		
			--mobile side: sending Futfile request
			local cid = self.mobileSession:SendRPC("PutFile",
													{
														syncFileName = arrFileNames[i],
														fileType	= "GRAPHIC_PNG",
														persistentFile = false,
														systemFile = false
													},
													"files/action.png")

			--mobile side: expect Futfile response
			EXPECT_RESPONSE(cid, { success = true})
			
		end
	end	
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
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})
	
	--3. PutFile to SDL	
	putfiles(sefl, FileNames)
	

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------

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

		--Write TEST_BLOCK_I_Begin to ATF log
		function Test:TEST_BLOCK_I_Begin()
			print("****************************** CommonRequestCheck ******************************")
		end					

				
		
		--Begin test case CommonRequestCheck.1
		--Description: This test is intended to check positive cases and when all parameters 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-158

			--Verification criteria: SetAppIcon request sets up the icon for the application which sends the request. The icon is browsed when the user looks through mobile apps list on HMI.

			strTestCaseName = "SetAppIcon_AllParameters"
			TC_SetAppIcon_SUCCESS(self, "icon.png", strTestCaseName)
	
		--End test case CommonRequestCheck.1
		-----------------------------------------------------------------------------------------		

		--Begin test case PositiveRequestCheck.2
		--Description: check request with only mandatory parameters

			--It is checked in SetAppIcon_AllParameters?	

		--End Test case PositiveRequestCheck.2

		--Skipped CommonRequestCheck.3-4: There next checks are not applicable:
			-- request with all combinations of conditional-mandatory parameters (if exist)
			-- request with one by one conditional parameters (each case - one conditional parameter)

		-----------------------------------------------------------------------------------------



		--Begin test case CommonRequestCheck.5
		--Description: This test is intended to check request with missing mandatory parameters one by one (each case - missing one mandatory parameter)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-731

			--Verification criteria: SDL responses invalid data
			
			function Test:SetAppIcon_missing_mandatory_parameter_INVALID_DATA()						
				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
				{
				
				})
								
				check_INVALID_DATA_resultCode_OnMobile(cid)
			end					

			
		--End test case CommonRequestCheck.5
		-----------------------------------------------------------------------------------------		
	


		--Begin test case PositiveRequestCheck.6
		--Description: check request with all parameters are missing
				
			--It is checked in SetAppIcon_missing_mandatory_parameter_INVALID_DATA

		--End Test case PositiveRequestCheck.6



		--Begin test case PositiveRequestCheck.7
		--Description: check request with fake parameters (fake - not from protocol, from another request)

			--Begin test case CommonRequestCheck.7.1
			--Description: Check request with fake parameters

				--Requirement id in JAMA/or Jira ID: APPLINK-4518

				--Verification criteria: According to xml tests by Ford team all fake parameter should be ignored by SDL
				
				function Test:SetAppIcon_FakeParameters_SUCCESS()
				
					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "icon.png" , fakeParameter = "fakeParameter"})

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:ValidIf(function(_,data)
						if data.params.fakeParameter then
								print(" SDL re-sends fakeParameter to HMI in UI.SetAppIcon request")
								return false
						else 
							return true
						end
					end)						
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })

					
				end				

			--End test case CommonRequestCheck.7.1
			-----------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.7.2
			--Description: Check request with parameters of other request

				--Requirement id in JAMA/or Jira ID: APPLINK-4518

				--Verification criteria: According to xml tests by Ford team all fake parameter should be ignored by SDL
				
				function Test:SetAppIcon_ParametersOfOtherRequest_SUCCESS()
				
					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "icon.png" , sliderHeader ="sliderHeader"})

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:ValidIf(function(_,data)
						if data.params.sliderHeader then
								print(" SDL re-sends sliderHeader to HMI in UI.SetAppIcon request")
								return false
						else 
							return true
						end
					end)						
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })

					
				end				

			--End test case CommonRequestCheck.7.2
			-----------------------------------------------------------------------------------------
			
		--End Test case PositiveRequestCheck.7	

		
		
		--Begin test case CommonRequestCheck.8
		--Description: Check request is sent with invalid JSON structure

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-731

			--Verification criteria: The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.
				
			-- missing ':' after syncFileName
			--payload          = '{"syncFileName":"icon.png"}'
			payload          = '{"syncFileName" "icon.png"}'
					  
			commonTestCases:VerifyInvalidJsonRequest(35, payload)
						
		--End test case CommonRequestCheck.8
		-----------------------------------------------------------------------------------------
			
			
		--Begin test case CommonRequestCheck.9
		--Description: check request with correlation Id is duplicated

			--Requirement id in JAMA/or Jira ID: APPLINK-14293

			--Verification criteria: The response comes with SUCCESS result code.

			function Test:SetAppIcon_CorrelationID_Duplicated_SUCCESS()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })

				local msg = 
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 35, --SetAppIconID
					rpcCorrelationId = cid,
					payload          = '{"syncFileName":"action.png"}'
				}					
				
				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					},
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "action.png"
						}				
					}
				)
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						self.mobileSession:Send(msg)
					end
					--hmi side: sending UI.SetAppIcon response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
					
				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })	
				:Times(2)

			end

		--End test case CommonRequestCheck.9
		-----------------------------------------------------------------------------------------

		
		--Write TEST_BLOCK_I_End to ATF log
		function Test:TEST_BLOCK_I_End()
			print("********************************************************************************")
		end					
		
	--End Test suit PositiveRequestCheck	
	

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

		--Write TEST_BLOCK_II_Begin to ATF log
		function Test:TEST_BLOCK_II_Begin()
			print("******************************** Positive cases ********************************")
		end		
	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--


		--Begin test suit PositiveRequestCheck
		--Description: check of each request parameter value in bound and boundary conditions
		
			--Begin test case PositiveRequestCheck.1
			--Description: check of each request parameter value in bound and boundary conditions of syncFileName

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-158, SDLAQ-CRS-730

				--Verification criteria: SetAppIcon request sets up the icon for the application, the icon is browsed when the user looks through mobile apps list on HMI. Response is returned to mobile app, resultCode is "SUCCESS".
				
				for i=1,#syncFileName do					
					
					strTestCaseName = "SetAppIcon_syncFileName_InBound_" .. tostring(syncFileName[i]).."_SUCCESS"
					TC_SetAppIcon_SUCCESS(self, syncFileName[i], strTestCaseName)						
				end						


			--End test case PositiveRequestCheck.1
			-----------------------------------------------------------------------------------------


		--End Test suit PositiveRequestCheck


	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- parameters with values in boundary conditions

		
		--Begin test suit PositiveResponseCheck
		--Description: Check positive responses 



			--Begin test case PositiveResponseCheck.1
			--Description: Check info parameter when SetAppIcon response with min-length, max-length

				--Requirement id in JAMA/or Jira ID: N/A

				--Verification criteria: verify SDL responses with info parameter value in min-length, max-length
				
				for i=1,#info do										
					Test["SetAppIcon_Response_info_Parameter_InBound_" .. tostring(infoName[i]).."_SUCCESS"] = function(self)

						--mobile side: sending SetAppIcon request
						local cid = self.mobileSession:SendRPC("SetAppIcon",
							{
								syncFileName = "icon.png"
							}
						)

						--hmi side: expect UI.SetAppIcon request
						EXPECT_HMICALL("UI.SetAppIcon",
						{
							syncFileName = 
							{
								imageType = "DYNAMIC",
								value = storagePath .. "icon.png"
							}				
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetAppIcon response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = info[i]})
						end)

						
						--mobile side: expect SetAppIcon response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", info = info[i]})
						:Timeout(iTimeout)
		
					end
				end						
				
			--End test case CommonRequestCheck.1
			-----------------------------------------------------------------------------------------
				
		--End Test suit PositiveResponseCheck

		--Write TEST_BLOCK_II_End to ATF log
		function Test:TEST_BLOCK_II_End()
			print("********************************************************************************")
		end		

----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

		--Write TEST_BLOCK_III_Begin to ATF log
		function Test:TEST_BLOCK_III_Begin()
			print("******************************** Negative cases ********************************")
		end		
		
	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--
		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

	--Begin test suit NegativeRequestCheck
	--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.


		--Begin test case NegativeRequestCheck.1
		--Description: check of each request parameter value in bound and boundary conditions of syncFileName

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-158, SDLAQ-CRS-731

			--Verification criteria: SDL returns INVALID_DATA

			for i=1,#OutBoundFile do
				Test["SetAppIcon_syncFileName_OutBound_" .. tostring(OutBoundFileName[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = OutBoundFile[i]
					})

					--Check results on mobile side (and HMI if it is applicable)
					check_INVALID_DATA_resultCode_OnMobile(cid, false, "INVALID_DATA")
				 
				end
			end						


		--End test case NegativeRequestCheck.1
		-----------------------------------------------------------------------------------------



		--Begin test case NegativeRequestCheck.2
		--Description: invalid values(empty, missing, nonexistent, duplicate, invalid characters)

	
			--Begin test case NegativeRequestCheck.2.1
			--Description: Check properties parameter is -- invalid values(empty) - The request with empty "syncFileName" is sent

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-158, SDLAQ-CRS-731

				--Verification criteria: SDL responses with INVALID_DATA result code. 

				function Test:SetAppIcon_syncFileName_IsInvalidValue_Empty_INVALID_DATA()
				
					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = ""
					})

					--Check results on mobile side (and HMI if it is applicable)
					check_INVALID_DATA_resultCode_OnMobile(cid, false, "INVALID_DATA")
								
				end
			
			--End test case NegativeRequestCheck.2.1
			-----------------------------------------------------------------------------------------		
	

			--Begin test case NegativeRequestCheck.2.2
			--Description: Check the request without "syncFileName" is sent, the INVALID_DATA response code is returned.

				--It is covered by SetAppIcon_missing_mandatory_parameter_INVALID_DATA
			
			--End test case NegativeRequestCheck.2.2
			-----------------------------------------------------------------------------------------	



			--Begin test case NegativeRequestCheck.2.3
			--Description: Check the request with nonexistent value is sent, the INVALID_DATA response code is returned.

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-158, SDLAQ-CRS-731

				--Verification criteria: SDL responses with INVALID_DATA result code. 

				function Test:SetAppIcon_syncFileName_IsInvalidValue_nonexistent_INVALID_DATA()
				
					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "nonexistentButton"
					})

					--Check results on mobile side (and HMI if it is applicable)
					check_INVALID_DATA_resultCode_OnMobile(cid, false, "INVALID_DATA")
								
				end
			
			--End test case NegativeRequestCheck.2.3
			-----------------------------------------------------------------------------------------	
		


			--Begin test case NegativeRequestCheck.2.4
			--Description: invalid values(duplicate)	
				
				--This check is not applicable for SetAppIcon
				
			--End Test case NegativeRequestCheck.2.4

			

			--Begin test case NegativeRequestCheck.2.5
			--Description: Check the request with invalid characters is sent, the INVALID_DATA response code is returned.

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-158, SDLAQ-CRS-731

				--Verification criteria: SDL responses with INVALID_DATA result code. 

				function Test:SetAppIcon_syncFileName_IsInvalidValue_InvalidCharacters_NewLine_INVALID_DATA()
				
					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "a\nb"
					})

					--Check results on mobile side (and HMI if it is applicable)
					check_INVALID_DATA_resultCode_OnMobile(cid, false, "INVALID_DATA")
								
				end
				
				function Test:SetAppIcon_syncFileName_IsInvalidValue_InvalidCharacters_Tab_INVALID_DATA()
				
					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "a\tb"
					})

					--Check results on mobile side (and HMI if it is applicable)
					check_INVALID_DATA_resultCode_OnMobile(cid, false, "INVALID_DATA")
								
				end

				function Test:SetAppIcon_syncFileName_IsInvalidValue_InvalidCharacters_OnlySpaces_INVALID_DATA()
				
					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "  "
					})

					--Check results on mobile side (and HMI if it is applicable)
					check_INVALID_DATA_resultCode_OnMobile(cid, false, "INVALID_DATA")
								
				end					
			--End test case NegativeRequestCheck.2.5
			-----------------------------------------------------------------------------------------	

	

		--End Test case NegativeRequestCheck.2


		--Begin test case NegativeRequestCheck.3
		--Description: Check the request with wrong data type in syncFileName parameter


				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-731

				--Verification criteria: The response with INVALID DATA result code is returned.

				function Test:SetAppIcon_syncFileName_IsInvalidValue_WrongDataType_INVALID_DATA()
				
					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = 123
					})

					--Check results on mobile side (and HMI if it is applicable)
					check_INVALID_DATA_resultCode_OnMobile(cid, false, "INVALID_DATA")
								
				end						

		--End test case NegativeRequestCheck.3
		-----------------------------------------------------------------------------------------		


	--End test suit NegativeRequestCheck

	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json

	--Begin test suit NegativeResponseCheck
	--Description: check negative response from HMI

		--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-159

		--Verification criteria:  The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
		

--[[TODO: update after resolving APPLINK-14551
		--Begin test case NegativeResponseCheck.1
		--Description: check negative response from HMI in case outbound values of info parameter

			--Requirement id in JAMA/or Jira ID: APPLINK-14551, SDLAQ-CRS-159

			--Verification criteria: info parameter value is truncated to max-length
			
			function Test:SetAppIcon_Response_info_Parameter_OutBound_SUCCESS()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = str1000Chars .."z"})
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", info = str1000Chars})
				:Timeout(iTimeout)

			end
				
			
		--End test case NegativeResponseCheck.1
		-----------------------------------------------------------------------------------------
	


		--Begin test case NegativeResponseCheck.2
		--Description: check negative response from HMI in case invalid values(empty, missing, nonexistent, invalid characters)

			--Requirement id in JAMA/or Jira ID: APPLINK-14551, SDLAQ-CRS-159

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				

			--Begin test case NegativeResponseCheck.2.1
			--Description: check negative response from HMI in case invalid values(empty)
	
				-- info parameter is empty => SUCCESS with info is empty 									
				function Test:SetAppIcon_Response_info_Parameter_Empty_SUCCESS()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = ""})
						self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
					end)

					
					--mobile side: expect SetAppIcon response
					--EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
					:ValidIf (function(_,data)
						if data.payload.info then
							print(" SDL resend empty info to mobile app ")
							return false
						else 
							return true
						end
					end)
	
				end				
				]]
		--[[TODO: updated after resolving APPLINK-14765
				-- method parameter is empty => GENERIC_ERROR 							
				function Test:SetAppIcon_Response_method_parameter_empty_GENERIC_ERROR()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
					end)

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
	
				end	

				-- resultCode parameter is empty								
				function Test:SetAppIcon_Response_resultCode_parameter_IsEmpty_GenericError()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, data.method, "", {})
					end)

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response"})
					:Timeout(iTimeout)
	
				end

			--End test case NegativeResponseCheck.2.1
			-----------------------------------------------------------------------------------------		
		]]
				
			--Begin test case NegativeResponseCheck.2.2
			--Description: check negative response from HMI in case invalid values(missing)
		--[[TODO: update after resolving APPLINK-14765
				-- info parameter is missing => SUCCESS without info parameter						
				function Test:SetAppIcon_Response_info_Parameter_missing_SUCCESS()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
						if data.payload.info then
							print(" SDL send empty info to mobile app ")
							return false
						else 
							return true
						end
					end)
	
				end				
				
				-- method parameter is missing => GENERIC_ERROR 						
				function Test:SetAppIcon_Response_method_Parameter_missing_GENERIC_ERROR()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
					end) 

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
	
				end				

				-- resultCode parameter is missing => INVALID_DATA 						
				function Test:SetAppIcon_Response_resultcode_parameter_missing_INVALID_DATA()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"method":"UI.SetAppIcon"}}')
					end) 

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
	
				end				

				-- mandatory parameters are missing => GENERIC_ERROR 							
				function Test:SetAppIcon_Response_mandatory_parameters_are_missed_GENERIC_ERROR()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"info":"abc"}}')
					end) 

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
	
				end	
				
				-- all parameters are missing => GENERIC_ERROR 						
				function Test:SetAppIcon_Response_all_parameters_are_missed_GENERIC_ERROR()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:Send('{"jsonrpc":"2.0","result":{}}')
					end) 

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
	
				end					

			--End test case NegativeResponseCheck.2.2
		]]
			-----------------------------------------------------------------------------------------
		--[[TODO: update fter resolving APPLINK-14551	
			--Begin test case NegativeResponseCheck.2.3
			--Description: check negative response from HMI in case invalid values(invalid characters)
				
				-- info parameter is invalid characters: \t => SUCCESS with invalid character							
				function Test:SetAppIcon_Response_info_Parameter_Invalid_Character_Tab_SUCCESS()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a\tb"})
					end)

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
						if data.payload.info then
							print(" SDL resend invalid info to mobile app: info = " .. tostring(data.payload.info))
							return false
						else 
							return true
						end
					end)
	
				end
					
								
				-- info parameter is invalid characters: \n => SUCCESS with invalid character								
				function Test:SetAppIcon_Response_info_Parameter_Invalid_Character_NewLine_SUCCESS()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a\nb"})
					end)

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
						if data.payload.info then
							print(" SDL resend invalid info to mobile app: info = " .. tostring(data.payload.info))
							return false
						else 
							return true
						end
					end)
	
				end
			
			--End test case NegativeResponseCheck.2.3
		]]
			-----------------------------------------------------------------------------------------
		--[[TODO: update after resolving APPLINK-14765
			--Begin test case NegativeResponseCheck.2.4
			--Description: check negative response from HMI in case invalid values(nonexistent)
			
				-- resultCode parameter is invalid: None existing value									
				function Test:SetAppIcon_Response_resultCode_Parameter_Invalid_NonExisting_SUCCESS()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, data.method, "InvalidCode", {})
					end)

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response"})
	
				end
				
													
			--End test case NegativeResponseCheck.2.4
			-----------------------------------------------------------------------------------------

		--End Test case NegativeResponseCheck.2
		


		--Begin test case NegativeResponseCheck.3
		--Description: check negative response from HMI in case parameters is wrong type
		
			--ToDo: Should be updated according to APPLINK-13276
			
			-- info parameter is wrong type => What does SDL do in this case?								
			function Test:SetAppIcon_Response_info_Parameter_IsWrongType_SUCCESS()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = 123})
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
				:ValidIf (function(_,data)
					if data.payload.info then
						print(" SDL resend wrong data type of info to mobile app. info = " .. tostring(data.payload.info))
						return false
					else 
						return true
					end
				end)

			end

			-- method parameter is wrong type => GENERIC_ERROR 							
			function Test:SetAppIcon_Response_method_parameter_wrong_type_GENERIC_ERROR()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					self.hmiConnection:SendResponse(data.id, 123, "SUCCESS", {})
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)

			end	
			
			
			-- resultCode parameter is wrong type								
			function Test:SetAppIcon_Response_resultCode_Parameter_IsWrongType_GenericError()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					self.hmiConnection:SendResponse(data.id, data.method, 456, {})
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response"})
				:Timeout(iTimeout)

			end

											
		--End test case NegativeResponseCheck.3
		-----------------------------------------------------------------------------------------				

]]

			
		--Begin test case NegativeResponseCheck.4
		--Description: check negative response from HMI in case invalid json
	--[[TODO: Update after resolving APPLINK-13418, APPLINK-14765								
			function Test:SetAppIcon_Response_Invalid_JSON_GENERIC_ERROR()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = 123})
					
					--change ":" by " " after "code"
					--self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code":0,"method":"UI.SetAppIcon"}}')
					  self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code" 0,"method":"UI.SetAppIcon"}}')								
				end)					

				
				--mobile side: expect SetAppIcon response
				--EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", info = nil})
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = nil})
				:Timeout(12000)

			end

]]--	

		--End test case NegativeResponseCheck.4
		-----------------------------------------------------------------------------------------
		
	--End Test suit NegativeResponseCheck
		
		--Write TEST_BLOCK_III_End to ATF log
		function Test:TEST_BLOCK_III_End()
			print("********************************************************************************")
		end		


		
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

	--Check all uncovered pairs resultCodes+success

	--Begin test suit ResultCodeCheck
	--Description: check result code of response to Mobile (SDLAQ-CRS-729)

		--Write TEST_BLOCK_IV_Begin to ATF log
		function Test:TEST_BLOCK_IV_Begin()
			print("****************************** Result code check *******************************")
		end		
		
		--Begin test case ResultCodeCheck.1
		--Description: Check resultCode: SUCCESS

			-- It was checked by other case such as SetAppIcon_AllParameters
			
		--End test case ResultCodeCheck.1
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.2
		--Description: Check resultCode: INVALID_DATA

			--It is covered by SetAppIcon_syncFileName_IsInvalidValue_nonexistent_INVALID_DATA		
			
		--End test case ResultCodeCheck.2
		-----------------------------------------------------------------------------------------


		--Begin test case ResultCodeCheck.3
		--Description: Check resultCode: OUT_OF_MEMORY

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-732

			--Verification criteria: A SetAppIcon request is sent under conditions of RAM deficit for executing it. The response code OUT_OF_MEMORY is returned
			
			--ToDo: Can not check this case.	
			
		--End test case ResultCodeCheck.3
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.4
		--Description: Check resultCode: TOO_MANY_PENDING_REQUESTS

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-733

			--Verification criteria: SDL response TOO_MANY_PENDING_REQUESTS resultCode
			
			--Move to another script: ATF_SetAppIcon_TOO_MANY_PENDING_REQUESTS.lua
			
		--End test case ResultCodeCheck.4
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.5
		--Description: Check resultCode: APPLICATION_NOT_REGISTERED

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-734

			--Verification criteria: SDL responses APPLICATION_NOT_REGISTERED resultCode 			
					
			--Precondition: Creation New Session
			commonSteps:precondition_AddNewSession()
			
			--Description: Send SetAppIcon when application not registered yet.			
			function Test:SetAppIcon_resultCode_APPLICATION_NOT_REGISTERED()
			
				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession2:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--mobile side: expect SetAppIcon response
				self.mobileSession2:ExpectResponse(cid, {success = false, resultCode = "APPLICATION_NOT_REGISTERED"})
				
			end
			
		--End test case ResultCodeCheck.5
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.6
		--Description: Check resultCode: REJECTED 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-735

			--Verification criteria: In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.

												
			function Test:SetAppIcon_resultCode_REJECTED()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {info = ""})
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "REJECTED", info = ""})
				:Timeout(iTimeout)

			end				
			

		--End test case ResultCodeCheck.6
		-----------------------------------------------------------------------------------------
		
		--Begin test case ResultCodeCheck.7
		--Description: Check resultCode: GENERIC_ERROR

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-736

			--Verification criteria: no UI response during SDL`s watchdog. SDL->app: SetAppIcon (resultCode: GENERIC_ERROR, success: false, "info": "UI component does not respond")
											
			function Test:SetAppIcon_resultCode_GENERIC_ERROR()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {info = "a"})
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info ="a"})

			end		
			
		--End test case ResultCodeCheck.7
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.8
		--Description: Check resultCode: UNSUPPORTED_REQUEST

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1043

			--Verification criteria: Feature is not supported on a given platform => Skipped
												
			function Test:SetAppIcon_resultCode_UNSUPPORTED_REQUEST()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					self.hmiConnection:SendResponse(data.id, data.method, "UNSUPPORTED_REQUEST", {info = "a"})
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "UNSUPPORTED_REQUEST", info ="a"})

			end				
			
		--End test case ResultCodeCheck.8
		-----------------------------------------------------------------------------------------	
		
		
		--Write TEST_BLOCK_IV_End to ATF log
		function Test:TEST_BLOCK_IV_End()
			print("********************************************************************************")
		end		
		
	--End Test suit ResultCodeCheck
			
	
----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
	-- requests without responses from HMI
	-- invalid structure os response
	-- several responses from HMI to one request
	-- fake parameters
	-- HMI correlation id check 
	-- wrong response with correct HMI id
	
	
	-- SetAppIcon API does not have any response from HMI. This test suit is not applicable => Ignore
	
		--Write TEST_BLOCK_V_Begin to ATF log
		function Test:TEST_BLOCK_V_Begin()
			print("****************************** HMI negative cases ******************************")
		end		

		
	--Begin test suit HMINegativeCheck
	--Description: Check negative response from HMI

			
		--Begin test case HMINegativeCheck.1
		--Description: Check SetMediaClockTimer requests without UI responses from HMI

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-736

			--Verification criteria: SDL responses GENERIC_ERROR
									
			function Test:SetAppIcon_Without_UI_Response_GENERIC_ERROR()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					--self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {info = ""})
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)

			end	

		--End test case HMINegativeCheck.1
		-----------------------------------------------------------------------------------------


		--Begin test case HMINegativeCheck.2
		--Description: Check responses from HMI (UI) with invalid structure

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-731, SDLAQ-CRS-159

			--Verification criteria: SDL responses INVALID_DATA
								
			function Test:SetAppIcon_UI_ResponseWithInvalidStructure_INVALID_DATA()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					--self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {info = ""})
					
					--Move code outside of result parameter
					--self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code":0,"method":"UI.SetAppIcon"}}')
					  self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"code":0,"result":{"method":"UI.SetAppIcon"}}')
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
				:Timeout(12000)

			end	
			
		--End test case HMINegativeCheck.2
		-----------------------------------------------------------------------------------------	

		
		--Begin test case HMINegativeCheck.3
		--Description: Check several responses from HMI (UI) to one request

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-159

			--Verification criteria: SDL responses SUCCESS
											
			function Test:SetAppIcon_UI_SeveralResponseToOneRequest_SUCCESS()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
				:Timeout(12000)

			end	
			
		--End test case HMINegativeCheck.3
		-----------------------------------------------------------------------------------------

		
		--Begin test case HMINegativeCheck.4
		--Description: check response with fake parameters
		
			--Begin test case HMINegativeCheck.4.1
			--Description: Check responses from HMI (UI) with fake parameter

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-158

				--Verification criteria: SDL does not send fake parameter to mobile.
												
				function Test:SetAppIcon_UI_ResponseWithFakeParamater_SUCCESS()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
					end)

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
			    		if data.payload.fake then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)					

				end					

			--End test case HMINegativeCheck.4.1
			-----------------------------------------------------------------------------------------
			
			--Begin test case HMINegativeCheck.4.2
			--Description: Parameter from another API

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-158

				--Verification criteria: SDL does not send parameter from other API to mobile.
								
				function Test:SetAppIcon_UI_ParamsFromOtherAPIInResponse_SUCCESS()

					--mobile side: sending SetAppIcon request
					local cid = self.mobileSession:SendRPC("SetAppIcon",
						{
							syncFileName = "icon.png"
						}
					)

					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = storagePath .. "icon.png"
						}				
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)

					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" SDL resend parameter of other API to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)					

				end					

			--End test case HMINegativeCheck.4.2
			-----------------------------------------------------------------------------------------
	
		--End Test case HMINegativeCheck.4

		

		--Begin test case HMINegativeCheck.5
		--Description: Check UI wrong response with wrong HMI correlation id

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-159
			
			--Verification criteria: SDL responses GENERIC_ERROR				
							
			function Test:SetAppIcon_UI_ResponseWithWrongHMICorrelationId_GENERIC_ERROR()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}
						self.hmiConnection:SendResponse(data.id + 1, data.method, "SUCCESS", {})
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)

			end		


		--End test case HMINegativeCheck.5
		----------------------------------------------------------------------------------------



		--Begin test case HMINegativeCheck.6
		--Description: Check UI wrong response with correct HMI id

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-159
			
			--Verification criteria: SDL responses GENERIC_ERROR
								
			function Test:SetAppIcon_UI_WrongResponseWithCorrectHMICorrelationId_GENERIC_ERROR()

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName = 
					{
						imageType = "DYNAMIC",
						value = storagePath .. "icon.png"
					}				
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}
						self.hmiConnection:SendResponse(data.id, "UI.Show", "SUCCESS", {})
				end)

				
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)

			end						
			
		--End test case HMINegativeCheck.6
		----------------------------------------------------------------------------------------
				

			
	--End Test suit HMINegativeCheck
		
		--Write TEST_BLOCK_V_End to ATF log
		function Test:TEST_BLOCK_V_End()
			print("********************************************************************************")
		end		


----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

	--Begin test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		-- with emulating of user's actions

		--Write TEST_BLOCK_VI-_Begin to ATF log
		function Test:TEST_BLOCK_VI_Begin()
			print("***************** Sequence with emulating of user's action(s) ******************")
		end		
		
		--Begin test case SequenceCheck.1
		--Description: check scenario in test case TC_SetAppIcon_01

			--It is covered by CommonRequestCheck.1

		--End test case SequenceCheck.1
		-----------------------------------------------------------------------------------------	

		
		--Write TEST_BLOCK_VI_End to ATF log
		function Test:TEST_BLOCK_VI_End()
			print("********************************************************************************")
		end		

	--End Test suit SequenceCheck




----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin test suit DifferentHMIlevel
	--Description: processing API in different HMILevel

		--Write TEST_BLOCK_VII_Begin to ATF log
		function Test:TEST_BLOCK_VII_Begin()
			print("***************************** Different HMIStatus ******************************")
		end		

		
		--Begin test case DifferentHMIlevel.1
		--Description: Check SetAppIcon request when application is in NONE HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-812

			--Verification criteria: SetAppIcon is allowed in NONE HMI level
		
			-- Precondition: Change app to NONE HMI level
			commonSteps:DeactivateAppToNoneHmiLevel()
						
			strTestCaseName = "SetAppIcon_NONE_SUCCESS"
			TC_SetAppIcon_SUCCESS(self, "icon.png", strTestCaseName)	
			
			--Postcondition: Activate app
			commonSteps:ActivationApp()
			
		--End test case DifferentHMIlevel.1
		-----------------------------------------------------------------------------------------
		
		--Begin test case DifferentHMIlevel.2
		--Description: Check SetAppIcon request when application is in LIMITED HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-812

			--Verification criteria: SetAppIcon is allowed in LIMITED HMI level

			if commonFunctions:isMediaApp() then
				
				-- Precondition: Change app to LIMITED
				commonSteps:ChangeHMIToLimited()				
			
				strTestCaseName = "SetAppIcon_LIMITED_SUCCESS"
				TC_SetAppIcon_SUCCESS(self, "icon.png", strTestCaseName)						
			end	
		--End test case DifferentHMIlevel.2
		-----------------------------------------------------------------------------------------


		--Begin test case DifferentHMIlevel.3
		--Description: Check SetAppIcon request when application is in BACKGOUND HMI level

			--Requirement id in JAMA/or Jira ID:  SDLAQ-CRS-812

			--Verification criteria: SetAppIcon is allowed in BACKGOUND HMI level
		
			-- Precondition 1: Change app to BACKGOUND HMI level
			commonTestCases:ChangeAppToBackgroundHmiLevel()
			
			strTestCaseName = "SetAppIcon_BACKGROUND_SUCCESS"
			TC_SetAppIcon_SUCCESS(self, "icon.png", strTestCaseName)				

		--End test case DifferentHMIlevel.3
		-----------------------------------------------------------------------------------------

		--Write TEST_BLOCK_VII_End to ATF log
		function Test:TEST_BLOCK_VII_End()
			print("********************************************************************************")
		end		
		
	--End Test suit DifferentHMIlevel



----------------------------------------------------------------------------------------------------------------
------------------------------------VIII FROM NEW TEST CASES----------------------------------------------------
--------32[ATF]_TC_SetAppIcon: Check that SDL allows PutFile and SetAppIcon requests with the name \<filename>.-
----------------------------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
	--APPLINK-16760: -- Check that SDL allows PutFile and SetAppIcon requests with the name \<filename>.
	--APPLINK-16761: -- Check that SDL allows PutFile and SetAppIcon requests with the name \\<filename>.
	--APPLINK-16762: -- Check that SDL allows PutFile and SetAppIcon requests with the name .\\<filename>.
	--APPLINK-16763: -- Check that SDL allows PutFile and SetAppIcon requests with the name ..\\<filename>.
	--APPLINK-16766: -- Check that SDL allows PutFile and SetAppIcon requests with the name ..<filename>.
	--APPLINK-16767: -- Check that SDL allows PutFile and SetAppIcon requests with the name ...<filename>.
-----------------------------------------------------------------------------------------------


local function SequenceNewTCs()
	

---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------
--Description: Set all parameter for PutFile
function putFileAllParams()
	local temp = { 
		syncFileName ="icon.png",
		fileType ="GRAPHIC_PNG",
		persistentFile =false,
		systemFile = false,
		offset =0,
		length =11600
	} 
	return temp
end
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
--Description: Delete draft file
function DeleteDraftFile(imageFile)
	os.remove(imageFile)
end
--Description: SetAppIcon successfully with default image file
	--imageFile: syncFileName
function Test:setAppIconSuccess(imageFile)
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
		
		--mobile side: expect Putfile response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil })
		:ValidIf (function(_,data) 
			if file_check(strAppFolder .. imageFile) == true then					
				return true
			else 
				print(" \27[36m File is not copy to storage \27[0m ")
				return false
			end
		end)
end
--Description: PutFile successfully with default image file and check copies this file to AppStorageFolder
	--paramsSend: Parameters will be sent to SDL
function Test:putFileSuccess_ex(paramsSend)

	DeleteDraftFile(strAppFolder .. paramsSend.syncFileName)
	
	local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/icon.png")	
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	:ValidIf (function(_,data)
			if data.payload.spaceAvailable == nil then
				commonFunctions:printError("spaceAvailable parameter is missed")
				return false
			else 
				if file_check(strAppFolder .. paramsSend.syncFileName) == true then						
					return true
				else
					print(" \27[36m File is not copy to storage \27[0m ")
					return false
				end				
			end
		end)
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
					print(" \27[36m File is not deleted from storage \27[0m ")
					return false
				else 
					return true
				end				
			end
		end)					
	end
end

---------------------------------------------------------------------------------------------
---------------------------------------End Common function-----------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("-----------------------VIII FROM NEW TEST CASES------------------------------")

	--Description: APPLINK-16760: TC_Path_vulnerabilty_PutFile_and_SetAppIcon_04
					--SDL must respond with INVALID_DATA resultCode in case the name of file that the app requests to upload (related: PutFile, SystemRequest) on the system contains "./" symbol (example: fileName: "./123.jpg")
					--Check that SDL allows PutFile and SetAppIcon requests with the name \<filename>.
				    --TCID: APPLINK-16760
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936
					-- SDLAQ-TC-1321
					
	local function APPLINK_16760()
		-------------------------------------------------------------------------------------------------------------

		--Description: --SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: PutFile, SystemRequest) on the system contains "\" symbol (example: fileName: "\icon.png")
		function Test:APPLINK_16760_Step1_PutFile_syncFileNameBackSlashSymbol() 
			local paramsSend = putFileAllParams()
			paramsSend.syncFileName = "\\icon.png"
			
			self:putFileSuccess_ex(paramsSend)
		end
	
		-------------------------------------------------------------------------------------------------------------
		
		--Description: SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: SetAppIcon, SystemRequest) on the system contains "\" symbol (example: fileName: "\icon.png")
		function Test:APPLINK_16760_Step2_SetAppIcon_syncFileNameBackSlashSymbol()
			
			self:setAppIconSuccess("\\icon.png")
		end
		
		-------------------------------------------------------------------------------------------------------------

		--Description: SDL responses with SUCCESS result code. There is no such file in AppStorageFolder. Icon is disappeared from HMI
		TC_DeleteFile_SUCCESS(self, "APPLINK_16760_Step3_DeleteFile_syncFileNameBackSlashSymbol", "\\icon.png", "GRAPHIC_PNG")
		
		-------------------------------------------------------------------------------------------------------------			
		
	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16761: TC_Path_vulnerabilty_PutFile_and_SetAppIcon_05
					--Check that SDL allows PutFile and SetAppIcon requests with the name \\<filename>.
				    --TCID: APPLINK-16761
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936
					-- SDLAQ-TC-1326
					
	local function APPLINK_16761()
		-------------------------------------------------------------------------------------------------------------

		--Description: --SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: PutFile, SystemRequest) on the system contains double "\" symbol (example: fileName: "\\icon.png")
		function Test:APPLINK_16761_Step1_PutFile_syncFileNameDoubleBackSlashSymbol() 
			local paramsSend = putFileAllParams()
			paramsSend.syncFileName = "\\\\icon.png"
			
			self:putFileSuccess_ex(paramsSend)
		end
	
		-------------------------------------------------------------------------------------------------------------
		
		--Description: SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: SetAppIcon, SystemRequest) on the system contains double "\" symbol (example: fileName: "\\icon.png")
		function Test:APPLINK_16761_Step2_SetAppIcon_syncFileNameDoubleBackSlashSymbol()
			
			self:setAppIconSuccess("\\\\icon.png")
		end
		
		-------------------------------------------------------------------------------------------------------------

		--Description: SDL responses with SUCCESS result code. There is no such file in AppStorageFolder. Icon is disappeared from HMI
		TC_DeleteFile_SUCCESS(self, "APPLINK_16761_Step3_DeleteFile_syncFileNameDoubleBackSlashSymbol", "\\\\icon.png", "GRAPHIC_PNG")
		
		-------------------------------------------------------------------------------------------------------------			
		
	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16762: TC_Path_vulnerabilty_PutFile_and_SetAppIcon_06
					--Check that SDL allows PutFile and SetAppIcon requests with the name .\\<filename>.
				    --TCID: APPLINK-16762
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936
					-- SDLAQ-TC-1327
					
	local function APPLINK_16762()
		-------------------------------------------------------------------------------------------------------------

		--Description: --SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: PutFile, SystemRequest) on the system contains dot and double ".\\" symbol (example: fileName: ".\\icon.png")
		function Test:APPLINK_16762_Step1_PutFile_syncFileNameDotDoubleBackSlashSymbol() 
			local paramsSend = putFileAllParams()
			paramsSend.syncFileName = ".\\\\icon.png"
			
			self:putFileSuccess_ex(paramsSend)
		end
	
		-------------------------------------------------------------------------------------------------------------
		
		--Description: SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: SetAppIcon, SystemRequest) on the system contains double ".\\" symbol (example: fileName: ".\\icon.png")
		function Test:APPLINK_16762_Step2_SetAppIcon_syncFileNameDotDoubleBackSlashSymbol()
			
			self:setAppIconSuccess(".\\\\icon.png")
		end
		
		-------------------------------------------------------------------------------------------------------------

		--Description: SDL responses with SUCCESS result code. There is no such file in AppStorageFolder. Icon is disappeared from HMI
		TC_DeleteFile_SUCCESS(self, "APPLINK_16762_Step3_DeleteFile_syncFileNameDotDoubleBackSlashSymbol", ".\\\\icon.png", "GRAPHIC_PNG")
		
		-------------------------------------------------------------------------------------------------------------			
		
	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16763: TC_Path_vulnerabilty_PutFile_and_SetAppIcon_07
					--Check that SDL allows PutFile and SetAppIcon requests with the name ..\\<filename>.
				    --TCID: APPLINK-16763
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936
					-- SDLAQ-TC-1328
					
	local function APPLINK_16763()
		-------------------------------------------------------------------------------------------------------------

		--Description: --SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: PutFile, SystemRequest) on the system contains double Dot "..\\" symbol (example: fileName: "..\\icon.png")
		function Test:APPLINK_16763_Step1_PutFile_syncFileNameDoubleDotDoubleBackSlashSymbol() 
			local paramsSend = putFileAllParams()
			paramsSend.syncFileName = "..\\\\icon.png"
			
			self:putFileSuccess_ex(paramsSend)
		end
	
		-------------------------------------------------------------------------------------------------------------
		
		--Description: SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: SetAppIcon, SystemRequest) on the system contains double "..\\" symbol (example: fileName: "..\\icon.png")
						--This step is added more. TC doesn't mention.
		function Test:APPLINK_16763_Step2_SetAppIcon_syncFileNameDoubleDotDoubleBackSlashSymbol()
			
			self:setAppIconSuccess("..\\\\icon.png")
		end
		
		-------------------------------------------------------------------------------------------------------------

		--Description: SDL responses with SUCCESS result code. There is no such file in AppStorageFolder. Icon is disappeared from HMI
		TC_DeleteFile_SUCCESS(self, "APPLINK_16763_Step3_DeleteFile_syncFileNameDoubleDotDoubleBackSlashSymbol", "..\\\\icon.png", "GRAPHIC_PNG")
		
		-------------------------------------------------------------------------------------------------------------			
		
	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16766: TC_Path_vulnerabilty_PutFile_and_SetAppIcon_08
					--Check that SDL allows PutFile and SetAppIcon requests with the name ..<filename>.
				    --TCID: APPLINK-16766
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936
					-- SDLAQ-TC-1329
					
	local function APPLINK_16766()
		-------------------------------------------------------------------------------------------------------------

		--Description: --SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: PutFile, SystemRequest) on the system contains double Dot ".." symbol (example: fileName: "..icon.png")
		function Test:APPLINK_16766_Step1_PutFile_syncFileNameDoubleDotSymbol() 
			local paramsSend = putFileAllParams()
			paramsSend.syncFileName = "..icon.png"
			
			self:putFileSuccess_ex(paramsSend)
		end
	
		-------------------------------------------------------------------------------------------------------------
		
		--Description: SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: SetAppIcon, SystemRequest) on the system contains double ".." symbol (example: fileName: "..icon.png")
		function Test:APPLINK_16766_Step2_SetAppIcon_syncFileNameDoubleDotSymbol()
			
			self:setAppIconSuccess("..icon.png")
		end
		
		-------------------------------------------------------------------------------------------------------------

		--Description: SDL responses with SUCCESS result code. There is no such file in AppStorageFolder. Icon is disappeared from HMI
		TC_DeleteFile_SUCCESS(self, "APPLINK_16766_Step3_DeleteFile_syncFileNameDoubleDotSymbol", "..icon.png", "GRAPHIC_PNG")
		
		-------------------------------------------------------------------------------------------------------------			
		
	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16767: TC_Path_vulnerabilty_PutFile_and_SetAppIcon_09
					--Check that SDL allows PutFile and SetAppIcon requests with the name ...<filename>.
				    --TCID: APPLINK-16767
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936
					-- SDLAQ-TC-1330
					
	local function APPLINK_16767()
		-------------------------------------------------------------------------------------------------------------

		--Description: --SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: PutFile, SystemRequest) on the system contains double Dot "..." symbol (example: fileName: "...icon.png")
		function Test:APPLINK_16767_Step1_PutFile_syncFileNameThreeDotSymbol() 
			local paramsSend = putFileAllParams()
			paramsSend.syncFileName = "...icon.png"
			
			self:putFileSuccess_ex(paramsSend)
		end
	
		-------------------------------------------------------------------------------------------------------------
		
		--Description: SDL must respond with SUCCESS resultCode in case the name of file that the app requests to upload (related: SetAppIcon, SystemRequest) on the system contains double "..." symbol (example: fileName: "...icon.png")
		function Test:APPLINK_16767_Step2_SetAppIcon_syncFileNameThreeDotSymbol()
			
			self:setAppIconSuccess("...icon.png")
		end
		
		-------------------------------------------------------------------------------------------------------------

		--Description: SDL responses with SUCCESS result code. There is no such file in AppStorageFolder. Icon is disappeared from HMI
		TC_DeleteFile_SUCCESS(self, "APPLINK_16767_Step3_DeleteFile_syncFileNameThreeDotSymbol", "...icon.png", "GRAPHIC_PNG")
		
		-------------------------------------------------------------------------------------------------------------			
		
	end
	-----------------------------------------------------------------------------------------------------------------	

	
	--Main to execute test cases
	APPLINK_16760()
	APPLINK_16761()
	APPLINK_16762()
	APPLINK_16763()
	APPLINK_16766()
	APPLINK_16767()
	-------------------------------------------------------------------------------------------------------------	
end

SequenceNewTCs()


policyTable:Restore_preloaded_pt()
	
return Test
