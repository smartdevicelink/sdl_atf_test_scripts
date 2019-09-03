--This script contains common functions that are used in many script.
--How to use:
	--1. local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
	--2. testCasesForPolicyTable:createPolicyTableWithoutAPI()
---------------------------------------------------------------------------------------------

local testCasesForPolicyTable = {}
local mobile_session = require('mobile_session')
local commonFunctions = require('user_modules/shared_testcases_custom/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases_custom/commonPreconditions')
local commonSteps = require('user_modules/shared_testcases_custom/commonSteps')


--Policy template
local PolicyTableTemplate = "user_modules/shared_testcases/PolicyTables/DefaultPolicyTableWith_group1.json"

local PolicyTableTemplate2 = "user_modules/shared_testcases/PolicyTables/DefaultPolicyTableWith_group1_2.json"

--New policy table
local PolicyTable = "user_modules/shared_testcases/PolicyTables/TestingPolicyTable.json"

local APINameKeyWord = "APIName"
local appID = "0000001"
local defaultFunctionGroupName = "group1"

---------------------------------------------------------------------------------------------
------------------------------------------ Functions ----------------------------------------
---------------------------------------------------------------------------------------------
--List of group functions:
--1. createPolicyTableWithoutAPI
--2. createPolicyTable
--2b. createPolicyTableFile
--3. updatePolicy
--4. userConsent
--5. updatePolicyAndAllowFunctionGroup
---------------------------------------------------------------------------------------------


--Create new policy table from a template without APIName
function testCasesForPolicyTable:createPolicyTableWithoutAPI(APIName)


	--New policy table with API
	local PolicyTable = "user_modules/shared_testcases/PolicyTables/TestingPolicyTable192837465.json"


	-- Opens a file in read mode
	local file = io.open(PolicyTableTemplate, "r")

	-- Opens a file in write mode
	local file2 = io.open(PolicyTable, "w")

	--Rename API if it is exist
	while true do

		local line = file:read()
		if line == nil then break end

		if string.find(line, APIName) ~= nil then
			--rename API name if it is esist in template policy table
			line  =  string.gsub(line, APIName, APIName .. "1")
		end

		--Write line to new policy table
		file2:write(line)
	end

	file:close()
	file2:close()

	return PolicyTable

end

--Create new policy table from a template with API name and Hmi levels
function testCasesForPolicyTable:createPolicyTable(APIName, HmiLevels, keep_context, steal_focus, functionGroupName)

	if keep_context == nil then
		keep_context = false
	end
	if steal_focus == nil then
		steal_focus = false
	end

	if functionGroupName == nil then
		functionGroupName = defaultFunctionGroupName
	end


	local testCaseName = "CreatePolicyTable_AllowHmiLevels"
	for i = 1, #HmiLevels do
		testCaseName = testCaseName .. "_" .. HmiLevels[i]
	end

	testCaseName = testCaseName .. "_" .. "keep_context_is" .. tostring(keep_context) ..  "_steal_focus_is" .. tostring(steal_focus)

	Test[testCaseName] = function(self)


		-- Opens a file in read mode
		local file = io.open(PolicyTableTemplate, "r")

		-- Opens a file in write mode
		local file2 = io.open(PolicyTable, "w")

		--Read policy table template and create new policy table with API name and HMI Levels
		while true do

			local line = file:read()
			if line == nil then break end

			line  =  string.gsub(line, defaultFunctionGroupName, functionGroupName)

			if string.find(line, APINameKeyWord) == nil then
				--rename API name if it is exist in template policy table
				line  =  string.gsub(line, APIName, APIName .. "1")

				--Write line to new policy table
				file2:write(line)

				if string.find(line, appID) ~= nil then
					--update keep_context and steal_focus
					line = "\t\t\t\t\"keep_context\" : " .. tostring(keep_context).. ",\n"
					file:read()
					file2:write(line)
					line = "\t\t\t\t\"steal_focus\" : " .. tostring(steal_focus).. ",\n"
					file:read()
					file2:write(line)


				end

			else

				--Update API name
				line  =  string.gsub(line, APINameKeyWord, APIName)
				file2:write(line)

				--Copy next line
				line = file:read()
				file2:write(line)

				--skip a next line (HMI Level)
				line = file:read()

				--Write HMI LEVELS
				if #HmiLevels >= 1 then
					for i = 1, #HmiLevels - 1 do
						line  =  "\t\t\t\t\t\t\t\"" .. HmiLevels[i] .. "\",\n"
						file2:write(line)
					end
					line  =  "\t\t\t\t\t\t\t\"" .. HmiLevels[#HmiLevels] .. "\"]\n"
					file2:write(line)
				else
					print("Error: HmiLevels should not be empty")
					break
				end

			end
		end

		file:close()
		file2:close()

		return true

	end

	return PolicyTable
end

--Use for adding permission for Base-4, group1, application (new function)
function testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, RenameAPIs)

	if RenameAPIs == nil then
		RenameAPIs = {}
	end

	local TestCaseName = "CreatePolicyTable"
	if PermissionLinesForBase4 ~= nil then TestCaseName = TestCaseName .. "_Add_APIs_To_Base4_Group" end
	if PermissionLinesForGroup1 ~= nil then TestCaseName = TestCaseName .. "_Add_APIs_To_group1_Group" end
	if PermissionLinesForApplication ~= nil then TestCaseName = TestCaseName .. "_Assign_Groups_To_App" end

	Test[TestCaseName] = function(self)

		-- Opens a file in read mode
		local file = io.open(PolicyTableTemplate2, "r")

		-- Opens a file in write mode
		local file2 = io.open(PolicyTable, "w")


		--1. Create PT with permission for group1 group
		if PermissionLinesForGroup1 ~= nil then
			while true do
				--look for '"user_consent_prompt" : "group1",' keyword and add permission for group1 group
				local keyword = '"user_consent_prompt" : "group1",'
				local line = file:read()
				if line == nil then break end

				--Write to new PT
				file2:write(line)

				if string.find(line, keyword) ~= nil then
					--Copy next line to new policy table
					line = file:read()  --"rpcs" : {
					file2:write(line)

					--ignore next 4 lines
					line = file:read()
					line = file:read()
					line = file:read()
					line = file:read()

					--Add new APIs to new policy table
					file2:write(PermissionLinesForGroup1)
					break
				end
			end
		end

		--2. Create PT with permission for Base-4 group
		if PermissionLinesForBase4 ~= nil then
			--look for Base keyword and add permission for Base-4 group
			local keyword = '"Base'
			while true do
				local line = file:read()
				if line == nil then break end

				--Write to new PT
				file2:write(line)

				if string.find(line, keyword) ~= nil then
					--Copy next line to new policy table
					line = file:read()  --"rpcs" : {
					file2:write(line)

					--Add new APIs to new policy table
					file2:write(PermissionLinesForBase4)
					break
				end
			end
		end

		--3. Create PT with permission for application
		if PermissionLinesForApplication ~= nil then
			--look for '"user_consent_prompt" : "group1",' keyword and add permission for group1 group
			local keyword = '"app_policies" : {'
			while true do

				local line = file:read()
				if line == nil then break end

				for j = 1, #RenameAPIs do
					if string.find(line, RenameAPIs[j]) ~= nil then
						--rename API name if it is esist in template policy table
						line  =  string.gsub(line, RenameAPIs[j], RenameAPIs[j] .. "_1")
					end
				end

				--Write to new PT
				file2:write(line)

				if string.find(line, keyword) ~= nil then

					--Add new APIs to new policy table
					file2:write(PermissionLinesForApplication)
					break
				end
			end
		end


		--4. Copy to the end of file
		while true do
			local line = file:read()
			if line == nil then break end

			for j = 1, #RenameAPIs do
				if string.find(line, RenameAPIs[j]) ~= nil then
					--rename API name if it is esist in template policy table
					line  =  string.gsub(line, RenameAPIs[j], RenameAPIs[j] .. "_1")
				end
			end


			--Write to new PT
			file2:write(line)
		end

		file:close()
		file2:close()
		return true
	end

	return PolicyTable

end

--Precondition: update policy with specified policy file, policy group name and return groupID of consent group.
function testCasesForPolicyTable:updatePolicy(PTName, iappID, TestName)

	if (TestName == nil) then
		TestName = "UpdatePolicy"
	end
	Test[TestName] = function(self)

		if not iappID then
			iappID = self.applications[config.application1.registerAppInterfaceParams.appName]
		end

		--hmi side: sending SDL.GetPolicyConfigurationData request
		local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })

		--hmi side: expect SDL.GetPolicyConfigurationData response from HMI
		EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetPolicyConfigurationData"}})
		:Do(function(_,data)
			--print("SDL.GetPolicyConfigurationData response is received")
			--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
				{
					requestType = "PROPRIETARY",
					fileName = "filename"
				}
			)
			--mobile side: expect OnSystemRequest notification
			EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
			:Do(function(_,data)
				--print("OnSystemRequest notification is received")
				--mobile side: sending SystemRequest request
				local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
					{
						fileName = "PolicyTableUpdate",
						requestType = "PROPRIETARY",
						appID = iappID
					},
				PTName)

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
							data.params.status == "UPDATING" then
								return true
						elseif
							exp.occurences == 2 and
							data.params.status == "UP_TO_DATE" then
								return true
						else
							if
								exp.occurences == 1 then
									print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
							elseif exp.occurences == 2 then
									print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
							end
							return false
						end
					end)
					:Times(Between(1,2))

				--mobile side: expect SystemRequest response
				EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
				:Do(function(_,data)
					--print("SystemRequest is received")
					--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
					local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})

					--hmi side: expect SDL.GetUserFriendlyMessage response
					EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
				end)

			end)
		end)


	end

end

--Precondition: update policy with specified policy file on Genivi
function testCasesForPolicyTable:updatePolicyGenivi(self, PTName, iappID)

	-- Test["UpdatePolicy"] = function(self)

		if not iappID then
			iappID = self.applications[config.application1.registerAppInterfaceParams.appName]
		end

		--print("OnSystemRequest notification is received")
		--mobile side: sending SystemRequest request
		local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
			{
				fileName = "PolicyTableUpdate",
				requestType = "PROPRIETARY",
				appID = iappID
			},
		PTName)

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
			--print("SystemRequest is received")
			--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
			local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})

			--hmi side: expect SDL.GetUserFriendlyMessage response
			EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
		end)

	-- end

end

--User allowed or disallowed group policy
function testCasesForPolicyTable:userConsent(IsConsent, functionGroupName, TestName)

	if (TestName == nil) then
		TestName = "UserConsent_".. tostring(IsConsent)
	end


	--Test["UserConsent_".. tostring(IsConsent)] = function(self)
	Test[TestName] = function(self)


		if functionGroupName == nil then
			functionGroupName = defaultFunctionGroupName
		end

		--Get GetListOfPermissions
		--hmi side: sending SDL.GetListOfPermissions request to SDL
		local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})


		-- hmi side: expect SDL.GetListOfPermissions response
		--EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{name = functionGroupName}}}})
		EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions)
			:Do(function(_,data)

					--Get groupID
					local groupID
					for i = 1, #data.result.allowedFunctions do
						if data.result.allowedFunctions[i].name == functionGroupName then
							groupID = data.result.allowedFunctions[i].id
							break
						end

					end

					if groupID == nil then
						commonFunctions:printError("Error: userConsent function: function group name is not exist")
					end


					--hmi side: sending SDL.OnAppPermissionConsent
					self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = IsConsent, id = groupID, name = functionGroupName}}, source = "GUI"})

					--EXPECT_NOTIFICATION("OnPermissionsChange", {})
			end)


	end
end

--Print user consent group in policy table
function testCasesForPolicyTable:printUserConsent()


	Test["PrintUserConsent"] = function(self)

		local groupName = "group1"

		--Get GetListOfPermissions
		--hmi side: sending SDL.GetListOfPermissions request to SDL
		local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})


		-- hmi side: expect SDL.GetListOfPermissions response
		EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{name = groupName}}}})

	end
end


--Verify DISALLOWED resultCode when API is not assigned to app
function testCasesForPolicyTable:checkPolicyWhenAPIIsNotExist()

	--Precondition: Build policy table file
	local PTName = testCasesForPolicyTable:createPolicyTableWithoutAPI(APIName)

	--Precondition: Update policy table
	testCasesForPolicyTable:updatePolicy(PTName)

	--Send request and check DISALLOWED resultCode
	Test[APIName .."_resultCode_DISALLOWED"] = function(self)

		--mobile side: sending the request
		local RequestParams = self.createRequest()
		local cid = self.mobileSession:SendRPC(APIName, RequestParams)

		--mobile side: expect response
		self.mobileSession:ExpectResponse(cid, {  success = false, resultCode = "DISALLOWED"})

	end


end


--Verify DISALLOWED resultCode when API is assigned to app but the group has not yet received user's consents.
--Verify USER_DISALLOWED resultCode
function testCasesForPolicyTable:checkPolicyWhenUserDisallowed(HmiLevels, keep_context, steal_focus)


	--Case 1: Verify DISALLOWED resultCode when API is assigned to app but the group has not yet received user's consents.


	--Precondition: Build policy table file
	local PTName = testCasesForPolicyTable:createPolicyTable(APIName, HmiLevels, keep_context, steal_focus)

	--Precondition: Update policy table
	testCasesForPolicyTable:updatePolicy(PTName)

	--Send request and check DISALLOWED resultCode
	Test[APIName .."_resultCode_DISALLOWED"] = function(self)

		--mobile side: sending the request
		local RequestParams = self.createRequest()
		local cid = self.mobileSession:SendRPC(APIName, RequestParams)

		--mobile side: expect response
		self.mobileSession:ExpectResponse(cid, {  success = false, resultCode = "DISALLOWED"})

	end


	--Case 2: Verify USER_DISALLOWED resultCode

	--Precondition: User does not allow function group
	testCasesForPolicyTable:userConsent(false)

	--Send request and check USER_DISALLOWED resultCode
	Test[APIName .."_resultCode_USER_DISALLOWED"] = function(self)
		--mobile side: sending the request
		local Request = self.createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		--mobile side: expect response
		self.mobileSession:ExpectResponse(cid, {  success = false, resultCode = "USER_DISALLOWED"})
	end

	--Postcondition: User allows function group
	testCasesForPolicyTable:userConsent(true)
end

--Update policy and user consent
function testCasesForPolicyTable:updatePolicyAndAllowFunctionGroup(HmiLevels, keep_context, steal_focus, consentGroup)

	if consentGroup == nil then
		consentGroup = defaultFunctionGroupName
	end

	--Precondition: Build policy table file
	local PTName = testCasesForPolicyTable:createPolicyTable(APIName, HmiLevels, keep_context, steal_focus, consentGroup)

	--Precondition: Update policy table
	testCasesForPolicyTable:updatePolicy(PTName)

	--Postcondition: User allows function group
	testCasesForPolicyTable:userConsent(true, consentGroup)
end

--Update PT for precondition of each test case.
function testCasesForPolicyTable:precondition_updatePolicyAndAllowFunctionGroup(HmiLevels, keep_context, steal_focus)

	local consentGroupName = "group_precondition"

	testCasesForPolicyTable:updatePolicyAndAllowFunctionGroup(HmiLevels, keep_context, steal_focus, consentGroupName)

end

--testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})
function testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves(HmiLevels)

	local temp = "\"" .. HmiLevels[1] .. "\""

	for i=2, #HmiLevels do
		temp = temp .. "," .. "\"" .. HmiLevels[i] .. "\""
	end

	local PermissionLines = "\""..APIName.. "\": { \"hmi_levels\": [" .. temp .. "]}"

	local PermissionLinesForBase4 = PermissionLines .. ",\n"
	local PermissionLinesForGroup1 = nil
	local PermissionLinesForApplication = nil
	local PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {APIName})
	testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)

end

function testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, RenameAPIs)

	if RenameAPIs == nil then
		RenameAPIs = {}
	end

	local TestCaseName = "CreatePolicyTable"
	if PermissionLinesForBase4 ~= nil then TestCaseName = TestCaseName .. "_Add_APIs_To_Base4_Group" end
	if PermissionLinesForGroup1 ~= nil then TestCaseName = TestCaseName .. "_Add_APIs_To_group1_Group" end
	if PermissionLinesForApplication ~= nil then TestCaseName = TestCaseName .. "_Assign_Groups_To_App" end

--	Test[TestCaseName] = function(self)

		-- Opens a file in read mode
		local file = io.open(PolicyTableTemplate2, "r")

		-- Opens a file in write mode
		local file2 = io.open(PolicyTable, "w")


		--1. Create PT with permission for group1 group
		if PermissionLinesForGroup1 ~= nil then
			while true do
				--look for '"user_consent_prompt" : "group1",' keyword and add permission for group1 group
				local keyword = '"user_consent_prompt" : "group1",'
				local line = file:read()
				if line == nil then break end

				--Write to new PT
				file2:write(line)

				if string.find(line, keyword) ~= nil then
					--Copy next line to new policy table
					line = file:read()  --"rpcs" : {
					file2:write(line)

					--ignore next 4 lines
					line = file:read()
					line = file:read()
					line = file:read()
					line = file:read()

					--Add new APIs to new policy table
					file2:write(PermissionLinesForGroup1)
					break
				end
			end
		end

		--2. Create PT with permission for Base-4 group
		if PermissionLinesForBase4 ~= nil then
			--look for Base keyword and add permission for Base-4 group
			local keyword = '"Base'
			while true do
				local line = file:read()
				if line == nil then break end

				--Write to new PT
				file2:write(line)

				if string.find(line, keyword) ~= nil then
					--Copy next line to new policy table
					line = file:read()  --"rpcs" : {
					file2:write(line)

					--Add new APIs to new policy table
					file2:write(PermissionLinesForBase4)
					break
				end
			end
		end

		--3. Create PT with permission for application
		if PermissionLinesForApplication ~= nil then
			--look for '"user_consent_prompt" : "group1",' keyword and add permission for group1 group
			local keyword = '"app_policies" : {'
			while true do

				local line = file:read()
				if line == nil then break end

				for j = 1, #RenameAPIs do
					if string.find(line, RenameAPIs[j]) ~= nil then
						--rename API name if it is esist in template policy table
						line  =  string.gsub(line, RenameAPIs[j], RenameAPIs[j] .. "_1")
					end
				end

				--Write to new PT
				file2:write(line)

				if string.find(line, keyword) ~= nil then

					--Add new APIs to new policy table
					file2:write(PermissionLinesForApplication)
					break
				end
			end
		end


		--4. Copy to the end of file
		while true do
			local line = file:read()
			if line == nil then break end

			for j = 1, #RenameAPIs do
				if string.find(line, RenameAPIs[j]) ~= nil then
					--rename API name if it is esist in template policy table
					line  =  string.gsub(line, RenameAPIs[j], RenameAPIs[j] .. "_1")
				end
			end


			--Write to new PT
			file2:write(line)
		end

		file:close()
		file2:close()
		--return true
	--end

	return PolicyTable

end


function testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)

		local pt_fileName = "sdl_preloaded_pt.json"

		--Backup sdl_preloaded_pt.json file
		commonPreconditions:BackupFile(pt_fileName)

		--Copy new policy table to /sdl/bin folder
		os.execute(" cp -f " .. PTName .. " " .. config.pathToSDL .. pt_fileName)

		--Delete policy table
		commonSteps:DeletePolicyTable()


end

function testCasesForPolicyTable:Restore_preloaded_pt()

	Test["PostCondition_Restore_preloaded_pt"] = function(self)

		local pt_fileName = "sdl_preloaded_pt.json"
		commonPreconditions:RestoreFile(pt_fileName)
	end
end

return testCasesForPolicyTable
