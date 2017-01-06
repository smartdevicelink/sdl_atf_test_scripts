--This script contains common functions that are used in many script.
--How to use:
	--1. local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
	--2. commonFunctions:createString(500) --example
---------------------------------------------------------------------------------------------
local commonFunctions = {}
local json = require('json4lua/json/json')
---------------------------------------------------------------------------------------------
------------------------------------------ Functions ----------------------------------------
---------------------------------------------------------------------------------------------
--List of group functions:
--1. Functions for String
--2. Functions for Table
--3. Functions for Test Case
--4. Functions for TTSChunk
--5. Functions for SoftButton
--6. Functions for printing error
--7. Functions for Response
--8. Functions for Notification
--9. Functions for checking the existence
--10. Functions for updated .ini file
--11. Function for updating PendingRequestsAmount in .ini file to test TOO_MANY_PENDING_REQUESTS resultCode
--12. Functions array of structures
--13. Functions for SDL stop
--14. Function gets parameter from smartDeviceLink.ini file
--15. Function sets parameter to smartDeviceLink.ini file
---------------------------------------------------------------------------------------------

--return true if app is media or navigation
function commonFunctions:isMediaApp()

	local isMedia = false

	if Test.isMediaApplication == true or
		Test.appHMITypes["NAVIGATION"] == true	then
		isMedia = true
	end

	return isMedia

end

function commonFunctions:userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

--1. Functions for String
---------------------------------------------------------------------------------------------
function commonFunctions:createString(length)

	return string.rep("a", length)

end

function commonFunctions:createArrayString(size, length)

	if length == nil then
		length = 1
	end

	local temp = {}
	for i = 1, size do
		table.insert(temp, string.rep("a", length))
	end
	return temp

end


function commonFunctions:createArrayInteger(size, value)

	if value == nil then
		value = 1
	end

	local temp = {}
	for i = 1, size do
		table.insert(temp, value)
	end
	return temp

end
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
--2. Functions for Table
---------------------------------------------------------------------------------------------

--Convert a table to string
function commonFunctions:convertTableToString (tbl, i)
	local strIndex = ""
	local strIndex2 = ""
	local strReturn = ""
	for j = 1, i do
		strIndex = strIndex .. "\t"
	end
	strIndex2 = strIndex .."\t"

	local x = 0
	if type(tbl) == "table" then
		strReturn = strReturn .. strIndex .. "{\n"

       for k,v in pairs(tbl) do
			x = x + 1
			if type(k) == "number" then
				if type(v) == "table" then
					if x ==1 then
						--strReturn = strReturn .. strIndex2
					else
						--strReturn = strReturn .. ",\n" .. strIndex2
						strReturn = strReturn .. ",\n"
					end
				else
					if x ==1 then
						strReturn = strReturn .. strIndex2
					else
						strReturn = strReturn .. ",\n" .. strIndex2
					end
				end
			else
				if x ==1 then
					strReturn = strReturn .. strIndex2 .. k .. " = "
				else
					strReturn = strReturn .. ",\n" .. strIndex2 .. k .. " = "
				end
				if type(v) == "table" then
					strReturn = strReturn .. "\n"
				end
			end
			strReturn = strReturn .. commonFunctions:convertTableToString(v, i+1)
       end
	   strReturn = strReturn .. "\n"
	   strReturn = strReturn .. strIndex .. "}"
   else
		if type(tbl) == "number" then
			strReturn = strReturn .. tbl
		elseif type(tbl) == "boolean" then
			strReturn = strReturn .. tostring(tbl)
		elseif type(tbl) == "string" then
			strReturn = strReturn .."\"".. tbl .."\""
		end
   end
   return strReturn
 end


--Print table to ATF log. It is used to debug script.
function commonFunctions:printTable(tbl)
	print ("-------------------------------------------------------------------")
	print (commonFunctions:convertTableToString (tbl, 1))
	print ("-------------------------------------------------------------------")
end
 --------------------------------------------------

--Create new table and copy value from other tables. It is used to void unexpected change original table.
function commonFunctions:cloneTable(original)
	if original == nil then
		return {}
	end

    local copy = {}
    for k, v in pairs(original) do
        if type(v) == 'table' then
            v = commonFunctions:cloneTable(v)
        end
        copy[k] = v
    end
    return copy
end

-- Get table size on top level
local function TableSize(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

--Compare 2 tables
function commonFunctions:is_table_equal(table1, table2)
 -- compare value types
  if type(table1) ~= type(table2) then return false end
  if type(table1) == 'number' then return table1 == table2 end
  if type(table1) == 'boolean' then return table1 == table2 end
  if type(table1) == 'string' then return table1 == table2 end
  -- non-table can't be comparing
  if type(table1) ~= 'table' then return false end
  if type(table1) == 'nil' then return true end

  -- Now, on to tables.
  -- If tables have different size they can't be equal
  --calc size t1
  local size_t1 = TableSize(table1)
  --calc size t2
  local size_t2 = TableSize(table2)
  if (size_t1 ~= size_t2) then return false end

  --compare arrays. Order in array must be equal
  if json.isArray(table1) and json.isArray(table2) then
    for k1,v1 in table1 do
      if not commonFunctions:is_table_equal(v1, table2[k1]) then -- get element  by the same index
        return false
      end
    end
    return true
  end
  -- compare tables by elements
  local already_compared = {} --optimization
  for _,v1 in pairs(table1) do
    for k2,v2 in pairs(table2) do
      if not already_compared[k2] and commonFunctions:is_table_equal(v1,v2) then
        already_compared[k2] = true
      end
    end
  end
  if size_t2 ~= TableSize(already_compared) then
    return false
  end
  return true
end
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
--3. Functions for Test Case
	--Note: Use global variable to add prefix and subfix to test case name:
		--TestCaseNameSuffix
		--TestCaseNamePrefix
---------------------------------------------------------------------------------------------

--Set value for a parameter on the request
function commonFunctions:setValueForParameter(Request, Parameter, Value)

	local temp = Request
	for i = 1, #Parameter - 1 do
		temp = temp[Parameter[i]]
	end

	temp[Parameter[#Parameter]] = Value

-- Due to Lua specific empty array defines as empty structure (APPLINK-15292). For testing addressLines in GetWayPoints (CRQ APPLINK-21610) response use next condition.
	if  Value == nil and Parameter[#Parameter-1] == "addressLines" then 
print("Check success response in SDL logs. Due to APPLINK-15292 ATF fails next case")

		temp[Parameter[#Parameter]] = json.EMPTY_ARRAY 
	end

	--[=[print request if parameter matches Debug value
	if Debug ~= {} then
		if #Debug == #Parameter then
			local blnPrint = true

			for i =1, #Debug do
				if Debug[i] ~= Parameter[i] then
					blnPrint = false
					break
				end
			end

			if blnPrint == true then
				commonFunctions:printTable(Request)
			end
		end
	end	]=]
end


--Global variable TestCaseNameSuffix is suffix for test case. It is used to add text at the end of test case.
local function BuildTestCase(Parameter, verificationName, resultCode)

	local testCaseName = ""
	--Add parameters to test case name
	for i = 1, #Parameter  do
		if Parameter[i] == 1 then
			testCaseName =  testCaseName .. "_" .. "element"
		else
			testCaseName =  testCaseName .. "_" .. tostring(Parameter[i])
		end
	end

	--Add verification to test case
	testCaseName = testCaseName .. "_" .. verificationName

	--Add resultCode to test case name
	if resultCode ~= nil then
		testCaseName = testCaseName .. "_" .. resultCode
	end

	--Add suffix to test case name
	if TestCaseNameSuffix ~= nil then
		testCaseName = testCaseName .. "_" .. TestCaseNameSuffix
	end

	--Add Prefix to test case name
	if TestCaseNamePrefix ~= nil then
		testCaseName = "_" .. TestCaseNamePrefix .. testCaseName
	end

	return testCaseName
end

--Build test case name from APIName, parameter and verification name
function commonFunctions:BuildTestCaseName(Parameter, verificationName, resultCode)

	return APIName .. BuildTestCase(Parameter, verificationName, resultCode)
end

--Build test case name from APIName, parameter and verification name
function commonFunctions:BuildTestCaseNameForResponse(Parameter, verificationName, resultCode)

	return APIName .. "_Response".. BuildTestCase(Parameter, verificationName, resultCode)
end


--Print new line to separate new test cases group
function commonFunctions:newTestCasesGroup(ParameterOrMessage)

	NewTestSuiteNumber = NewTestSuiteNumber + 1

	local message = ""

	--Print new lines to separate test cases group in test report
	if ParameterOrMessage == nil then
		message = "Test Suite For Parameter:"
	elseif type(ParameterOrMessage)=="table" then
		local Prameter = ParameterOrMessage

        for i = 1, #Prameter  do
			if type(Prameter[i]) == "number" then
				message =  message .. "[" .. tostring(Prameter[i]) .. "]"
			else
				if message == "" then
					message = tostring(Prameter[i])
				else
					local len  = string.len(message)
					if string.sub(message, len -1, len) == "]" then
						message =  message .. tostring(Prameter[i])
					else
						message =  message .. "." .. tostring(Prameter[i])
					end


				end
			end
		end
		message =  "Test Suite For Parameter: " .. message

	else
		message = ParameterOrMessage
    end

	Test["Suite_" .. tostring(NewTestSuiteNumber)] = function(self)

		local  length = 80
		local spaces = length - string.len(message)
		--local line1 = string.rep(" ", math.floor(spaces/2)) .. message
		local line1 = message
		local line2 = string.rep("-", length)

		print("\27[33m" .. line2 .. "\27[0m")
		print("")
		print("")
		print("\27[33m" .. line1 .. "\27[0m")
		print("\27[33m" .. line2 .. "\27[0m")

	end


end

local messageflag = false
--This function sends a request from mobile with INVALID_DATA and verify result on mobile.
function commonFunctions:verify_Unsuccess_Case(self, Request, ResultCode)

	if messageflag == false then
		print (" \27[33m verify_INVALID_DATA_Case function is absent in script for invalid cases is used common function commonFunctions:verify_Unsuccess_Case. Please add function for processing invalid cases in script. \27[0m")
	end

	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC(APIName, Request)


	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = ResultCode })
	:Timeout(50)

	messageflag = true
end

--Send a request and check result code
function commonFunctions:SendRequestAndCheckResultCode(self, Request, ResultCode)

	if ResultCode == "SUCCESS" then

		self:verify_SUCCESS_Case(Request)

	elseif ResultCode == "INVALID_DATA" or ResultCode == "DISALLOWED" then

		if self.verify_INVALID_DATA_Case then
			self:verify_INVALID_DATA_Case(Request)
		else
			commonFunctions:verify_Unsuccess_Case(self, Request, ResultCode)
		end

	else

		print("Error: Input resultCode is not SUCCESS or INVALID_DATA or DISALLOWED")
	end

end

function commonFunctions:BuildChildParameter(ParentParameter, childParameter)
	local temp = commonFunctions:cloneTable(ParentParameter)
	table.insert(temp, childParameter)
	return temp
end




--Common test case
function commonFunctions:TestCase(self, Request, Parameter, Verification, Value, ResultCode)

	Test[commonFunctions:BuildTestCaseName(Parameter, Verification, ResultCode)] = function(self)

		--Copy request
		local TestingRequest = commonFunctions:cloneTable(Request)

		--Set value for the Parameter in request
		commonFunctions:setValueForParameter(TestingRequest, Parameter, Value)

		--Send the request and check resultCode
		commonFunctions:SendRequestAndCheckResultCode(self, TestingRequest, ResultCode)
	end
end



---------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------
--4. Functions for TTSChunk
---------------------------------------------------------------------------------------------

function commonFunctions:createTTSChunk(strText, strType)

	return 	{
				text =strText,
				type = strType
			}

end


function commonFunctions:createTTSChunks(strText, strType, number)

	local temp = {}
	local TTSChunk = {}

	if number ==1 then
		TTSChunk = commonFunctions:createTTSChunk(strText, strType)
		table.insert(temp, TTSChunk)
	else
		for i = 1, number do
			TTSChunk = commonFunctions:createTTSChunk(strText .. tostring(i), strType)
			table.insert(temp, TTSChunk)
		end
	end

	return temp

end


---------------------------------------------------------------------------------------------
--5. Functions for SoftButton
---------------------------------------------------------------------------------------------


function commonFunctions:createSoftButton(SoftButtonID, Text, SystemAction, Type, IsHighlighted, ImageType, ImageValue)

	return
	{
		softButtonID = SoftButtonID,
		text = Text,
		systemAction = SystemAction,
		type = Type,
		isHighlighted = IsHighlighted,
		image =
		{
		   imageType = ImageType,
		   value = ImageValue
		}
	}
end



function commonFunctions:createSoftButtons(SoftButtonID, Text, SystemAction, Type, IsHighlighted, ImageType, ImageValue, number)

	local temp = {}
	local button = {}
	if number == 1 then
		button  = commonFunctions:createSoftButton(SoftButtonID, Text, SystemAction, Type, IsHighlighted, ImageType, ImageValue)
		table.insert(temp, button)
	else
		for i = 1, number do
			button  = commonFunctions:createSoftButton(SoftButtonID + i - 1, Text .. tostring(i), SystemAction, Type, IsHighlighted, ImageType, ImageValue)
			table.insert(temp, button)
		end
	end

	return temp

end

---------------------------------------------------------------------------------------------
--6. Functions for printing error
---------------------------------------------------------------------------------------------
function commonFunctions:printError(errorMessage)
	print()
	print(" \27[31m " .. errorMessage .. " \27[0m ")
end


function commonFunctions:sendRequest(self, Request, functionName, FunctionId)

	local message = json.encode(Request)
	local cid

	if string.find(message, "{}") ~= nil or string.find(message, "{{}}") ~= nil then
		message = string.gsub(message, "{}", "[]")
		message = string.gsub(message, "{{}}", "[{}]")

		self.mobileSession.correlationId = self.mobileSession.correlationId + 1

		local msg =
		{
			serviceType      = 7,
			frameInfo        = 0,
			rpcType          = 0,
			rpcFunctionId    = FunctionId,
			rpcCorrelationId = self.mobileSession.correlationId,
			payload          = message
		}
		self.mobileSession:Send(msg)
		cid = self.mobileSession.correlationId
	else
		--mobile side: sending the request
		cid = self.mobileSession:SendRPC(functionName, Request)
	end

	return cid
end


---------------------------------------------------------------------------------------------
--7. Functions for Response
---------------------------------------------------------------------------------------------


--Send a request and response and check result code
function commonFunctions:SendRequestAndResponseThenCheckResultCodeForResponse(self, Response, ResultCode)

	if ResultCode == "SUCCESS" then

		self:verify_SUCCESS_Response_Case(Response)

	elseif ResultCode == "GENERIC_ERROR" then

		self:verify_GENERIC_ERROR_Response_Case(Response)

	else

		print("Error: SendRequestAndResponseThenCheckResultCodeForResponse function: Input resultCode is not SUCCESS or GENERIC_ERROR")
	end

end



function commonFunctions:TestCaseForResponse(self, Response, Parameter, Verification, Value, ResultCode)

	Test[commonFunctions:BuildTestCaseNameForResponse(Parameter, Verification, ResultCode)] = function(self)

		--Copy Response
		local TestingResponse = commonFunctions:cloneTable(Response)

		--Set value for the Parameter in Response
		commonFunctions:setValueForParameter(TestingResponse, Parameter, Value)

		--Send the request and response then check resultCode
		commonFunctions:SendRequestAndResponseThenCheckResultCodeForResponse(self, TestingResponse, ResultCode)
	end
end


---------------------------------------------------------------------------------------------
--8. Functions for Notification
---------------------------------------------------------------------------------------------
--Build test case name from APIName, parameter and verification name
function commonFunctions:BuildTestCaseNameForNotification(Parameter, verificationName, resultCode)

	--return APIName .. "_Notification".. BuildTestCase(Parameter, verificationName, resultCode)
	return APIName .. BuildTestCase(Parameter, verificationName, resultCode)
end



--Send Notification and check Notification on mobile
function commonFunctions:SendNotificationAndCheckResultOnMobile(self, Notification, IsValidValue)

	if IsValidValue == true then

		self:verify_SUCCESS_Notification_Case(Notification)

	else

		self:verify_Notification_IsIgnored_Case(Notification)

	end

end


function commonFunctions:TestCaseForNotification(self, Notification, Parameter, Verification, Value, IsValidValue)

	Test[commonFunctions:BuildTestCaseNameForNotification(Parameter, Verification)] = function(self)

		--Copy BuildTestCase
		local TestingNotification = commonFunctions:cloneTable(Notification)

		--Set value for the Parameter in Notification
		commonFunctions:setValueForParameter(TestingNotification, Parameter, Value)

		--Send Notification and check Notification on mobile
		commonFunctions:SendNotificationAndCheckResultOnMobile(self, TestingNotification, IsValidValue)
	end
end

---------------------------------------------------------------------------------------------
--9. Functions for checking the existence
---------------------------------------------------------------------------------------------

-- Check directory existence
function commonFunctions:Directory_exist(DirectoryPath)
	local returnValue

	local Command = assert( io.popen(  "[ -d " .. tostring(DirectoryPath) .. " ] && echo \"Exist\" || echo \"NotExist\"" , 'r'))
	local CommandResult = tostring(Command:read( '*l' ))

	if
		CommandResult == "NotExist" then
			returnValue = false
	elseif
		CommandResult == "Exist" then
		returnValue =  true
	else
		commonFunctions:userPrint(31," Some unexpected result in Directory_exist function, CommandResult = " .. tostring(CommandResult))
		returnValue = false
	end

	return returnValue
end

-- Check file existence
function commonFunctions:File_exists(file_name)	
  	local file_found=io.open(file_name, "r")  
  	if file_found==nil then
    	return false
  	else
    	return true
  	end
end
---------------------------------------------------------------------------------------------
--10. Functions for updated .ini file
---------------------------------------------------------------------------------------------
-- !!! Do not update fucntion without necessity. In case of updating check all scripts where function is used.
function commonFunctions:SetValuesInIniFile(FindExpression, parameterName, ValueToUpdate )
	local SDLini = config.pathToSDL .. "smartDeviceLink.ini"

	f = assert(io.open(SDLini, "r"))
		if f then
			fileContent = f:read("*all")

			fileContentFind = fileContent:match(FindExpression)

			local StringToReplace

			if ValueToUpdate == ";" then
				StringToReplace =  ";" .. tostring(parameterName).. " =  \n"
			else
				StringToReplace =  tostring(parameterName) .. " = " .. tostring(ValueToUpdate) .. "\n"
			end

			if fileContentFind then
				fileContentUpdated  =  string.gsub(fileContent, FindExpression, StringToReplace)

				f = assert(io.open(SDLini, "w"))
				f:write(fileContentUpdated)
			else
				commonFunctions:userPrint(31, "Finding of '" .. tostring(parameterName) .. " = value' is failed. Expect string finding and replacing the value to " .. tostring(ValueToUpdate))
			end
			f:close()
		end
end

---------------------------------------------------------------------------------------------
--11. Function for updating PendingRequestsAmount in .ini file to test TOO_MANY_PENDING_REQUESTS resultCode
---------------------------------------------------------------------------------------------
function commonFunctions:SetValuesInIniFile_PendingRequestsAmount(ValueToUpdate)
	commonFunctions:SetValuesInIniFile("%p?PendingRequestsAmount%s?=%s-[%d]-%s-\n", "PendingRequestsAmount", ValueToUpdate)
end
---------------------------------------------------------------------------------------------
--12. Functions array of structures
---------------------------------------------------------------------------------------------
function commonFunctions:createArrayStruct(size, Struct)

	if length == nil then
		length = 1
	end

	local temp = {}
	for i = 1, size do
		table.insert(temp, Struct)
	end

	return temp

end
---------------------------------------------------------------------------------------------
--13. Functions for SDL stop
---------------------------------------------------------------------------------------------
function commonFunctions:SDLForceStop(self)
	os.execute("ps aux | grep smart | awk \'{print $2}\' | xargs kill -9")
	os.execute("sleep 1")
end

function check_file_existing(path)
	local file = io.open(path, "r")
	if file == nil then
		print("File doesnt exist, path:"..path)
		assert(false)
	end
	file:close()
end

---------------------------------------------------------------------------------------------
--14. Function gets parameter from smartDeviceLink.ini file
---------------------------------------------------------------------------------------------
function commonFunctions:read_parameter_from_smart_device_link_ini(param_name)
	local path_to_ini_file = config.pathToSDL .. "smartDeviceLink.ini"
	check_file_existing(path_to_ini_file)
	local param_value  = nil
	for line in io.lines(path_to_ini_file) do
		if string.match(line, "^%s*"..param_name.."%s*=%s*") ~= nil then
			if string.find(line, "%s*=%s*$") ~= nil then
				param_value = ""
				break
			end
			local b, e = string.find(line, "%s*=%s*.")
			if b ~= nil then
				local len = string.len(line)
				param_value = string.sub(line, e, len)
				break
			end
		end
	end
	return param_value
end

---------------------------------------------------------------------------------------------
--15. Function sets parameter to smartDeviceLink.ini file
---------------------------------------------------------------------------------------------
function commonFunctions:write_parameter_to_smart_device_link_ini(param_name, param_value)
	local path_to_ini_file = config.pathToSDL .. "smartDeviceLink.ini"
	check_file_existing(path_to_ini_file)
	local new_file_content = ""
	local is_find_string = false
	local result = false
	for line in io.lines(path_to_ini_file) do
		if is_find_string == false then
			if string.match(line, "^%s*"..param_name.."%s*=%s*") ~= nil then
				line = param_name.." = "..param_value
				is_find_string = true
			end
		end
		new_file_content = new_file_content..line.."\n"
	end
	if is_find_string == true then
		local file = io.open(path_to_ini_file, "w")
		if file then
			file:write(new_file_content)
			file:close()
			result = true
		else
			print("File doesn't open, path:"..path_to_ini_file)
			assert(false)
		end
	end
	return result
end

return commonFunctions
