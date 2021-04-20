---------------------------------
-- Author: Anna Rotar
-- Creation date: 26.08.2016
-- ATF version: 2.2

---------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local mobile  = require('mobile_connection')
local json = require("modules/json")
local SDL = require('SDL')
---------------------------------------------------------------------------------------------
--------------------------------Required Shared Libraries------------------------------------
---------------------------------------------------------------------------------------------
require('user_modules/AppTypes')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local utils = require ('user_modules/utils')
---------------------------------------------------------------------------------------------
------------------------------------Common Variables-----------------------------------------
---------------------------------------------------------------------------------------------
--[TODO: shall be removed when APPLINK-16610 is fixed
--Set 2 protocol as default for script:
config.defaultProtocolVersion = 2

local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. tostring(utils.getDeviceMAC()) .. "/")

---------------------------------------------------------------------------------------------
-------------------------------------Common functions-----------------------------------------
---------------------------------------------------------------------------------------------

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

--User output
local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

local function WaitForStopSDL(self)
  local status = SDL:CheckStatusSDL()
  local timer =0
  while status == SDL.RUNNING and timer < 10 do
    sleep(1)
    timer = timer+1
    status = SDL:CheckStatusSDL()
  end
  status = SDL:CheckStatusSDL()
  if status == SDL.RUNNING then
    self:FailTestCase("SDL didn't finish correctly")
    StopSDL()
  else
    userPrint(34, "After correct sdl_preloaded_pt.json restored, SDL stops successfully")
  end
end

--Backup preloaded file
local function BackupPreloaded()
  os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
end

--Restore correct preloaded policy table file
local function RestorePreloadedPT(self)
  os.execute('rm ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
end

---------------------------------------------------------------------------------------------
--------------------------------------Preconditions------------------------------------------
---------------------------------------------------------------------------------------------

--Print new line to seperate Preconditions
commonFunctions:newTestCasesGroup("General Preconditions")

--Verify config.pathToSDL
function Test:VerifyConfigPathToSDL()
    commonSteps:CheckSDLPath()
end

--Delete app_info.dat, logs and policy table
--function Test:DeleteLogsAndPolicyTable()
	--commonSteps:DeleteLogsFiles()
	--commonSteps:DeletePolicyTable()
--end
--Activate application
commonSteps:ActivationApp()
---------------------------------------------------------------------------------------------
---------------------------------------Test cases--------------------------------------------
---------------------------------------------------------------------------------------------
--Start Positive cases check.
	-- Start positive case1.
	--Description: PTU of registered App is performed using correct file.
	--Verification criteria: Policy update is successfull.

	commonFunctions:newTestCasesGroup("TC01_Case when for PTU is used correct file")


	        function Test:PTUSuccessIfPTWithDeviceAndPreDataConsent()

			local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
				{
					fileName = "PolicyTableUpdate",
					requestType = "PROPRIETARY",
					appID = iappID
				},
			"files/ptu_general.json")

			local systemRequestId
			--hmi side: expect SystemRequest request
			EXPECT_HMICALL("BasicCommunication.SystemRequest")
			:Do(function(_,data)
				systemRequestId = data.id
				--print("BasicCommunication.SystemRequest is received")

				--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
				self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
					{
						policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
					}
				)
				function to_run()
					--hmi side: sending SystemRequest response
					self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
				end

				RUN_AFTER(to_run, 500)
			end)

			--hmi side: expect SDL.OnStatusUpdate
			EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
				:ValidIf(function(exp,data)
					if
						exp.occurences == 1 and
						data.params.status == "UP_TO_DATE" then
							return true
					elseif
						exp.occurences == 1 and
						data.params.status == "UPDATE_NEEDED" then
							return true
					elseif
						(exp.occurences == 1 or
						exp.occurences == 2 )and
						data.params.status == "UPDATING" then
							return true
					elseif
						(exp.occurences == 2 or
						exp.occurences == 3) and
						data.params.status == "UP_TO_DATE" then
							return true
					else
						if
							exp.occurences == 1 then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
						elseif exp.occurences == 2 then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
						elseif
							exp.occurences == 3 then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in third occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
						end
						return false
					end
				end)
				:Times(Between(1,3))

			--mobile side: expect SystemRequest response
			EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
			:Do(function(_,data)
				--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
				local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})

				--hmi side: expect SDL.GetUserFriendlyMessage response
				EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{messageCode = "StatusUpToDate"}}}})
			end)

		end
	-- End Positive case1.
--End Positive cases check.


--Start Negative cases check.
-------------------------------------------------------------------------------------------------------

--"Device" and "pre_DataConsent" sections are omitted in PTU file.

-------------------------------------------------------------------------------------------------------
	-- Start Negative case1.
	--Description:SDL starts with valid preloaded_pt. PTU of registered App is performed with omitted "device" section.
	--Verification criteria: SDL fails validation of PTU file,  policy update is not successfull.

    commonFunctions:newTestCasesGroup("TC02_Case when in PTU file device section omitted:")

	    function Test:PTUFailNoDeviceSection()

					local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
						{
							fileName = "PolicyTableUpdate",
							requestType = "PROPRIETARY",
							appID = iappID
						},
					"files/PTU_DeviceSectionMissed.json")

					local systemRequestId
					--hmi side: expect SystemRequest request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						systemRequestId = data.id

						--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
						self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
							{
								policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
							}
						)
						function to_run()
							--hmi side: sending SystemRequest response
							self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
						end

						RUN_AFTER(to_run, 500)
					end)

					--hmi side: expect SDL.OnStatusUpdate
					EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
					:ValidIf(function(exp,data)
							if
								exp.occurences == 1 and
								data.params.status == "UPDATE_NEEDED" then
									print ("\27[31m SDL.OnStatusUpdate came with wrong values. PTU file validation failed. Exchange wasn't successful")
									return true
							elseif
								exp.occurences == 1 and
								data.params.status == "UP_TO_DATE" then
								    print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in first occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
									return false
							elseif
								exp.occurences == 2 and
								data.params.status == "UPDATING" then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in second occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
									return false
							end

						end)
						:Times(Between(1,2))

					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
					:Times(0)

	    end
	-- End Negative case1.

-------------------------------------------
	-- Start Negative case2.
	--Description:SDL starts with valid preloaded_pt. PTU of registered App is performed with incorrect "device" section - uppercase.
	--Verification criteria: SDL fails validation of PTU file,  policy update is not successfull.

    commonFunctions:newTestCasesGroup("TC03_Case when in PTU file device section incorrect:")

	    function Test:PTUFailDeviceIncorrect()

					local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
						{
							fileName = "PolicyTableUpdate",
							requestType = "PROPRIETARY",
							appID = iappID
						},
					"files/PTU_DeviceSectionUppercase.json")

					local systemRequestId
					--hmi side: expect SystemRequest request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						systemRequestId = data.id

						--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
						self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
							{
								policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
							}
						)
						function to_run()
							--hmi side: sending SystemRequest response
							self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
						end

						RUN_AFTER(to_run, 500)
					end)

					--hmi side: expect SDL.OnStatusUpdate
					EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
					:ValidIf(function(exp,data)
							if
								exp.occurences == 1 and
								data.params.status == "UPDATE_NEEDED" then
									print ("\27[31m SDL.OnStatusUpdate came with wrong values. PTU file validation failed. Exchange wasn't successful")
									return true
							elseif
								exp.occurences == 1 and
								data.params.status == "UP_TO_DATE" then
								    print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in first occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
									return false
							elseif
								exp.occurences == 2 and
								data.params.status == "UPDATING" then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in second occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
									return false
							end

						end)
						:Times(Between(1,2))

					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
					:Times(0)

	    end
	-- End Negative case2.

-------------------------------------------
	-- Start Negative case3.
	--Description:SDL starts with valid preloaded_pt. PTU of registered app is performed with omitted "pre_DataConsent" section.
	--Verification criteria: SDL fails validation of PTU file,  policy update is not successfull.

    commonFunctions:newTestCasesGroup("TC04_Case when in PTU file pre_DataConsent section omitted:")

	     function Test:PTUFailNoPredataSection()

					local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
						{
							fileName = "PolicyTableUpdate",
							requestType = "PROPRIETARY",
							appID = iappID
						},
					"files/PTU_PreDataConsentMissed.json")

					local systemRequestId
					--hmi side: expect SystemRequest request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						systemRequestId = data.id

						--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
						self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
							{
								policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
							}
						)
						function to_run()
							--hmi side: sending SystemRequest response
							self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
						end

						RUN_AFTER(to_run, 500)
					end)

					--hmi side: expect SDL.OnStatusUpdate
					EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
					:ValidIf(function(exp,data)
							if
								exp.occurences == 1 and
								data.params.status == "UPDATE_NEEDED" then
									print ("\27[31m SDL.OnStatusUpdate came with wrong values. PTU file validation failed. Exchange wasn't successful")
									return true
							elseif
								exp.occurences == 1 and
								data.params.status == "UP_TO_DATE" then
								    print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in first occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
									return false
							elseif
								exp.occurences == 2 and
								data.params.status == "UPDATING" then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in second occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
									return false
							end

						end)
						:Times(Between(1,2))

					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
					:Times(0)

	     end
	-- End Negative case3.

-------------------------------------------

	-- Start Negative case4.
	--Description:SDL starts with valid preloaded_pt. PTU of registered App is performed with incorrect "pre_DataConsent" section - uppercase.
	--Verification criteria: SDL fails validation of PTU file,  policy update is not successfull.

    commonFunctions:newTestCasesGroup("TC05_Case when in PTU file pre_DataConsent section incorrect:")

	    function Test:PTUFailPreDataIncorrect()

					local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
						{
							fileName = "PolicyTableUpdate",
							requestType = "PROPRIETARY",
							appID = iappID
						},
					"files/PTU_PreDataSectionUppercase.json")

					local systemRequestId
					--hmi side: expect SystemRequest request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						systemRequestId = data.id

						--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
						self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
							{
								policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
							}
						)
						function to_run()
							--hmi side: sending SystemRequest response
							self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
						end

						RUN_AFTER(to_run, 500)
					end)

					--hmi side: expect SDL.OnStatusUpdate
					EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
					:ValidIf(function(exp,data)
							if
								exp.occurences == 1 and
								data.params.status == "UPDATE_NEEDED" then
									print ("\27[31m SDL.OnStatusUpdate came with wrong values. PTU file validation failed. Exchange wasn't successful")
									return true
							elseif
								exp.occurences == 1 and
								data.params.status == "UP_TO_DATE" then
								    print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in first occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
									return false
							elseif
								exp.occurences == 2 and
								data.params.status == "UPDATING" then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in second occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
									return false
							end

						end)
						:Times(Between(1,2))

					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
					:Times(0)

	    end
	-- End Negative case4.

-------------------------------------------
	-- Start Negative case5.
	--Description:SDL starts with valid preloaded_pt. PTU of registered app is performed with omitted "device" and "pre_DataConsent" sections.
	--Verification criteria: SDL fails validation of PTU file,  policy update is not successfull.

    commonFunctions:newTestCasesGroup("TC06_Case when in PTU file device and pre_DataConsent sections omitted:")

 	function Test:PTUFailNoPredataAndDeviceSections()

				local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
					{
						fileName = "PolicyTableUpdate",
						requestType = "PROPRIETARY",
						appID = iappID
					},
				"files/PTU_DeviceAndPreDataMissed.json")

				local systemRequestId
				--hmi side: expect SystemRequest request
				EXPECT_HMICALL("BasicCommunication.SystemRequest")
				:Do(function(_,data)
					systemRequestId = data.id

					--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
					self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
						{
							policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
						}
					)
					function to_run()
						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
					end

					RUN_AFTER(to_run, 500)
				end)

				--hmi side: expect SDL.OnStatusUpdate
				EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
				:ValidIf(function(exp,data)
						if
							exp.occurences == 1 and
							data.params.status == "UPDATE_NEEDED" then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. PTU file validation failed. Exchange wasn't successful")
								return true
						elseif
							exp.occurences == 1 and
							data.params.status == "UP_TO_DATE" then
							    print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in first occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
								return false
						elseif
							exp.occurences == 2 and
							data.params.status == "UPDATING" then
							print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in second occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
								return false
						end

					end)
					:Times(Between(1,2))

				--mobile side: expect SystemRequest response
				EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
				:Times(0)

     end
	-- End Negative case5.

-------------------------------------------
	-- Start Negative case6.
	--Description:SDL starts with valid preloaded_pt. PTU of registered App is performed with incorrect "device" and "pre_DataConsent" sections - uppercase.
	--Verification criteria: SDL fails validation of PTU file,  policy update is not successfull.

    commonFunctions:newTestCasesGroup("TC07_Case when in PTU device & pre_DataConsent sections incorrect:")

	    function Test:PTUFailDeviceAndPreDataIncorrect()

					local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
						{
							fileName = "PolicyTableUpdate",
							requestType = "PROPRIETARY",
							appID = iappID
						},
					"files/PTU_DeviceAndPreDataUppercase.json")

					local systemRequestId
					--hmi side: expect SystemRequest request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						systemRequestId = data.id

						--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
						self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
							{
								policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
							}
						)
						function to_run()
							--hmi side: sending SystemRequest response
							self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
						end

						RUN_AFTER(to_run, 500)
					end)

					--hmi side: expect SDL.OnStatusUpdate
					EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
					:ValidIf(function(exp,data)
							if
								exp.occurences == 1 and
								data.params.status == "UPDATE_NEEDED" then
									print ("\27[31m SDL.OnStatusUpdate came with wrong values. PTU file validation failed. Exchange wasn't successful")
									return true
							elseif
								exp.occurences == 1 and
								data.params.status == "UP_TO_DATE" then
								    print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in first occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
									return false
							elseif
								exp.occurences == 2 and
								data.params.status == "UPDATING" then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in second occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
									return false
							end

						end)
						:Times(Between(1,2))

					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
					:Times(0)

	    end
	-- End Negative case6.

------------------------------------------------------------------------------------------------------

--"Device" and "pre_DataConsent" section are omitted in sdl_preloaded_pt.json file.

------------------------------------------------------------------------------------------------------
	-- Start Negative case7.
		--Description: Mandatory section "device" is omitted in preloaded_pt
		--Verification criteria: SDL checks preloaded_PT on start, finds out that it is invalid and stops working

		commonFunctions:newTestCasesGroup("TC08_Case when mandatory section device is omitted in preloaded_pt:")

			function Test:PreconditionIgnitionOff()
			    StopSDL()
			end

			function Test:BackupPreloadedPt()
				BackupPreloaded()
			end

			function Test:RemoveDeviceFromPreloadedJson()
			    pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
			    local file  = io.open(pathToFile, "r")
			    local json_data = file:read("*all") -- may be abbreviated to "*a";
			    file:close()

			    local json = require("modules/json")

			    local data = json.decode(json_data)
			    if data.policy_table.app_policies and
			   	    data.policy_table.app_policies["device"] ~= nil then
			   		data.policy_table.app_policies["device"] = nil
			    end

			    data = json.encode(data)

			    file = io.open(pathToFile, "w")
			    file:write(data)
			    file:close()
			end

			function Test:IgnitionOnWithEditedPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
				userPrint(34, "After IGNON SDL stops since preloaded not valid(see above message)")
				WaitForStopSDL(self)
			end

		--Start Postcondition to case7.
		commonFunctions:newTestCasesGroup("TC08_Postconditions")

		    	function Test:RestorePreloadedJson()
		  		RestorePreloadedPT()
		   	end



			function Test:StartSDLWithDeviceInPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
  				userPrint(34, "After correct sdl_preloaded_pt.json restored, SDL starts successfully")
			end
		--end Postcondition to case7.

	-- End Negative case7.

	-------------------------------------------------------------
	-- Start Negative case8.
		--Description: Mandatory section "device" is wrong in preloaded_pt
		--Verification criteria: SDL checks preloaded_PT on start, finds out that it is invalid and stops working

		commonFunctions:newTestCasesGroup("TC09_Case when mandatory section device is incorrect in preloaded_pt:")

			function Test:PreconditionIgnitionOff()
			    StopSDL()
			end

			function Test:BackupPreloadedPtFile()
				BackupPreloaded()
			end

			function Test:ChangeDeviceSectionInPreloaded()
			    pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
			    local file  = io.open(pathToFile, "r")
			    local json_data = file:read("*all") -- may be abbreviated to "*a";
			    file:close()

			    local json = require("modules/json")

			    local data = json.decode(json_data)
			    if data.policy_table.app_policies and
			   	    data.policy_table.app_policies["device"] ~= nil then
			   		data.policy_table.app_policies["device"] = data.policy_table.app_policies["Device"]
			    end

			    data = json.encode(data)

			    file = io.open(pathToFile, "w")
			    file:write(data)
			    file:close()
			end

			function Test:IgnitionOnWithEditedPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
				userPrint(34, "After IGNON SDL stops since preloaded not valid(see above message)")
				WaitForStopSDL(self)
			end

		--Start Postcondition to case8.
		commonFunctions:newTestCasesGroup("TC09_Postconditions")

		  	function Test:RestorePreloadedJson()
		  		RestorePreloadedPT()
		   	end

			function Test:StartSDLWithDeviceInPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
  				userPrint(34, "After correct sdl_preloaded_pt.json restored, SDL starts successfully")
			end
		--end Postcondition to case8.
	-- End Negative case8.

	-------------------------------------------------------------

	-- Start Negative case9.
		--Description: Mandatory section "pre_DataConsent" is not present in preloaded_pt
		--Verification criteria: SDL checks preloaded_PT on start, finds out that it is invalid and stops working

		commonFunctions:newTestCasesGroup("TC10_Case when mandatory section pre_DataConsent is omitted in preloaded_pt:")

			function Test:PreconditionIgnitionOff()
				StopSDL()
			end

			function Test:BackupPreloadedPtFile()
				BackupPreloaded()
			end

			function Test:RemovePreDataConsentFromPreloadedJson()
			    pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
			    local file  = io.open(pathToFile, "r")
			    local json_data = file:read("*all") -- may be abbreviated to "*a";
			    file:close()

			    local json = require("modules/json")

			    local data = json.decode(json_data)
			   	if data.policy_table.app_policies and
			   		data.policy_table.app_policies["pre_DataConsent"] ~= nil then
			   		data.policy_table.app_policies["pre_DataConsent"] = nil

			    end

			    data = json.encode(data)

			    file = io.open(pathToFile, "w")
			    file:write(data)
			    file:close()
			 end

			function Test:IgnitionOnWithEditedPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
				userPrint(34, "After IGNON SDL stops since preloaded not valid(see above message)")
				WaitForStopSDL(self)
			end

		--Start Postcondition to case9.
		commonFunctions:newTestCasesGroup("TC10_Postconditions")
			function Test:RestorePreloadedJson()
		  		RestorePreloadedPT()
		    	end

			function Test:StartSDLWithPreDataInPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
  				userPrint(34, "After correct sdl_preloaded_pt.json restored, SDL starts successfully")
			end
		--end Postcondition to case9.
	-- End Negative case9.

	-------------------------------------------------------------
	-- Start Negative case10.
		--Description: Mandatory section "device" is wrong in preloaded_pt
		--Verification criteria: SDL checks preloaded_PT on start, finds out that it is invalid and stops working

		commonFunctions:newTestCasesGroup("TC11_Case when mandatory section pre_DataConsent is incorrect in preloaded_pt:")

			function Test:PreconditionIgnitionOff()
			    StopSDL()
			end

			function Test:BackupPreloadedPtFile()
				BackupPreloaded()
			end

			function Test:ChangePreDataSectionInPreloaded()
			    pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
			    local file  = io.open(pathToFile, "r")
			    local json_data = file:read("*all") -- may be abbreviated to "*a";
			    file:close()

			    local json = require("modules/json")

			    local data = json.decode(json_data)
			    if data.policy_table.app_policies and
			   	    data.policy_table.app_policies["pre_DataConsent"] ~= nil then
			   		data.policy_table.app_policies["pre_DataConsent"] = data.policy_table.app_policies["Pre_DataConsent"]
			    end

			    data = json.encode(data)

			    file = io.open(pathToFile, "w")
			    file:write(data)
			    file:close()
			end

			function Test:IgnitionOnWithEditedPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
				userPrint(34, "After IGNON SDL stops since preloaded not valid(see above message)")
				WaitForStopSDL(self)
			end

		--Start Postcondition to case10.
		commonFunctions:newTestCasesGroup("TC11_Postconditions")
		    	function Test:RestorePreloadedJson()
		  		RestorePreloadedPT()
		   	end

			function Test:StartSDLWithDeviceInPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
  				userPrint(34, "After correct sdl_preloaded_pt.json restored, SDL starts successfully")
			end
		--end Postcondition to case10.
	-- End Negative case10.

	-------------------------------------------------------------

	-- Start Negative case11.
		--Description: Both mandatory sections "device" and "pre_DataConsent" are omitted in preloaded_pt
		--Verification criteria: SDL checks preloaded_PT on start, finds out that it is invalid and stops working

		commonFunctions:newTestCasesGroup("TC12_Case when both sections device and pre_DataConsent are omitted in preloaded_pt:")

			function Test:PreconditionIgnitionOff()
				StopSDL()
			end

			function Test:BackupPreloadedPtFile()
				BackupPreloaded()
			end

			function Test:RemoveDeviceAndPreDataFromPreloaded()
			    pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
			    local file  = io.open(pathToFile, "r")
			    local json_data = file:read("*all") -- may be abbreviated to "*a";
			    file:close()

			    local json = require("modules/json")

			    local data = json.decode(json_data)
			   		if data.policy_table.app_policies and
				   		data.policy_table.app_policies["pre_DataConsent"] ~= nil and data.policy_table.app_policies["device"] ~= nil then
				   		data.policy_table.app_policies["device"] = nil
				   		data.policy_table.app_policies["pre_DataConsent"] = nil
				end

			    data = json.encode(data)

			    file = io.open(pathToFile, "w")
			    file:write(data)
			    file:close()
			end

			function Test:IgnitionOnWithEditedPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
				userPrint(34, "After IGNON SDL stops since preloaded not valid(see above message)")
				WaitForStopSDL(self)
			end

		--Start Postcondition to case11.
		commonFunctions:newTestCasesGroup("TC12_Postconditions")
			function Test:RestorePreloadedJson()
		  		RestorePreloadedPT()
		  	end

			function Test:StartSDLWithDeviceAndPreDataInPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
  				userPrint(34, "After correct sdl_preloaded_pt.json restored, SDL starts successfully")
			end
		--end Postcondition to case11.
	-- End Negative case11.

	-------------------------------------------------------------
	-- Start Negative case12.
		--Description: Mandatory section "device" is wrong in preloaded_pt
		--Verification criteria: SDL checks preloaded_PT on start, finds out that it is invalid and stops working

		commonFunctions:newTestCasesGroup("TC13_Case when mandatory device and pre_DataConsent are incorrect in preloaded_pt:")

			function Test:PreconditionIgnitionOff()
			    StopSDL()
			end

			function Test:BackupPreloadedPtFile()
				BackupPreloaded()
			end

			function Test:ChangePreDataAndDeviceInPreloaded()
			    pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
			    local file  = io.open(pathToFile, "r")
			    local json_data = file:read("*all") -- may be abbreviated to "*a";
			    file:close()

			    local json = require("modules/json")

			    local data = json.decode(json_data)
			    if data.policy_table.app_policies and
			   	    data.policy_table.app_policies["pre_DataConsent"] ~= nil and data.policy_table.app_policies["device"] ~= nil then
			   		data.policy_table.app_policies["pre_DataConsent"] = data.policy_table.app_policies["Pre_DataConsent"]
			   		data.policy_table.app_policies["device"] = data.policy_table.app_policies["Device"]

			    end

			    data = json.encode(data)

			    file = io.open(pathToFile, "w")
			    file:write(data)
			    file:close()
			end

			function Test:IgnitionOnWithEditedPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
				userPrint(34, "After IGNON SDL stops since preloaded not valid(see above message)")
				WaitForStopSDL(self)
			end

		--Start Postcondition to case12.
		commonFunctions:newTestCasesGroup("TC13_Postconditions")
		  	function Test:RestorePreloadedJson()
		  		RestorePreloadedPT()
		 	end

			function Test:StartSDLWithDeviceInPT()
				StartSDL(config.pathToSDL, config.ExitOnCrash)
  				userPrint(34, "After correct sdl_preloaded_pt.json restored, SDL starts successfully")
			end
		--end Postcondition to case12.
	-- End Negative case12.
--End Negative cases check.

return Test
