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

APIName = "ListFiles" -- use for above required scripts.

local str255Chars = string.rep("a",255)

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

---------------------------------------------------------------------------------------------
-------------------------------------------Common functions-------------------------------------
---------------------------------------------------------------------------------------------

-- Test case sending request and checking results in case SUCCESS
local function TC_ListFiles_SUCCESS(self, strTestCaseName, arrFileNames)

	Test[strTestCaseName] = function(self)
	
		--mobile side: sending ListFiles request
		local cid = self.mobileSession:SendRPC("ListFiles", {} )
		

		--mobile side: expect ListFiles response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", filenames = arrFileNames, info = nil })
		:ValidIf (function(_,data)
			    		if data.payload.spaceAvailable == nil then
			    			print("spaceAvailable parameter is missed")
			    			return false
			    		else 
			    			return true
			    		end

						if data.payload.info ~= nil then
			    			print("info parameter is not nil")
			    			return false
			    		else 
			    			return true
			    		end
						
			    	end)
					
	end
end

--Test case to verify case that file is deleted successfully 
local function TC_DeleteFile_SUCCESS(self, strFileName, strReportName)

	if strReportName == nil then
		strReportName = strFileName
	end
	
	Test["DeleteFile_"..strReportName .. "_SUCCESS"] = function(self)
	
		--mobile side: sending DeleteFile request
		local cid = self.mobileSession:SendRPC("DeleteFile",
		{
			syncFileName = strFileName
		})

		--mobile side: expect DeleteFile response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil })
					
	end
end

--PutFile to SDL with all parameters. If a parameter is missed, default value will be used. 
function putfile(self, strFileName, strFileType, blnPersistentFile, blnSystemFile, strFileNameOnMobile)

	local strTestCaseName, strSyncFileName, strFileNameOnLocal1	
	if type(strFileName) == "table" then
		strTestCaseName = "PutFile_"..strFileName.reportName
		strSyncFileName = strFileName.fileName
	elseif type(strFileName) == "string" then
		strTestCaseName = "PutFile_"..strFileName
		strSyncFileName = strFileName
	else 
		print("Error: PutFile function, strFileName is wrong value type: " .. tostring(strFileName))
	end
	
	if strFileNameOnMobile ==nil then
		strFileNameOnMobile = "bmp_6kb.bmp"
	end
	
	Test[strTestCaseName] = function(self)
	
		--mobile side: sending PutFile request
		local cid = self.mobileSession:SendRPC("PutFile",
												{
													syncFileName = strSyncFileName,
													fileType	= strFileType, 
													persistentFile = blnPersistentFile,
													systemFile = blnSystemFile
												},
												"files/"..strFileNameOnMobile)

		--mobile side: expect PutFile response
		EXPECT_RESPONSE(cid, { success = true})
						
		
	end
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



--Create default request
function Test:createRequest()
	return {}
end

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request)
	
	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--mobile side: expect AddSubMenu response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
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
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})


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
		print("****************************** I TEST BLOCK: Check of mandatory/conditional request's parameters (mobile protocol) ******************************")
	end
	
	--Begin test suit CommonRequestCheck
	--Description:
		-- request with all parameters
		-- request with only mandatory parameters
		-- request with all combinations of conditional-mandatory parameters (if exist)
		-- request with one by one conditional parameters (each case - one conditional parameter)
		-- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
		-- request with all parameters are missing
			--=> One test case for all above checks
			
		-- request with fake parameters (fake - not from protocol, from another request)
		-- request is sent with invalid JSON structure
		-- different conditions of correlationID parameter (invalid, several the same etc.)
	

				
		--Begin test case CommonRequestCheck.1
		--Description: check request with all parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-154

			--Verification criteria: ListFile request returns the list of the file names which are stored in the app's folder on SDL platform.
			
			function Test:ListFiles()
			
				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )
				

				--mobile side: expect ListFiles response
				EXPECT_RESPONSE
				(
					cid, 
					{
						success = true, 
						resultCode = "SUCCESS",
						filenames = {config.application1.registerAppInterfaceParams.fullAppID},
						spaceAvailable = 104857600
					}
				)
				:Do(function(_,data)
					if data.payload.filenames ~= nil then
						return false
					else
						return true					
					end
					
					if data.payload.info ~= nil then
						return false
					else
						return true					
					end
				end) 

							
			end
		
		--End test case CommonRequestCheck.1			
		
		

		--Skipped CommonRequestCheck.2-6: There next checks are not applicable:
			-- request with only mandatory parameters
			-- request with all combinations of conditional-mandatory parameters (if exist)
			-- request with one by one conditional parameters (each case - one conditional parameter)
			-- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
			-- request with all parameters are missing			

				
		--Begin test case CommonRequestCheck.7
		--Description: check request with fake parameters (fake - not from protocol, from another request)

			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake parameters should be ignored by SDL

			--Begin test case CommonRequestCheck.7.1
			--Description: Check request with fake parameters
				
				function Test:ListFiles_FakeParameters_SUCCESS()

					--mobile side: sending ListFiles request
					local cid = self.mobileSession:SendRPC("ListFiles",
					{
						fakeParameter1 = 123,
						fakeParameter2 = "abc"

					})

					--mobile side: expect ListFiles response
					EXPECT_RESPONSE
					(
						cid, 
						{
							success = true, 
							resultCode = "SUCCESS"
						}
					)
					
				end

			--End test case CommonRequestCheck.7.1

			--Begin test case CommonRequestCheck.7.2
			--Description: Check request with fake parameters
				
				function Test:ListFiles_ParametersOfOtherAPI_SUCCESS()

					--mobile side: sending ListFiles request
					local cid = self.mobileSession:SendRPC("ListFiles",
					{
						syncFileName ="icon.png"
					})

					--mobile side: expect ListFiles response
					EXPECT_RESPONSE
					(
						cid, 
						{
							success = true, 
							resultCode = "SUCCESS"
						}
					)
					
				end

			--End test case CommonRequestCheck.7.2		
		
		--End test case CommonRequestCheck.7			

		

		--Begin test case CommonRequestCheck.8
		--Description: Check request is sent with invalid JSON structure

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-723

			--Verification criteria: The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.
		
			local  payload          = '}'
			commonTestCases:VerifyInvalidJsonRequest(34, payload)
						
		--End test case CommonRequestCheck.8



		--Begin test case CommonRequestCheck.9
		--Description: Check correlationID parameter value is duplicated

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-722

			--Verification criteria: response comes with SUCCESS result code.

			function Test:ListFiles_CorrelationID_IsDuplicated_SUCCESS()
					

				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )
				

				--mobile side: expect ListFiles response
				EXPECT_RESPONSE
				(
					cid, 
					{
						success = true, 
						resultCode = "SUCCESS", 
						filenames = nil, 
						info = nil 
					}
				)
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then						
						local msg = 
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 34,
							rpcCorrelationId = cid,					
							payload          = '{}'
						}
						self.mobileSession:Send(msg)
					end
				end)				
				
			end

		--End test case CommonRequestCheck.9

		
	--End test suit CommonRequestCheck	
	



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
	print("****************************** II TEST BLOCK: Positive request check ******************************")
	print("There is no parameter in request => Ignore this part.")
end			




--=================================================================================--
--------------------------------Positive response check------------------------------
--=================================================================================--

--------Checks-----------
-- parameters with values in boundary conditions

--Write NewTestBlock to ATF log
function Test:NewTestBlock()
	print("****************************** II TEST BLOCK: Positive response check ******************************")
end			


--Begin test suit PositiveResponseCheck
--Description: Check positive responses 

		
	--Begin test case PositiveResponseCheck.1
	--Description: Check filenames parameter

		--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-155

		--Verification criteria: Returns the current list of resident filenames for the registered app along with the current space available.
		
		
		--Begin test case PositiveResponseCheck.1.1
		--Description: 
			--Check filenames parameter is missed (nil)
			--Check filenames parameter is min-size => filenames is omitted if no files currently reside on the system.

			--It is covered by CommonRequestCheck.1
			
		--End test case PositiveResponseCheck.1.1
		
		--Begin test case PositiveResponseCheck.1.2
		--Description: Check filenames parameter contains one item with min length (1)

			-- Precondition
			putfile(self, "a", "GRAPHIC_PNG")	
			
			function Test:ListFiles_filenames_oneItem_minLength_1()
			
				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )
				

				--mobile side: expect ListFiles response
				EXPECT_RESPONSE
				(
					cid, 
					{
						success = true, 
						resultCode = "SUCCESS", 
						filenames = {config.application1.registerAppInterfaceParams.fullAppID, "a"}, 
						info = nil 
					}
				)							
			end
			
			-- Delete put file
			TC_DeleteFile_SUCCESS(self, "a")
			
		--End test case PositiveResponseCheck.1.2

		--Begin test case PositiveResponseCheck.1.3
		--Description: Check filenames parameter contains one item with max length of PutFile (255)

			-- Precondition
			putfile(self, str255Chars, "GRAPHIC_PNG")	
			
			function Test:ListFiles_filenames_oneItem_maxLength_255()
			
				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )
				

				--mobile side: expect ListFiles response
				EXPECT_RESPONSE
				(
					cid, 
					{
						success = true, 
						resultCode = "SUCCESS", 
						filenames = {config.application1.registerAppInterfaceParams.fullAppID, str255Chars}, 
						info = nil 
					}
				)							
			end
			
			-- Delete put file
			TC_DeleteFile_SUCCESS(self, str255Chars)
			
		--End test case PositiveResponseCheck.1.3

		--Begin test case PositiveResponseCheck.1.4
		--Description: Check filenames parameter contains max size items with max-length (500)

			-- make an array with 1000 elements, each element has 255 characters.
			local arrFileNames = {}
			local arrFileNames_Report = {}
			local str251Characters = "_255_characters_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

			arrFileNames[1] = config.application1.registerAppInterfaceParams.fullAppID
			for i = 2, 1000 do
				if i<10 then
					arrFileNames[i] = "000" ..tostring(i) .. str251Characters	
					arrFileNames_Report[i] = "000" ..tostring(i)
				elseif i<100 then					
					arrFileNames[i] = "00" ..tostring(i) .. str251Characters
					arrFileNames_Report[i] = "00" ..tostring(i)
				elseif i<1000 then
					arrFileNames[i] = "0" ..tostring(i) .. str251Characters
					arrFileNames_Report[i] = "0" ..tostring(i)
				else
					arrFileNames[i] = tostring(i) .. str251Characters
					arrFileNames_Report[i] = tostring(i)
				end
			end
			
			--Put 999/1000 files
			for j = 2, #arrFileNames do
				putfile(self, {fileName = arrFileNames[j], reportName = arrFileNames_Report[j]}, "GRAPHIC_PNG")					
			end
			
			function Test:ListFiles_filenames_maxsize_1000_minLength()
			
				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )
				

				--mobile side: expect ListFiles response
				EXPECT_RESPONSE
				(
					cid, 
					{
						success = true, 
						resultCode = "SUCCESS", 
						filenames = arrFileNames, 
						info = nil 
					}
				)							
			end

		--End test case PositiveResponseCheck.1.5


		--Begin test case PositiveResponseCheck.1.6
		--Description: Check filenames parameter value in case there are more than 1000 files on app folder
		
			--Note: This is spacial case, move this test case from NegativeResponseCheck to PositiveResponseCheck to reuse precondition: 1000 files was put to SDL.
		

			--PutFile 1001th
			local FileName1001 = "1001_256.png"
			
			putfile(self, FileName1001, "GRAPHIC_PNG")	
							
			function Test:ListFiles_filenames_OutUpperBound_1001()
			
				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )

				--mobile side: expect ListFiles response
				EXPECT_RESPONSE
				(
					cid, 
					{
						success = true, 
						resultCode = "SUCCESS", 
						filenames = arrFileNames
					}
				)
				:ValidIf (function(_,data)
					if #data.payload.filenames > 1000 then
						print("filenames returns more than 1000 files. Number of files is " .. tostring(#data.payload.filenames))
						return false
					else
						return true
					end								
			    end)
					
			
			end
			
			--Delete put files
			for j = 2, #arrFileNames do
				TC_DeleteFile_SUCCESS(self, arrFileNames[j], arrFileNames_Report[j])
			end		
			
			TC_DeleteFile_SUCCESS(self, FileName1001)
			
		--End test case PositiveResponseCheck.1.6

		
	--End test case PositiveResponseCheck.1

	
	--Begin test case PositiveResponseCheck.2-5
	--Description: 
		--Check resultCode parameter		
		--Check method parameter	
		--Check info parameter	
		--Check correlationId parameter	
		
		--=> These parameters are responded by SDL. We cannot test.
		
	--End test case PositiveResponseCheck.2-5

	
	--Begin test case PositiveResponseCheck.6
	--Description: Check spaceAvailable parameter

		--Begin test case PositiveResponseCheck.6.1
		--Description: Check spaceAvailable parameter is upper bound (104857600 -  100 MBs) 
			
			--It is covered by CommonRequestCheck.1
			
		--End test case PositiveResponseCheck.6.1
		
		
		--Begin test case PositiveResponseCheck.6.2
		--Description: Check spaceAvailable parameter is lower bound
		
--[[ToDo: Update this test case when APPLINK-14538 is closed.

			--PutFile to make applicaton folder is full.
			local addedFiles = {}
			for i = 1, 23 do
				putfile(self,  tostring(i) .."_MP3_4555kb.mp3", "AUDIO_MP3")

				table.insert(addedFiles, tostring(i) .."_MP3_4555kb.mp3") 
			end
										
			function Test:ListFiles_spaceAvailable_LowerBound()
			
				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )

				--mobile side: expect ListFiles response
				EXPECT_RESPONSE
				(
					cid, 
					{
						success = true, 
						resultCode = "SUCCESS", 
						spaceAvailable = 0
					}
				)							
			end

			for j = 1, #addedFiles do
				TC_DeleteFile_SUCCESS(self, addedFiles[j], addedFiles[j])
			end
		
		--End test case PositiveResponseCheck.6.2			
		]]
	--End test case PositiveResponseCheck.6
		
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
			print("****************************** III TEST BLOCK: Negative request check ******************************")
			print("There is no parameter in request => Ignore this part.")
		end		
		
	--Begin test suit NegativeRequestCheck
	--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.
	
		--Begin test case NegativeRequestCheck.1-3
		--Description: 
			--Check parameter value is out bound
			--Check parameter is invalid values(empty, missing, nonexistent, duplicate, invalid characters)
			--check syncFileName parameter is wrong type

			--=>These checks are not applicable for this request. => Ignore
			
		--End test case NegativeRequestCheck.1-3		
		
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
			print("****************************** III TEST BLOCK: Negative response check ******************************")
			print("There is no response from HMI => Ignore this part.")
			
		end	

		
	--Begin test suit NegativeResponseCheck
	--Description: Check of filenames parameter value is out of bound

		--Begin test case NegativeResponseCheck.1
		--Description: Check filenames parameter value in case there are more than 1000 files on app folder
		
		--This test case is coverted by TC PositiveResponseCheck.1.6

	--End test suit NegativeResponseCheck
		

		

		
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------	

	--Check all uncovered pairs resultCodes+success
	
	
	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		print("****************************** IV TEST BLOCK: Result code check ******************************")
	end	
		

	--Begin test suit ResultCodeCheck
	--Description: check result code of response to Mobile

		--Begin test case resultCodeCheck.1
		--Description: Check resultCode: APPLICATION_NOT_REGISTERED

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-726

			--Verification criteria: SDL returns APPLICATION_NOT_REGISTERED code for the request sent within the same connection before RegisterAppInterface has been performed yet.
				
			--Precondition: Create new session
			commonSteps:precondition_AddNewSession()
		
			function Test:ListFiles_resultCode_APPLICATION_NOT_REGISTERED()
							
				--mobile side: sending ListFiles request
				local cid = self.mobileSession2:SendRPC("ListFiles", {} )		

				--mobile side: expect ListFiles response
				self.mobileSession2:ExpectResponse(cid, {success = false, resultCode = "APPLICATION_NOT_REGISTERED", info = nil})
				
			end
			
		--End test case resultCodeCheck.1
		

		--Begin test case resultCodeCheck.2
		--Description: Check resultCode: REJECTED 
			
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-727
			
			--Verification criteria:  . In case app in HMI level of NONE sends ListFiles_request AND the number of requests more than value of 'ListFilesRequest' parameter (defined in .ini file) SDL must respond REJECTED result code to this mobile app
			

			-- Precondition: Change app to NONE HMI level
			commonSteps:DeactivateAppToNoneHmiLevel()
			
			-- Precondition: Send ListFiles 5 times
			files = {"first_file", "second_file", "third_file", "fourth_file", "fifth_file"}
			for i = 1, 5 do
				Test["ListFiles_".. files[i] .. "_SUCCESS"] = function(self)
					--mobile side: sending ListFiles request
					local cid = self.mobileSession:SendRPC("ListFiles", {} )
					
					--mobile side: expect ListFiles response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })									
				end
			end

						
			Test["ListFiles_6th_time_REJECTED"] = function(self)

				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )
											
				--mobile side: expect ListFiles response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED", info = nil})		
			end

			-- Activate app again
			commonSteps:ActivationApp()
		
		--End test case resultCodeCheck.2
		
				

		--Begin test case resultCodeCheck.3
		--Description: Check resultCode: UNSUPPORTED_REQUEST

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1042
			--Verification criteria: The platform doesn't support file operations, the UNSUPPORTED_REQUEST responseCode is returned. General request result is success=false.
			
			--Per APPLINK-9867, current HeadUnit supports ListFiles API so that this requirement is not applicable.
			
		--End test case resultCodeCheck.3

		
	--End test suit resultCodeCheck



----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------

	
	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		print("****************************** V TEST BLOCK: HMI negative cases ******************************")
		print("There is no response from HMI => Ignore this part.")
	end	
		

	
----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

	-- Check different request sequence with timeout, emulating of user's actions


	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		print("****************************** VI TEST BLOCK: Sequence with emulating of user's action(s) ******************************")
	end	
	
	--Begin test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		-- with emulating of user's actions
				
		--Begin test case SequenceCheck.1
		--Description: Check scenario in test case TC_ListFiles_01: Check stored files from mobile device on SDL Core using ListFiles request

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-154

			--Verification criteria: ListFiles request returns the list of the file names which are stored in the app's folder on SDL platform.

						
			-- Precondition: PutFile action.png, turn_forward.png, turn_left.png, icon.png, turn_right.png	
			
			putfile(self, "1action.png", "GRAPHIC_PNG")
			putfile(self, "2turn_forward.png", "GRAPHIC_PNG")
			putfile(self, "3turn_left.png", "GRAPHIC_PNG")
			putfile(self, "4icon.png", "GRAPHIC_PNG")
			putfile(self, "5turn_right.png", "GRAPHIC_PNG")
			
			
			Test["TC_ListFiles_01_Before_PutFile"] = function(self)
			
				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )
				
				--mobile side: expect DeleteFile response
				EXPECT_RESPONSE(cid, 
					{
						success = true, 
						resultCode = "SUCCESS",
						filenames = 
						{
							config.application1.registerAppInterfaceParams.fullAppID,
							"1action.png",
							"2turn_forward.png",
							"3turn_left.png",
							"4icon.png",
							"5turn_right.png"
						}
					}
				)
			end
			
			putfile(self, "6image.png", "GRAPHIC_PNG")
			
			Test["TC_ListFiles_01_After_PutFile"] = function(self)
			
				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )
				
				--mobile side: expect DeleteFile response
				EXPECT_RESPONSE(cid, 
					{
						success = true, 
						resultCode = "SUCCESS",
						filenames = 
						{
							config.application1.registerAppInterfaceParams.fullAppID,
							"1action.png",
							"2turn_forward.png",
							"3turn_left.png",
							"4icon.png",
							"5turn_right.png",
							"6image.png"
						}
					}
				)
			end	
			
			TC_DeleteFile_SUCCESS(self, "6image.png")
			
			Test["TC_ListFiles_01_After_DeleteFile"] = function(self)
			
				--mobile side: sending ListFiles request
				local cid = self.mobileSession:SendRPC("ListFiles", {} )
				
				--mobile side: expect DeleteFile response
				EXPECT_RESPONSE(cid, 
					{
						success = true, 
						resultCode = "SUCCESS",
						filenames = 
						{
							config.application1.registerAppInterfaceParams.fullAppID,
							"1action.png",
							"2turn_forward.png",
							"3turn_left.png",
							"4icon.png",
							"5turn_right.png"
						}
					}
				)
				:ValidIf (function(_,data)
					local result = true
					for i = 1, #data.payload.filenames do
						if "6image.png" == data.payload.filenames[i] then
							print("Deleted file is still in response of ListFiles request")
			    			result = false
						end						
					end
					return result
						
			    end)
			end
			
			--Post condition
			TC_DeleteFile_SUCCESS(self, "1action.png")
			TC_DeleteFile_SUCCESS(self, "2turn_forward.png")
			TC_DeleteFile_SUCCESS(self, "3turn_left.png")
			TC_DeleteFile_SUCCESS(self, "4icon.png")
			TC_DeleteFile_SUCCESS(self, "5turn_right.png")
				
		--End test case SequenceCheck.1

		--------------------------------------------------------------------------------------------------------
		--Begin test case SequenceCheck.2
		--Description: SDL doesn't list files in ListFiles response, loaded by PutFile with parameter systemRequest=true. ListFiles shows list of file names stored in App's directory, and files loaded as system, stored in separate folder.

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-154
			--TC id in Jira: APPLINK-18321

			--Verification criteria: ListFiles shows list of file names stored in App's directory, and files loaded as system, stored in separate folder.

		local function Task_APPLINK_15934()
			function GetParamValue(parameterName)
			  -- body
			  local iniFilePath = config.pathToSDL .. "smartDeviceLink.ini"
			  local iniFile = io.open(iniFilePath)
			  if iniFile then
				for line in iniFile:lines() do
				  if line:match(parameterName) then
					local version = line:match("=.*")
						version = string.gsub(version, "=", "")
						version = string.gsub(version, "% ", "")
					return version
				  end
				end
			  else
				  return nil
			  end
			end
			
			--Precondition:Start new session
			function Test:Precondition_NewSession5()
				--mobile side: start new session
				self.mobileSession5 = mobile_session.MobileSession(
				self,
				self.mobileConnection)
			end
					
			--Register new app5
			function Test:Precondition_AppRegistrationInNewSession_App5()
				--mobile side: start new 
				self.mobileSession5:StartService(7)
				:Do(function()
						local cid = self.mobileSession5:SendRPC("RegisterAppInterface",
						{
						  syncMsgVersion =
						  {
							majorVersion = 3,
							minorVersion = 0
						  },
						  appName = "App5",
						  isMediaApplication = false,
						  languageDesired = 'EN-US',
						  hmiDisplayLanguageDesired = 'EN-US',
						  appHMIType = { "NAVIGATION" },
						  appID = "5"
						})
						
						--hmi side: expect BasicCommunication.OnAppRegistered request
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						{
						  application = 
						  {
							appName = "App5"
						  }
						})
						:Do(function(_,data)
						  self.applications["App5"] = data.params.application.appID
						end)
						
						--mobile side: expect response
						self.mobileSession5:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
						:Timeout(2000)

						self.mobileSession5:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end)
				end
				
			--PutFile on App5 with systemFile = false
				
				function Test:PutFile_App5_systemFilefalse() 
					local paramsSend = { 
										syncFileName ="icon.png",
										fileType ="GRAPHIC_PNG",
										systemFile = false
									} 
									
					--mobile side: sending PutFile request
					local cid = self.mobileSession5:SendRPC("PutFile",paramsSend, "files/icon.png")	
					--mobile side: expected PutFile response
					self.mobileSession5:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
				
					:ValidIf (function(_,data)
						app5StoragePath = config.pathToSDL .. GetParamValue("AppStorageFolder").."/" .."5".. "_" .. config.deviceMAC.. "/"
							print(app5StoragePath.."icon.png")
							if file_check(app5StoragePath.."icon.png") ~= true then									
								print(" \27[36m Can not found file: icon.png \27[0m ")
								return false
							else 
								return true
							end
						end)
				
				end

			--Checking files: ListFiles - the list contain icon.png only
				function Test:ListFiles_App5_systemFilefalse()				
					
					--mobile side: sending ListFiles request					
					local cid = self.mobileSession5:SendRPC("ListFiles", {} )					

					--mobile side: expect ListFiles response
					self.mobileSession5:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
					
				end

			--PutFile on App5: systemFile = true
				function Test:PutFile_App5_systemFiletrue() 
					local paramsSend = { 
									syncFileName ="bmp_6kb.bmp",
									fileType ="GRAPHIC_BMP",
									systemFile = true
								} 
					--mobile side: sending PutFile request
					local cid = self.mobileSession5:SendRPC("PutFile",paramsSend, "files/bmp_6kb.bmp")	
					--mobile side: expected PutFile response
					self.mobileSession5:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
					
					:ValidIf (function(_,data)
						app5StoragePath = config.pathToSDL .. GetParamValue("AppStorageFolder").."/" .."5".. "_" .. config.deviceMAC.. "/"
							print(app5StoragePath.."icon.png")
							if file_check(app5StoragePath.."bmp_6kb.bmp") == true then
								print(" \27[36m Can not found file: bmp_6kb.bmp \27[0m ")
								return false
							else 
								return true
							end
						end)
				end	
		
			--Checking files: ListFiles - the list contain icon.png only
				function Test:ListFiles_App5_systemFiletrue()				
					app5StoragePath = config.pathToSDL .. GetParamValue("AppStorageFolder").."/" .."5".. "_" .. config.deviceMAC.. "/"
					local listfileresult = os.execute('ls ' .. app5StoragePath .. ">ResultOfListFile.txt")
					
					--open a file in read mode
					local file = io.open("ResultOfListFile.txt", "r")
					local Files = {}
					i = 1
					while true do
						
						local line = file:read()
						if line == nil then break end
						Files[i] = line
						i = i + 1
						print(line)
					end	
					file:close()
					
					--mobile side: sending ListFiles request
					local cid = self.mobileSession5:SendRPC("ListFiles", {} )					
					--mobile side: expect ListFiles response
					self.mobileSession5:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
					local fileNamesValue = data.payload.filenames
					
						if fileNamesValue == nil  or #fileNamesValue > 1 then
							print(" \27[36m Error: "..fileNamesValue[1].." \27[0m ")
							return false
						else
							
							if(fileNamesValue[1] == "icon.png") then
								print(" \27[36m Response contains only: "..fileNamesValue[1].." \27[0m ")
								return true
							else
								print(" \27[36m Error: "..fileNamesValue[1].." \27[0m ")
								return false
								
							end
						
						end
						
					end)
					
				end

		end
		Task_APPLINK_15934()
		--End test case SequenceCheck.2
		
	--End test suit SequenceCheck	


		
----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	
	-- processing of request/response in different HMIlevels, SystemContext, AudioStreamingState
	
	
	
	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		print("****************************** VII TEST BLOCK: Different HMIStatus ******************************")
	end	

	
	--Begin test suit DifferentHMIlevel
	--Description: processing API in different HMILevel

		--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-811

		--Verification criteria: ListFiles is allowed in FULL, LIMITED, BACKGROUND, NONE
		
		--Verify resultCode in NONE, LIMITED, BACKGROUND HMI level
		commonTestCases:verifyDifferentHMIStatus("SUCCESS", "SUCCESS", "SUCCESS")	

	--End test suit DifferentHMIlevel
	
	--Postcondition: restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()			
		
return Test

