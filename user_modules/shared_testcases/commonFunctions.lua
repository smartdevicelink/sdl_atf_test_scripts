--This script contains common functions that are used in many script.
--How to use:
  --1. local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
  --2. commonFunctions:createString(500) --example
---------------------------------------------------------------------------------------------
local commonFunctions = {}
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
require('atf.util')
local json = require('json4lua/json/json')
local SDL = require("SDL")
local events = require('events')
local NewTestSuiteNumber = 0 -- use as subfix of test case "NewTestSuite" to make different test case name.
local path_config = commonPreconditions:GetPathToSDL()
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
--13. Functions for put to sleep thread
--14. Functions for SDL stop
--15. Function gets parameter from smartDeviceLink.ini file
--16. Function sets parameter to smartDeviceLink.ini file
--17. Function transform data from PTU to permission change data
--18. Function returns data from sqlite by query
--19. Function checks value of column from DB with input data
--20. Function checks PTU sequence need to call when PTU is triggered before call of function – it should just finalize PTU
-- Checkes PTU HTTP flow.
--21. Function checks PTU sequence fully need to call when PTU is UP_TO_DATE, and PTU was triggerd.
--22. Function Subscribe sdl to vehicle data
--23. Function Unsubscribe sdl from vehicle data
--24. Function start PTU sequence HTTP flow
--25. Function reads log file and find specific string in this file.
--26. Function updates json file with new section
--27. Function joins paths of file system
---------------------------------------------------------------------------------------------

--return true if app is media or navigation
function commonFunctions:isMediaApp()

  local isMedia = false

  if Test.isMediaApplication == true or
    Test.appHMITypes["NAVIGATION"] == true  then
    isMedia = true
  end

  return isMedia
end

--check that SDL ports are open then raise else RUN after timeout configured by step variable
function commonFunctions:waitForSDLStart(test)
  return SDL.WaitForSDLStart(test)
end

function commonFunctions:createMultipleExpectationsWaiter(test, name)
  local expectations = require('expectations')
  local Expectation = expectations.Expectation
  assert(test and name)
  exp_waiter = {}
  exp_waiter.expectation_list = {}
  function exp_waiter:CheckStatus()
     if #exp_waiter.expectation_list == 0 and not exp_waiter.expectation.status then
      exp_waiter.expectation.status = SUCCESS
      event_dispatcher:RaiseEvent(test.mobileConnection, exp_waiter.event)
      return true
     end
     return false
  end

  function exp_waiter:AddExpectation(exp)
    table.insert(exp_waiter.expectation_list, exp)
    exp:Do(function()
      if exp_waiter:RemoveExpectation(exp) then
        exp_waiter:CheckStatus()
      end
    end)
  end

  function exp_waiter:RemoveExpectation(exp)
    local function AnIndexOf(t,val)
      for k,v in ipairs(t) do
        if v == val then return k end
      end
      return nil
    end
    local index = AnIndexOf(exp_waiter.expectation_list, exp)
    if index then table.remove(exp_waiter.expectation_list, index) end
    return index
  end

  exp_waiter.event = events.Event()

  exp_waiter.event.matches = function(self, e)
    return self == e
  end

  exp_waiter.expectation = Expectation(name, test.mobileConnection)
  exp_waiter.expectation.event = exp_waiter.event
  exp_waiter.event.level = 3
  event_dispatcher:AddEvent(test.mobileConnection, exp_waiter.event , exp_waiter.expectation)
  test:AddExpectation(exp_waiter.expectation)
  return exp_waiter
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

function commonFunctions:createArrayEnum(size, value)

  local temp = {}
  for i = 1, size do
    table.insert(temp, value)
  end
  return temp

end

function commonFunctions:buildColoredString(color, message)
  if config.color then
    return "\27[" .. tostring(color) .. "m" .. tostring(message) .. "\27[0m"
  end
  return message
end

function commonFunctions:userPrint( color, message, delimeter)
  delimeter = delimeter or "\n"
  io.write(commonFunctions:buildColoredString(color, message), delimeter)
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
    if getmetatable(original) ~= nil then setmetatable(copy, getmetatable(original)) end
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
  local type1 = type(table1)
  local type2 = type(table2)
  if type1 ~= type2 then return false end
  if type1 ~= 'table' and type2 ~= 'table' then return table1 == table2 end
  local size_tab1 = TableSize(table1)
  local size_tab2 = TableSize(table2)
  if size_tab1 ~= size_tab2 then return false end

  --compare arrays
  if json.isArray(table1) and json.isArray(table2) then
    local found_element
    local copy_table2 = commonFunctions:cloneTable(table2)
    for i, _  in pairs(table1) do
      found_element = false
      for j, _ in pairs(copy_table2) do
        if commonFunctions:is_table_equal(table1[i], copy_table2[j]) then
          copy_table2[j] = nil
          found_element = true
          break
        end
      end
      if found_element == false then
        break
      end
    end
    if TableSize(copy_table2) == 0 then
      return true
    else
      return false
    end
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
  if size_tab2 ~= TableSize(already_compared) then
    return false
  end
  return true
end

function commonFunctions:table_contains(table, value)
  if not table then return false end
  for _,val in pairs(table) do
    if val == value then return true end
  end
  return false
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
  end ]=]
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

  return  {
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
function commonFunctions:File_exists(path)
  local file = io.open(path, "r")
  if file == nil then
    print("File doesnt exist, path:"..path)
    return false
  else
    local ok, err, code = file:read(1)
    local res_code_for_dir = 21
    if code == res_code_for_dir then
      print("It is path to directory")
      file:close()
      return false
    end
  end
  file:close()
  return true
end

---------------------------------------------------------------------------------------------
--10. Functions for updated .ini file
---------------------------------------------------------------------------------------------
-- !!! Do not update fucntion without necessity. In case of updating check all scripts where function is used.
function commonFunctions:SetValuesInIniFile(FindExpression, parameterName, ValueToUpdate )
  local SDLini = path_config .. "smartDeviceLink.ini"

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
--13. Functions for put to sleep thread
---------------------------------------------------------------------------------------------
--! @brief Put to sleep thread for n seconds
--! @param n contains ammount of seconds
function commonFunctions:sleep(n)
  os.execute("sleep " .. tonumber(n))
end


---------------------------------------------------------------------------------------------
--14. Functions for SDL stop
---------------------------------------------------------------------------------------------
function commonFunctions:SDLForceStop(self)
  os.execute("ps aux | grep ./smartDeviceLinkCore | awk '{print $2}' | xargs kill -9")
  commonFunctions:sleep(1)
end

local function concatenation_path(path1, path2)
  local len = string.len(path1)
  if string.sub(path1, len, len) == '/' then
    return path1..path2
  end
  return path1..'/'..path2
end

---------------------------------------------------------------------------------------------
--15. Function gets parameter from smartDeviceLink.ini file
---------------------------------------------------------------------------------------------
function commonFunctions:read_parameter_from_smart_device_link_ini(param_name)
  local path_to_ini_file = concatenation_path(path_config, "smartDeviceLink.ini")
  assert(commonFunctions:File_exists(path_to_ini_file))
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
--16. Function sets parameter to smartDeviceLink.ini file
---------------------------------------------------------------------------------------------
function commonFunctions:write_parameter_to_smart_device_link_ini(param_name, param_value)
  local path_to_ini_file = concatenation_path(path_config, "smartDeviceLink.ini")
  assert(commonFunctions:File_exists(path_to_ini_file))
  local new_file_content = ""
  local is_find_string = false
  local result = false
  for line in io.lines(path_to_ini_file) do
    if is_find_string == false then
      if string.match(line, "[; ]*"..param_name..".*=.*") ~= nil then
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

---------------------------------------------------------------------------------------------
--17. Function transform data from PTU to permission change data
---------------------------------------------------------------------------------------------
function commonFunctions:convert_ptu_to_permissions_change_data(path_to_ptu, group_name, is_user_allowed)
  local permission_item_json_template = [[{"rpcName":"",
  "parameterPermissions":{"userDisallowed":[], "allowed":[]},
  "hmiPermissions":{"allowed":[], "userDisallowed":[]}}]]
  local permission_item_table_template = json.decode(permission_item_json_template);
  local file = io.open(path_to_ptu, "r")
  if file == nil then
    print("File doesnt exist, path:"..path_to_ptu)
    assert(false)
  end

  local json_data = file:read("*a")
  file:close()

  local data = json.decode(json_data)
  local rpcs = nil
  for key in pairs(data.policy_table.functional_groupings) do
    if key == group_name then
      rpcs = data.policy_table.functional_groupings[key].rpcs
      break
    end
  end
  local permission_items = {}
  local permission_item
  if rpcs == nil then
    print("Group name:"..group_name.." doesn't contain list of rpcs")
    assert(false)
  end

  for key in pairs(rpcs) do
    permission_item = commonFunctions:cloneTable(permission_item_table_template)
    permission_item.rpcName = key
    if is_user_allowed == true then
      permission_item.hmiPermissions.allowed = rpcs[key].hmi_levels
    else
      permission_item.hmiPermissions.userDisallowed = rpcs[key].hmi_levels
    end
    table.insert(permission_items, permission_item)
  end
  return permission_items
end

---------------------------------------------------------------------------------------------
-- Function returns output from console
---------------------------------------------------------------------------------------------
function os.capture(cmd, raw)
   local f = assert(io.popen(cmd, 'r'))
     local s = assert(f:read('*a'))
   f:close()
   if raw then return s end
   s = string.gsub(s, '^%s+', '')
   s = string.gsub(s, '%s+$', '')
   s = string.gsub(s, '[\n\r]+', ' ')
   return s
 end

---------------------------------------------------------------------------------------------
--18. Function returns data from sqlite by query
---------------------------------------------------------------------------------------------
--! @brief Gets data from db
--! @param db_path path to DB
--! @param sql_query contains select query with determine name of column. Don't use query with *
--! example of sql_query: "SELECT preloaded_pt FROM module_config"
--! "SELECT functional_group_id FROM app_group WHERE application_id='0000001'"
--! "SELECT functional_group_id FROM app_group WHERE application_id=\\\"0000001\\\""
--! @returns Requirements for result:
--! 1. result contains array of string.
--! 2. result contains boolean values like string "0" - false, "1" - true.
--! 3. result contains numbers like string.
function commonFunctions:get_data_policy_sql(db_path, sql_query)
  if string.match(sql_query, "^%a+%s*%*%s*%a+") ~= nil then
    print("Please specife name of column, don't use *")
    assert(false)
  end
  assert(commonFunctions:File_exists(db_path))
  local commandToExecute = "sqlite3 "..db_path .." \""..sql_query.."\""
  local db = nil
  local time_to_wait_read_data = 1
  local attempts_to_read = 10
  local selected_data = ""
  for i = 1, attempts_to_read do
    commonFunctions:sleep(time_to_wait_read_data)
    db = assert(io.popen(commandToExecute, 'r'))
    selected_data = assert(db:read('*a'))
    db:close()
    if string.len(selected_data) ~= 0 then
      break
    end
  end

  local column_db = {}
  if string.len(selected_data) == 0 then
    print("WARNING: script can not take data from DB. Please check query")
  else
    local b, e = 1, 0
    while e < string.len(selected_data) do
      e = string.find(selected_data, "\n", b)
      table.insert(column_db, string.sub(selected_data, b, e-1))
      b = e+1
    end
  end
  return column_db
end

---------------------------------------------------------------------------------------------
--19. Function checks value of column from DB with input data
---------------------------------------------------------------------------------------------
--! @brief Check if DB contains column with data
--! @param db_path path to DB
--! @param sql_query contains select query with determine name of column. Don't use query with *
--! example of sql_query: "SELECT preloaded_pt FROM module_config"
--! "SELECT functional_group_id FROM app_group WHERE application_id='0000001'"
--! "SELECT functional_group_id FROM app_group WHERE application_id=\\\"0000001\\\""
--! @param exp_result contains data for comparing data from DB.
--! Requirements for exp_result:
--! 1. exp_result MUST contain array of string.
--! 2. Boolean values MUST be like string "0" - false, "1" - true.
--! 3. Numbers MUST be like string.
--! @return Returns false if expected data are not equal with DB data, otherwise returns true.
function commonFunctions:is_db_contains(db_path, sql_query, exp_result)
  local column_db = commonFunctions:get_data_policy_sql(db_path, sql_query)
  return commonFunctions:is_table_equal(column_db, exp_result)
end

--------------------------------------------------------------------------------------------
--20. Function checks PTU sequence need to call when PTU is triggered before call of function – it should just finalize PTU
-- Checkes PTU HTTP flow.
---------------------------------------------------------------------------------------------
--! @brief Checks PTU HTTP flow sequence
--! @param ptu_path path to PTU file
--! @param ptu_name contains name of PTU file
function commonFunctions:check_ptu_sequence_partly(self, ptu_path, ptu_name)
  assert(commonFunctions:File_exists(ptu_path))
  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
    {
      requestType = "HTTP",
      fileName = ptu_name,
    },ptu_path)
  EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMICALL("BasicCommunication.SystemRequest"):Times(0)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :ValidIf(function(exp,data)
    if (exp.occurences == 1 or exp.occurences == 2) and
      data.params.status == "UP_TO_DATE" then
        return true
    end
    if exp.occurences == 1 and data.params.status == "UPDATING" then
        return true
    end
    return false
  end):Times(Between(1,2))
  EXPECT_HMICALL("VehicleInfo.GetVehicleData", {odometer=true}):Do(
    function(_,data)
  --hmi side: sending VehicleInfo.GetVehicleData response
  self.hmiConnection:SendResponse(data.id,"VehicleInfo.GetVehicleData", "SUCCESS", {odometer=0})
  end)
end

--------------------------------------------------------------------------------------------
--21. Function checks PTU sequence fully need to call when PTU is UP_TO_DATE, and PTU was triggerd.
---------------------------------------------------------------------------------------------
--! @brief Checks PTU HTTP flow fully sequence
--! @param ptu_path path to PTU file
--! @param ptu_name contains name of PTU file
function commonFunctions:check_ptu_sequence_fully(self, ptu_path, ptu_name)
assert(commonFunctions:File_exists(ptu_path))
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "HTTP"})
  :Do(function()
  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
    {
      requestType = "HTTP",
      fileName = ptu_name,
    },ptu_path)
  end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
   :ValidIf(function(exp,data)
    if
      exp.occurences == 1 and
      data.params.status == "UPDATE_NEEDED" then
    return true
    elseif exp.occurences == 2 and
      data.params.status == "UPDATING" then
    return true
    elseif exp.occurences == 3 and
      data.params.status == "UP_TO_DATE" then
      return true
    end
    return false
    end):Times(3)
end

--------------------------------------------------------------------------------------------
--Function fills request parameters for subscribe unsubscrive vehicle data
---------------------------------------------------------------------------------------------
--! @brief Fills table with parameter for subscribe unsubscribe vehicle data request
--! @param vehicle_data contains name of parameters. That must be subcribed to vi info from HMI.
--! @return Returns table with request parameters
local function fill_parameters_for_vi_subscription_request(vehicle_data)
  local request_parameters={}
  for _, v in pairs(vehicle_data) do
    request_parameters[v] = true
  end
  return request_parameters
end

--------------------------------------------------------------------------------------------
--Function fills response parameters for subscribe unsubscrive vehicle data
---------------------------------------------------------------------------------------------
--! @brief Fills table with parameter for subscribe unsubscribe vehicle data response
--! @param vehicle_data contains name of parameters
--! @param result_codes contains table with result code for vehicle data params
--! @return Returns table with response parameters
local function fill_parameters_for_vi_subscription_response(vehicle_data, result_codes)
  local SVDValues = {gps = "VEHICLEDATA_GPS",
    speed = "VEHICLEDATA_SPEED",
    rpm = "VEHICLEDATA_RPM",
    fuelLevel = "VEHICLEDATA_FUELLEVEL",
    fuelLevel_State = "VEHICLEDATA_FUELLEVEL_STATE",
    instantFuelConsumption = "VEHICLEDATA_FUELCONSUMPTION",
    externalTemperature = "VEHICLEDATA_EXTERNTEMP",
    prndl = "VEHICLEDATA_PRNDL",
    tirePressure = "VEHICLEDATA_TIREPRESSURE",
    odometer = "VEHICLEDATA_ODOMETER",
    beltStatus = "VEHICLEDATA_BELTSTATUS",
    bodyInformation = "VEHICLEDATA_BODYINFO",
    deviceStatus = "VEHICLEDATA_DEVICESTATUS",
    driverBraking = "VEHICLEDATA_BRAKING",
    wiperStatus = "VEHICLEDATA_WIPERSTATUS",
    headLampStatus = "VEHICLEDATA_HEADLAMPSTATUS",
    engineTorque = "VEHICLEDATA_ENGINETORQUE",
    accPedalPosition = "VEHICLEDATA_ACCPEDAL",
    steeringWheelAngle = "VEHICLEDATA_STEERINGWHEEL",
    vin = "VEHICLEDATA_VIN"
  }
  local response_parameters={}
  for _, v in pairs(vehicle_data) do
    local key = v ~= "clusterModeStatus" and v or "clusterModes"
    response_parameters[key] = {
          resultCode = result_codes[v],
          dataType = SVDValues[v]
      }
  end
  return response_parameters
end

-- ---------------------------------------------------------------------------------------------
-- Function Subscribe/Unsubscribe sdl to vehicle data
-- ---------------------------------------------------------------------------------------------
--! @brief  Subscribe/Unsubscribe sdl to vehicle data
--! @param self contains Test
--! @param vehicle_data contains name of parameters
--! @param result_codes contains table with result code for vehicle data params
--! @param hmi_function_id contains function id for request to HMI
--! @param mob_function_id contains function id for request from mobile
local function sub_unsub_vehicle_data(self, vehicle_data, result_codes, hmi_function_id, mob_function_id)
  local request_parameters = fill_parameters_for_vi_subscription_request(vehicle_data)
  local response_parameters = fill_parameters_for_vi_subscription_response(vehicle_data, result_codes)
  local CorId = self.mobileSession:SendRPC(mob_function_id, request_parameters)
  --hmi side: expect SubscribeVehicleData request
  EXPECT_HMICALL(hmi_function_id, request_parameters)
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.SubscribeVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response_parameters)
    end)

  EXPECT_RESPONSE(CorId, { success = true, resultCode = "SUCCESS"})
  --mobile side: expect OnHashChange notification
  EXPECT_NOTIFICATION("OnHashChange")
end

-- ---------------------------------------------------------------------------------------------
--22. Function Subscribe sdl to vehicle data
-- ---------------------------------------------------------------------------------------------
--! @brief  Subscribe sdl to vehicle data
--! @param self contains Test
--! @param vehicle_data contains name of parameters
--! @param result_codes contains table with result code for vehicle data params
function commonFunctions:subscribe_to_vehicle_data(self, vehicle_data, result_codes)
  sub_unsub_vehicle_data(self, vehicle_data, result_codes, "VehicleInfo.SubscribeVehicleData", "SubscribeVehicleData")
end
-- ---------------------------------------------------------------------------------------------
--23. Function Unsubscribe sdl from vehicle data
-- ---------------------------------------------------------------------------------------------
--! @brief Unsubscribe sdl to vehicle data
--! @param self contains Test
--! @param vehicle_data contains name of parameters
--! @param result_codes contains table with result code for vehicle data params
function commonFunctions:unsubscribe_to_vehicle_data(self, vehicle_data, result_codes)
  sub_unsub_vehicle_data(self, vehicle_data, result_codes, "VehicleInfo.UnSubscribeVehicleData", "UnSubscribeVehicleData")
end

-- ---------------------------------------------------------------------------------------------
--24. Function start PTU sequence HTTP flow
-- ---------------------------------------------------------------------------------------------
--! @brief Triggers PTU HTTP flow sequence by odometer
--! @param self contains Test
function commonFunctions:trigger_ptu_by_odometer(self)
  local path_to_policy_db = concatenation_path(path_config, "storage/policy.sqlite")
  local exchange_after_x_kilometers = commonFunctions:get_data_policy_sql(path_to_policy_db,
    "SELECT exchange_after_x_kilometers FROM module_config")
  local pt_exchange_at_odometer_x = commonFunctions:get_data_policy_sql(path_to_policy_db,
    "SELECT pt_exchanged_at_odometer_x FROM module_meta")
  local pt_exchange_odometer = tonumber(exchange_after_x_kilometers[1]) +
  tonumber(pt_exchange_at_odometer_x[1]) + 1
  --hmi side: Trigger PTU update
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {odometer = pt_exchange_odometer})
end

-- ---------------------------------------------------------------------------------------------
--25. Function reads log file and find specific string in this file.
-- ---------------------------------------------------------------------------------------------
--! @brief Reads log file and find specific string in this file.
--! @param path contains path to log file.

function commonFunctions:read_specific_message(path, message)
local file = io.open(path, "r")
if file == nil then
    print("File doesnt exist, path:"..path)
    assert(false)
  end
  local log_file = file:read("*a")
  file:close()
  local b, e = string.find(log_file, message)
  if b ~= nil then
    return true
  end
  return false
end

-- ---------------------------------------------------------------------------------------------
--26. Function updates json file with new section
-- ---------------------------------------------------------------------------------------------
--! @brief Function updates json file with new section
--! @param path_to_json contains path to json file, that should be updated
--! @param old_section path to old section MUST contain path like: policy_table.app_policies.default
--! section must be separated by point
--! @param new_section contain table with new data for updating

function commonFunctions:update_json_file(path_to_json, old_section, new_section)
  local file = io.open(path_to_json, "r")
  if file == nil then
    print("File doesnt exist, path:"..path_to_json)
    assert(false)
  end
  local json_data = file:read("*a")
  file:close()
  local data = json.decode(json_data)
  local begin_ref, end_ref = 0,0
  local temp_path = old_section.."."
  local len = string.len(temp_path)
  local key
  local temp_data = data
  while end_ref < len do
    end_ref = string.find(temp_path, "%.", begin_ref)
    if end_ref~= nil then
      key = string.sub(temp_path, begin_ref, end_ref-1);
      if temp_data[key] ==  nil then
        print("JSON file: "..path_to_json.." doesn't contain key= "..key)
        return
      end
      if end_ref == len then
        temp_data[key] = new_section
      else
        temp_data = temp_data[key]
      end
      begin_ref = end_ref+1;
    else
      print("Incorrect path to old section")
      return
    end
  end
  local dataToWrite = json.encode(data)
  file = io.open(path_to_json, "w")
  file:write(dataToWrite)
  file:close()
end

-- ---------------------------------------------------------------------------------------------
--27. Function joins paths of file system
-- ---------------------------------------------------------------------------------------------
--! @brief Return the path resulting from combining the individual paths
--! @args ... file paths
--! @usage Function usage example: commonFunctions:pathJoin("/tmp", "fs/mp/images/ivsu_cache", "ptu.json") returns "/tmp/fs/mp/images/ivsu_cache/ptu.json"
function commonFunctions:pathJoin(...)
  local args = {...}
  args[#args]  = string.sub(args[#args], -1) == "/" and string.sub(args[#args], 1, -2) or args[#args]
  return table.concat(args, "/")
end

function commonFunctions.getURLs(pService)
  local utils = require ('user_modules/utils')
  local function getPathToSDL()
    local pathToSDL = config.pathToSDL
    if pathToSDL:sub(-1) ~= '/' then
      pathToSDL = pathToSDL .. "/"
    end
    return pathToSDL
  end
  local fileName = getPathToSDL() .. commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  local tbl = utils.jsonFileToTable(fileName)
  local url = tbl.policy_table.module_config.endpoints[pService].default
  return url
end

--! @brief Acquire table with URLs for PTU from policy file
--! @param pPtFileName - json file with policy table structure
function commonFunctions:getUrlsTableFromPtFile(pPtFileName)
  if not pPtFileName then
    local function getPathToSDL()
      local pathToSDL = config.pathToSDL
      if pathToSDL:sub(-1) ~= '/' then
        pathToSDL = pathToSDL .. "/"
      end
      return pathToSDL
    end
    pPtFileName = getPathToSDL() .. commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  end
local pt = io.open(pPtFileName, "r")
    if pt == nil then
      error("PT file not found")
    end
  local ptString = pt:read("*all")
  pt:close()

  local ptTable = json.decode(ptString)
  return ptTable.policy_table.module_config.endpoints["0x07"]
end

--! @brief This function perform base validation of URLs from response of SDl.GetPolicyConfigurationData
--! @param expected_url_tbl - table with expected collection of URLs
--! @param actual_data - table which represents response of SDl.GetPolicyConfigurationData
function commonFunctions:validateUrls(pExpectedUrlTbl, pActualData)
  local endpoints = json.decode(pActualData.result.value[1])
  if endpoints then
    return compareValues(pExpectedUrlTbl, endpoints["0x07"], "urls")
  end
  return false, "Value JSON is not correct"
end

return commonFunctions
