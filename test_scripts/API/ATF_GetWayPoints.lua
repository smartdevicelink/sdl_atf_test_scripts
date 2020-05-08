-- ATF version: 2.2.1

--------------------------------------------------------------------------------------------------------
-- Precondition: deleting logs, policy table
local commonSteps = require('user_modules/shared_testcases/commonSteps')
commonSteps:DeleteLogsFileAndPolicyTable(false)

--------------------------------------------------------------------------------------------------------
Test = require('modules/connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection = require('file_connection')
local json = require('json')
local module = require('testbase')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local arrayIntergerParameterInResponse = require('user_modules/shared_testcases/testCasesForArrayIntegerParameterInResponse')
local stringParameterInResponse = require('user_modules/shared_testcases/testCasesForStringParameterInResponse')
local arrayStructParameterInResponse = require('user_modules/shared_testcases/testCasesForArrayStructParameterInResponse')
local doubleParameterInResponse = require('user_modules/shared_testcases/testCasesForDoubleParameterInResponse')
local imageParameterInResponse = require('user_modules/shared_testcases/testCasesForImageParameterInResponse')
local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameter')
----------------------------------------------------------------------------
-- User required files
require('user_modules/AppTypes')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "GetWayPoints" -- set request name
strMaxLengthFileName255 = string.rep("a", 251) .. ".png" -- set max length file name

local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. tostring(config.deviceMAC) .. "/")


---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. createUIParameters(RequestParams)
--3. verify_SUCCESS_Case(RequestParams)
--4. verify_INVALID_DATA_Case(RequestParams)
---------------------------------------------------------------------------------------------

--Create default request parameters
function Test:createRequest()

  return {
    wayPointType = "ALL"
  }
end

---------------------------------------------------------------------------------------------

--Create UI expected result based on parameters from the request
function Test:createUIParameters(RequestParams)
  local param = {}

  if RequestParams["wayPointType"] ~= nil then
    param["wayPointType"] = RequestParams["wayPointType"]

  end

  return param
end

----------------------------------------------------------------------------------------------

-- --Create HMI default response
local DefaultHMIResponse =
{
  LocationDetails =
  {
    coordinate =
    {
      latitudeDegrees = 1.1,
      longitudeDegrees = 1.1
    },
    locationName = "Hotel",
    addressLines =
    {
      "Hotel Bora",
      "Hotel 5 stars"
    },
    locationDescription = "VIP Hotel",
    phoneNumber = "Phone39300434",
    locationImage =
    {
      value ="icon.png",
      imageType ="DYNAMIC",
      fakeParam ="fakeParam"
    },
    searchAddress =
    {
      countryName = "countryName",
      countryCode = "countryCode",
      postalCode = "postalCode",
      administrativeArea = "administrativeArea",
      subAdministrativeArea = "subAdministrativeArea",
      locality = "locality",
      subLocality = "subLocality",
      thoroughfare = "thoroughfare",
      subThoroughfare = "subThoroughfare"
    }
  }
}

---------------------------------------------------------------------------------------------
--Create default response
function Test:createResponse()
  local response ={}
  response["wayPoints"] =
  {{

      coordinate =
      {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1
      },
      locationName = "Hotel",
      addressLines =
      {
        "Hotel Bora",
        "Hotel 5 stars"
      },
      locationDescription = "VIP Hotel",
      phoneNumber = "Phone39300434",
      locationImage =
      {
        value ="icon.png",
        imageType ="DYNAMIC",
      },
      searchAddress =
      {
        countryName = "countryName",
        countryCode = "countryCode",
        postalCode = "postalCode",
        administrativeArea = "administrativeArea",
        subAdministrativeArea = "subAdministrativeArea",
        locality = "locality",
        subLocality = "subLocality",
        thoroughfare = "thoroughfare",
        subThoroughfare = "subThoroughfare"
      }
  } }

  return response

end

---------------------------------------------------------------------------------------------

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request)

  --mobile side: sending the request
  local cid = self.mobileSession:SendRPC(APIName, Request)

  --hmi side: expect Navigation.GetWayPoints request
  local Response = self:createResponse()

  local temp = json.encode(Response)

  Request.appID = self.applications[config.application1.registerAppInterfaceParams.appName]
  EXPECT_HMICALL("Navigation.GetWayPoints", Request)
  :Do(function(_,data)
      --hmi side: sending response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
    end)

  --mobile side: expect the response
  local ExpectedResponse = commonFunctions:cloneTable(Response)
  ExpectedResponse["success"] = true
  ExpectedResponse["resultCode"] = "SUCCESS"
  EXPECT_RESPONSE(cid, ExpectedResponse)

end

---------------------------------------------------------------------------------------------
--This function is used to send default request and response with specific invalid data and verify GENERIC_ERROR resultCode
function Test:verify_GENERIC_ERROR_Response_Case(Response)

  --mobile side: sending the request
  local Request = self:createRequest()
  local cid = self.mobileSession:SendRPC(APIName, Request)

  Request.appID = self.applications[config.application1.registerAppInterfaceParams.appName]

  --hmi side: expect Navigation.GetWayPoints request
  EXPECT_HMICALL("Navigation.GetWayPoints", Request)
  :Do(function(_,data)
      --hmi side: sending response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
    end)

  --mobile side: expect the response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system" })
  :Timeout(11000)
end

---------------------------------------------------------------------------------------------
--This function is used to send default request and response with specific valid data and verify SUCCESS resultCode
function Test:verify_SUCCESS_Response_Case(Response)

  --mobile side: sending the request
  local Request = self:createRequest()
  local cid = self.mobileSession:SendRPC(APIName, Request)

  Request.appID = self.applications[config.application1.registerAppInterfaceParams.appName]

  --hmi side: expect Navigation.GetWayPoints request
  EXPECT_HMICALL("Navigation.GetWayPoints", Request)
  :Do(function(_,data)
      --hmi side: sending response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
    end)

  --mobile side: expect the response
  local ExpectedResponse = commonFunctions:cloneTable(Response)
  ExpectedResponse["success"] = true
  ExpectedResponse["resultCode"] = "SUCCESS"
  EXPECT_RESPONSE(cid, ExpectedResponse)

end

---------------------------------------------------------------------------------------------

--This function sends a request from mobile with INVALID_DATA and verifys result on mobile.
function Test:verify_INVALID_DATA_Case(RequestParams)
  local temp = json.encode(RequestParams)
  local cid = 0
  if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then
    temp = string.gsub(temp, "{}", "[]")
    temp = string.gsub(temp, "{{}}", "[{}]")

    if string.find(temp, "\"address\":%[%]") ~= nil then
      temp = string.gsub(temp, "\"address\":%[%]", "\"address\":{}")
    end

    self.mobileSession.correlationId = self.mobileSession.correlationId + 1

    cid = self.mobileSession.correlationId

    local msg =
    {
      serviceType = 7,
      frameInfo = 0,
      rpcType = 0,
      rpcFunctionId = 41,
      rpcCorrelationId = cid,
      payload = temp
    }
    self.mobileSession:Send(msg)
  else
    --mobile side: sending GetWayPoints request
    cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)
  end

  --mobile side: expect GetWayPoints response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

--1. Activate application
commonSteps:ActivationApp()

--2. Update policy to allow request
policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"})

-------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------
--Requirement id in JIRA:
-- APPLINK-21532
-- APPLINK-21892
-- APPLINK-24150
-- APPLINK-16739
-- APPLINK-21516
-- APPLINK-21519
-- APPLINK-21521
-- APPLINK-21884
-----------------------------------------------------------------------------------------------
--Common Test cases:
--1. Positive cases (check with too values of WayPointType)
--2. IsMissed
--3. IsWrongTypeData
--4. IsNoneExistenValue
--5. IsEmpty: without wayPointType
-----------------------------------------------------------------------------------------------
-- <param name="wayPointType" type="WayPointType" defvalue="ALL" mandatory="true">
-----------------------------------------------------------------------------------------------
-- NhungTT was updated this testing block to cover APPLINK-24150 and APPLINK-24149

local WaypoinType = {
						"ALL",
						"DESTINATION"
					}

local Request = {wayPointType = "ALL"}

enumerationParameter:verify_Enum_String_Parameter(Request, {"wayPointType"}, WaypoinType, true)

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA:
-- APPLINK-16739
-- APPLINK-4518

--Verification criteria:
-- In case the request comes to SDL with wrong json syntax, SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
-- SDL must cut off the fake parameters from mobile requests

-----------------------------------------------------------------------------------------
--List of test cases for softButtons type parameter:
--1. InvalidJSON
--2. CorrelationIdIsDuplicated 
--3. FakeParams and FakeParameterIsFromAnotherAPI
-----------------------------------------------------------------------------------------------

local function SpecialRequestChecks()

  --Begin Test case NegativeRequestCheck
  --Description: Check negative request

  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup(self, "TestCaseGroupForGetWayPoints")

  --Begin Test case NegativeRequestCheck.1
  --Description: Invalid JSON

  function Test:GetWayPoints_InvalidJSON()

    self.mobileSession.correlationId = self.mobileSession.correlationId + 1

    local msg =
    {
      serviceType = 7,
      frameInfo = 0,
      rpcType = 0,
      rpcFunctionId = 41,
      rpcCorrelationId = self.mobileSession.correlationId,
      --<<-- Missing :
      payload = '{"wayPointType" "ALL"}'
    }
    self.mobileSession:Send(msg)

    self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })

  end

  --End Test case NegativeRequestCheck.1

  -----------------------------------------------------------------------------------------

  --Begin Test case NegativeRequestCheck.2
  --Description: Check CorrelationId duplicate value
  --TODO: Expected result of this TC should be update when APPLINK-19834 is implementation

  function Test:GetWayPoints_CorrelationIdIsDuplicated()

    --mobile side: sending GetWayPoints request
    local cid = self.mobileSession:SendRPC("GetWayPoints",
      {
        wayPointType = "ALL"
      })

    --request from mobile side
    local msg =
    {
      serviceType = 7,
      frameInfo = 0,
      rpcType = 0,
      rpcFunctionId = 41,
      rpcCorrelationId = cid,
      payload = '{"wayPointType": "ALL"}'
    }

    --hmi side: expect Navigation.GetWayPoints request
    EXPECT_HMICALL("Navigation.GetWayPoints",
      {
        wayPointType = "ALL"
      })
    :Do(function(exp,data)
        if exp.occurences == 1 then
          self.mobileSession:Send(msg)
        end
        --hmi side: sending Navigation.GetWayPoints response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    :Times(2)

    --response on mobile side
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
    :Times(2)
  end

  --End Test case NegativeRequestCheck.2

  -----------------------------------------------------------------------------------------

  --Begin Test case NegativeRequestCheck.3
  --Description: Fake parameters check

  --Begin Test case NegativeRequestCheck.3.1
  --Description: With fake parameters (SUCCESS)
  function Test:GetWayPoints_WithFakeParam()

    local param = {
      wayPointType = "ALL",
      fakeParam ="fakeParam"
    }

    --mobile side: sending GetWayPoints request
    local cid = self.mobileSession:SendRPC("GetWayPoints", param)

    param.fakeParam = nil
    UIParams = self:createUIParameters(param)
    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :ValidIf(function(_,data)
        if data.params.fakeParam then
          print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")
          return false
        else
          return true
        end
      end)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  end

  --End Test case NegativeRequestCheck.3.1

  -----------------------------------------------------------------------------------------

  --Begin Test case NegativeRequestCheck.3.2
  --Description: Check processing response with fake parameters from another API
  function Test:GetWayPoints_ParamsAnotherRequest()
    --mobile side: sending GetWayPoints request
    local param = {
      wayPointType = "ALL",
      cmdID = 1005,
    }

    local cid = self.mobileSession:SendRPC("GetWayPoints", param)

    param.cmdID = nil

    --hmi side: expect the request
    UIParams = self:createUIParameters(param)
    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :ValidIf(function(_,data)
        if data.params.cmdID then
          print(" \27[36m SDL re-sends cmdID parameters to HMI \27[0m")
          return false
        else
          return true
        end
      end)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  end
  --End Test case NegativeRequestCheck.3.2
  --End Test case NegativeRequestCheck.3
end
SpecialRequestChecks()

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------
-- Requirement:
-- -- 1. APPLINK-14551: SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
-- -- 2. APPLINK-25599: [GENERIC_ERROR] Response from HMI contains wrong characters
-- -- 3. APPLINK-25602: [GENERIC_ERROR] Response from HMI contains empty String param
-- -- 4. APPLINK-9736: SDL must ignore the invalid notifications from HMI
------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
--Parameter 1: resultCode
-----------------------------------------------------------------------------------------------
--List of test cases:
--1. IsMissed
--2. IsValidValues
--3. IsNotExist
--4. IsEmpty
--5. IsWrongType
-----------------------------------------------------------------------------------------------

local function verify_resultCode_parameter()

  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup(self, "TestCaseGroupForResultCodeParameter: resultCode")
  -----------------------------------------------------------------------------------------

  --1. IsMissed
  Test[APIName.."_Response_resultCode_IsMissed"] = function(self)

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        --self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
        self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.GetWayPoints"}}')
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
    :Timeout(11000)
  end
  -----------------------------------------------------------------------------------------

  --2. IsValidValue
  local resultCodes = {
    {resultCode = "INVALID_DATA", success = false},
    {resultCode = "OUT_OF_MEMORY", success = false},
    {resultCode = "TOO_MANY_PENDING_REQUESTS", success = false},
    {resultCode = "APPLICATION_NOT_REGISTERED", success = false},
    {resultCode = "GENERIC_ERROR", success = false},
    {resultCode = "REJECTED", success = false},
    {resultCode = "DISALLOWED", success = false},
  }

  for i =1, #resultCodes do

    Test[APIName.."_resultCode_IsValidValues_" .. resultCodes[i].resultCode .."_SendResponse"] = function(self)

      --mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

      --hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)

      EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
      :Do(function(_,data)
          --hmi side: sending the response
          self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, {})
        end)

      --mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})

    end
    -----------------------------------------------------------------------------------------

    Test[APIName.."_resultCode_IsValidValues_" .. resultCodes[i].resultCode .."_SendError"] = function(self)

      --mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

      --hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)

      EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
      :Do(function(_,data)
          --hmi side: sending the response
          self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "info")
        end)

      --mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})

    end
  end
end
-----------------------------------------------------------------------------------------

--3. IsNotExist
--4. IsEmpty
--5. IsWrongType

local testData = {
  {value = "ANY", name = "IsNotExist"},
  {value = "", name = "IsEmpty"},
  {value = 123, name = "IsWrongType"},
}

for i =1, #testData do

  Test[APIName.."_resultCode_" .. testData[i].name .."_SendResponse"] = function(self)

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:SendResponse(data.id, data.method, testData[i].value, {})
      end)

    --mobile side: expect GetWayPoints response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
    :Timeout(11000)
  end
  -----------------------------------------------------------------------------------------

  Test[APIName.."_resultCode_" .. testData[i].name .."_SendError"] = function(self)

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:SendError(data.id, data.method, testData[i].value)
      end)

    --mobile side: expect GetWayPoints response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
    :Timeout(11000)
  end
end

verify_resultCode_parameter()

-----------------------------------------------------------------------------------------------
--Parameter 2: method
-----------------------------------------------------------------------------------------------
--List of test cases:
--1. IsMissed
--2. IsValidValue
--3. IsNotExist
--4. IsEmpty
--5. IsWrongType
--6. IsInvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------

local function verify_method_parameter()

  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup(self, "TestCaseGroupForMethodParameter: method")
  -----------------------------------------------------------------------------------------

  --1. IsMissed
  Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR"] = function(self)

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')

      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
    :Timeout(11000)
  end
  -----------------------------------------------------------------------------------------

  --2. IsValidValue
  Test[APIName.."_Response_method_IsValidValue_SendResponse"] = function(self)

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

    --mobile side: expect SetGlobalProperties response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

  end
  -----------------------------------------------------------------------------------------

  Test[APIName.."_Response_method_IsValidValue_SendError"] = function(self)

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "info")
      end)

    --mobile side: expect GetWayPoints response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "info"})
    :Timeout(11000)
  end
  -----------------------------------------------------------------------------------------

  --3. IsNotExist
  --4. IsEmpty
  --5. IsWrongType
  --6. IsInvalidCharacter - \n, \t
  local Methods = {
    {method = "ANY", name = "IsNotExist"},
    {method = "", name = "IsEmpty"},
    {method = 123, name = "IsWrongType"},
    {method = "a\nb", name = "IsInvalidCharacter_NewLine"},
    {method = "a\tb", name = "IsInvalidCharacter_Tab"}}

  for i =1, #Methods do

    Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendResponse"] = function(self)

      --mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

      --hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)

      EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
      :Do(function(_,data)
          --hmi side: sending the response
          self.hmiConnection:SendResponse(data.id, Methods[i].method, "SUCCESS", {})

        end)

      --mobile side: expect GetWayPoints response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
      :Timeout(11000)
    end
    -----------------------------------------------------------------------------------------

    Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendError"] = function(self)

      --mobile side: sending the request
      local RequestParams = Test:createRequest()
      local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

      --hmi side: expect the request
      UIParams = self:createUIParameters(RequestParams)

      EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
      :Do(function(_,data)
          --hmi side: sending the response
          self.hmiConnection:SendError(data.id, Methods[i].method, "UNSUPPORTED_RESOURCE", "info")

        end)

      --mobile side: expect GetWayPoints response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
      :Timeout(11000)
    end
  end
end

verify_method_parameter()

-- -----------------------------------------------------------------------------------------------
-- --Parameter 3: info Not implemented yet: APPLINK-14551
-- -----------------------------------------------------------------------------------------------
-- --List of test cases:
-- --1. IsMissed
-- --2. IsLowerBound
-- --3. IsUpperBound
-- --4. IsOutUpperBound
-- --5. IsEmpty/IsOutLowerBound
-- --6. IsWrongType
-- --7. InvalidCharacter - \n, \t
-- -----------------------------------------------------------------------------------------------

-- local function verify_info_parameter()

-- --Print new line to separate new test cases group
-- commonFunctions:newTestCasesGroup(self, "TestCaseGroupForInfoParameter: info")

-- -----------------------------------------------------------------------------------------

-- --1. IsMissed
-- Test[APIName.."_info_IsMissed_SendResponse"] = function(self)

-- --mobile side: sending the request
-- local RequestParams = Test:createRequest()
-- local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

-- --hmi side: expect the request
-- UIParams = self:createUIParameters(RequestParams)

-- EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
-- :Do(function(_,data)
-- --hmi side: sending the response
-- self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
-- end)

-- --mobile side: expect the response
-- EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
-- :ValidIf (function(_,data)
-- if data.payload.info then
-- print(" \27[32m SDL resends invalid info parameter to mobile app. \27[0m")
-- return false
-- else
-- return true
-- end
-- end)
-- end
-- -----------------------------------------------------------------------------------------

-- Test[APIName.."_info_IsMissed_SendError"] = function(self)

-- --mobile side: sending the request
-- local RequestParams = Test:createRequest()
-- local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

-- --hmi side: expect the request
-- UIParams = self:createUIParameters(RequestParams)

-- EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
-- :Do(function(_,data)
-- --hmi side: sending the response
-- self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR")
-- end)

-- --mobile side: expect the response
-- -- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
-- EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
-- :ValidIf (function(_,data)
-- if data.payload.info then
-- print(" \27[32m SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\" \27[0m")
-- return false
-- else
-- return true
-- end
-- end)
-- end
-- -----------------------------------------------------------------------------------------

-- --2. IsLowerBound
-- --3. IsUpperBound
-- local testData = {
-- {value = "a", name = "IsLowerBound"},
-- {value = commonFunctions:createString(1000), name = "IsUpperBound"}}

-- for i =1, #testData do
-- Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)

-- --mobile side: sending the request
-- local RequestParams = Test:createRequest()
-- local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

-- --hmi side: expect the request
-- UIParams = self:createUIParameters(RequestParams)

-- EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
-- :Do(function(_,data)
-- --hmi side: sending the response
-- self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = testData[i].value})
-- end)

-- --mobile side: expect GetWayPoints response
-- EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = testData[i].value})
-- end
-- -----------------------------------------------------------------------------------------

-- Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)

-- --mobile side: sending the request
-- local RequestParams = Test:createRequest()
-- local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

-- --hmi side: expect the request
-- UIParams = self:createUIParameters(RequestParams)

-- EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
-- :Do(function(_,data)
-- --hmi side: sending the response
-- self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
-- end)

-- --mobile side: expect GetWayPoints response
-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = testData[i].value})
-- end
-- end
-- -----------------------------------------------------------------------------------------

-- --4. IsOutUpperBound
-- Test[APIName.."_info_IsOutUpperBound_SendResponse"] = function(self)

-- local infoMaxLength = commonFunctions:createString(1000)

-- --mobile side: sending the request
-- local RequestParams = Test:createRequest()
-- local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

-- --hmi side: expect the request
-- UIParams = self:createUIParameters(RequestParams)

-- EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
-- :Do(function(_,data)
-- --hmi side: sending the response
-- self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = infoMaxLength .. "1"})
-- end)

-- --mobile side: expect SetGlobalProperties response
-- EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = infoMaxLength})
-- end
-- -----------------------------------------------------------------------------------------

-- Test[APIName.."_info_IsOutUpperBound_SendError"] = function(self)

-- local infoMaxLength = commonFunctions:createString(1000)

-- --mobile side: sending the request
-- local RequestParams = Test:createRequest()
-- local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

-- --hmi side: expect the request
-- UIParams = self:createUIParameters(RequestParams)

-- EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
-- :Do(function(_,data)
-- --hmi side: sending the response
-- self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMaxLength .."1")
-- end)

-- --mobile side: expect GetWayPoints response
-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})
-- end
-- -----------------------------------------------------------------------------------------

-- --5. IsEmpty/IsOutLowerBound
-- --6. IsWrongType
-- --7. InvalidCharacter - \n, \t, white spaces only

-- local testData = {
-- {value = "", name = "IsEmpty_IsOutLowerBound"},
-- {value = 123, name = "IsWrongType"},
-- {value = "a\nb", name = "IsInvalidCharacter_NewLine"},
-- {value = "a\tb", name = "IsInvalidCharacter_Tab"},
-- {value = " ", name = "WhiteSpacesOnly"}}

-- for i =1, #testData do

-- Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)

-- --mobile side: sending the request
-- local RequestParams = Test:createRequest()
-- local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

-- --hmi side: expect the request
-- UIParams = self:createUIParameters(RequestParams)

-- EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
-- :Do(function(_,data)
-- --hmi side: sending the response
-- self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = testData[i].value})
-- end)

-- --mobile side: expect GetWayPoints response
-- EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
-- :ValidIf (function(_,data)
-- if data.payload.info then
-- print(" \27[32m SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\" \27[0m")
-- return false
-- else
-- return true
-- end
-- end)
-- end
-- -----------------------------------------------------------------------------------------

-- Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)

-- --mobile side: sending the request
-- local RequestParams = Test:createRequest()
-- local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

-- --hmi side: expect the request
-- UIParams = self:createUIParameters(RequestParams)

-- EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
-- :Do(function(_,data)
-- --hmi side: sending the response
-- self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
-- end)

-- --mobile side: expect GetWayPoints response
-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
-- :ValidIf (function(_,data)
-- if data.payload.info then
-- print(" \27[32m SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\" \27[0m")
-- return false
-- else
-- return true
-- end
-- end)
-- end
-- end
-- end

-- verify_info_parameter()

-------------------------------------------------------------------------------------------------
--Parameter 4: correlationID
-----------------------------------------------------------------------------------------------
--List of test cases:
--1. CorrelationIDMissing
--2. CorrelationIDWrongType
--3. CorrelationIDNotExisted
--4. CorrelationIDNegative
--5. CorrelationIDNull
-----------------------------------------------------------------------------------------------

local function verify_correlationID_parameter()

  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test Suit For Parameter: CorrelationID")

  -----------------------------------------------------------------------------------------

  --1. CorrelationIDMissing
  Test[APIName.."_Response_CorrelationIDMissing"] = function(self)

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"Navigation.GetWayPoints", "code":0}}')
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
    :Timeout(11000)
  end
  -----------------------------------------------------------------------------------------

  --2. CorrelatioIDWrongType
  Test[APIName.."_Response_CorrelationIDWrongType"] = function(self)
    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {})
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
    :Timeout(11000)
  end
  -----------------------------------------------------------------------------------------

  --3. CorrelationIDNotExisted
  Test[APIName.."_Response_CorrelationIDNotExisted"] = function(self)

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:SendResponse(9999, data.method, "SUCCESS", {})
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
    :Timeout(11000)
  end
  -----------------------------------------------------------------------------------------

  --4. CorrelationIDNegative
  Test[APIName.."_Response_CorrelationIDNegative"] = function(self)

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {})
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
    :Timeout(11000)
  end

  -----------------------------------------------------------------------------------------
  --5. CorrelationIDNull
  Test[APIName.."_Response_CorrelationIDNull"] = function(self)

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        self.hmiConnection:Send('"id":null,"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.SendLocation"}}')
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
    :Timeout(11000)
  end
end

verify_correlationID_parameter()

---------------------------------------------------------------------------------------------
-- NhungTT was updated below test cases to cover APPLINK-25599 and APPLINK-25602

local Response = {}

local Response = {}

Response["wayPoints"] =
{{

    coordinate =
    {
      latitudeDegrees = 1.1,
      longitudeDegrees = 1.1
    },
    locationName = "Hotel",
    addressLines =
    {
      "Hotel Bora"
    },
    locationDescription = "VIP Hotel",
    phoneNumber = "Phone39300434",
    locationImage =
    {
      value ="icon.png",
      imageType ="DYNAMIC",
    },
    searchAddress =
    {
      countryName = "countryName",
      countryCode = "countryCode",
      postalCode = "postalCode",
      administrativeArea = "administrativeArea",
      subAdministrativeArea = "subAdministrativeArea",
      locality = "locality",
      subLocality = "subLocality",
      thoroughfare = "thoroughfare",
      subThoroughfare = "subThoroughfare"
    }

  }
}

-- Check different conditions for array of wayPoints
-- -- <param name="wayPoints" type="LocationDetails" mandatory="false" array="true" minsize="1" maxsize="10">	
------------------------------------------------------------------------------------------------------------------------------------
Test["GetWayPoints_Response_Without_Parameters_In_WayPoints_SUCCESS"] = function(self)

  local Response = {}
  Response["wayPoints"] =
  {{}}

  self:verify_SUCCESS_Response_Case(Response)

end
local Struct = Response.wayPoints[1]

arrayStructParameterInResponse:verify_Array_Struct_Parameter(Response, {"wayPoints"}, {1,10}, Struct, false)

-- Check different conditionds for locationName string parameter
-- -- <param name="locationName" type="String" maxlength="500" mandatory="false">
------------------------------------------------------------------------------------------------------------------------------------
stringParameterInResponse:verify_String_Parameter(Response, {"wayPoints", 1, "locationName"}, {1, 500}, false,false)

-- Check different conditionds for phoneNumber string parameter
-- -- <param name="phoneNumber" type="String" maxlength="500" mandatory="false">
------------------------------------------------------------------------------------------------------------------------------------
stringParameterInResponse:verify_String_Parameter(Response, {"wayPoints", 1, "phoneNumber"}, {1, 500}, false,false)

-- Check different conditionds for locationDescription string parameter
-- -- <param name="locationDescription" type="String" maxlength="500" mandatory="false">
------------------------------------------------------------------------------------------------------------------------------------
stringParameterInResponse:verify_String_Parameter(Response, {"wayPoints", 1, "locationDescription"}, {1, 500}, false,false)

-- Check for Double latitudeDegrees and longitudeDegrees parameters in coordinate structure
-- -- <param name="coordinate" type="Coordinate" mandatory="false"> 
-- -- -- <param name="latitudeDegrees" minvalue="-90" maxvalue="90" type="Double" mandatory="true"> 
-- -- -- <param name="longitudeDegrees" minvalue="-180" maxvalue="180" type="Double" mandatory="true">
---------------------------------------------------------------------------------------------------------------------------------
local Boundary_longitudeDegrees = {-180, 180}
local Boundary_latitudeDegrees = {-90, 90}

commonFunctions:newTestCasesGroup(self, "Test Suit For Paramameter: coordinate")

-- Coordinate IsWrongDataType
commonFunctions:TestCaseForResponse(self, Response, {"wayPoints", 1, "coordinate"}, "IsWrongDataType", 123, "GENERIC_ERROR")

-- Coordiate IsEmpty
commonFunctions:TestCaseForResponse(self, Response, {"wayPoints", 1, "coordinate"}, "IsEmpty", {}, "GENERIC_ERROR")

-- Check for latitudeDegress
doubleParameterInResponse:verify_Double_Parameter(Response, {"wayPoints", 1, "coordinate", "latitudeDegrees"}, Boundary_latitudeDegrees, true)

-- Check for longtitudeDegress
doubleParameterInResponse:verify_Double_Parameter(Response, {"wayPoints", 1, "coordinate", "longitudeDegrees"}, Boundary_longitudeDegrees, true)

-- Check for value and imageType parameters of locationImage structure
---------------------------------------------------------------------------------------------------------------------------------
local strMaxLengthFileName255 = string.rep("a", 251) .. ".png" -- set max length file name
imageParameterInResponse:verify_Image_Parameter(Response, {"wayPoints", 1, "locationImage"}, {"a", strMaxLengthFileName255}, false)

-- Check different conditionds for addressLines string parameter
-- -- <param name="addressLines" type="String" maxlength="500" minsize="0" maxsize="4" array="true" mandatory="false">
------------------------------------------------------------------------------------------------------------------------------------

stringParameterInResponse:verify_String_Parameter(Response, {"wayPoints", 1, "addressLines", 1}, {1, 500}, nil,false)

local Struct_1 = Response.wayPoints[1].addressLines[1]
arrayStructParameterInResponse:verify_Array_Struct_Parameter(Response, {"wayPoints", 1, "addressLines"}, {0, 4}, Struct_1, false)

-- Check for strings elements of searchAddress parameter
-- -- <param name="searchAddress" type="OASISAddress" mandatory="false">
-- -- type="OASISAddress":
-- -- -- <param name="countryName" minlength="0" maxlength="200" type="String" mandatory="false">	
-- -- -- <param name="countryCode" minlength="0" maxlength="50" type="String" mandatory="false">	
-- -- -- <param name="postalCode" minlength="0" maxlength="16" type="String" mandatory="false">	
-- -- -- <param name="administrativeArea" minlength="0" maxlength="200" type="String" mandatory="false">	
-- -- -- <param name="subAdministrativeArea" minlength="0" maxlength="200" type="String" mandatory="false">	
-- -- -- <param name="locality" minlength="0" maxlength="200" type="String" mandatory="false">	
-- -- -- <param name="subLocality" minlength="0" maxlength="200" type="String" mandatory="false">	
-- -- -- <param name="thoroughfare" minlength="0" maxlength="200" type="String" mandatory="false">	
-- -- -- <param name="subThoroughfare" minlength="0" maxlength="200" type="String" mandatory="false">	

-----------------------------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup(self, "Test Suit For Paramameter: searchAddress")
  
-- searchAddress IsWrongType
commonFunctions:TestCaseForResponse(self, Response, {"wayPoints", 1, "searchAddress"}, "IsWrongDataType", 123, "GENERIC_ERROR")

-- searchAddress IsEmpty
commonFunctions:TestCaseForResponse(self, Response, {"wayPoints", 1, "searchAddress"}, "IsEmpty", {}, "SUCCESS")

local Response = {}

Response["wayPoints"] =
{
	{
		phoneNumber = "Phone39300434",
		searchAddress =
		{

		}
	}
}
local Struct = Response.wayPoints[1].searchAddress
local testData = {"countryName",
  "countryCode",
  "postalCode",
  "administrativeArea",
  "subAdministrativeArea",
  "locality",
  "subLocality",
  "thoroughfare",
  "subThoroughfare"
}
local upperBound = {200, 50, 16, 200, 200, 200, 200, 200, 200}

-- Check for all sub-params
for i =1, #testData do
  stringParameterInResponse:verify_String_Parameter(Response, {"wayPoints", 1, "searchAddress", testData[i]}, {0, upperBound[i]}, nil,false)
end

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------
--Requirement: APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI
--Requirement: APPLINK-21610: p3: GetWayPoints-No active route If there is no active route set then the system shall provide a response of SUCCESS with Number Of Waypoints set to 0.
--Requirement: APPLINK-25599: Response from HMI contains wrong characters (not implemented APPLINK-24135)
--Requirement: APPLINK-25602: Response from HMI contains empty String param (not implemented APPLINK-24135)
-----------------------------------------------------------------------------------------------

--List of test cases for:
--1. InvalidJsonSyntax
--2. InvalidStructure
--2. DuplicatedCorrelationId
--3. FakeParams and FakeParameterIsFromAnotherAPI
--4. MissedAllPArameters
--5. NoResponse
--6. SeveralResponsesToOneRequest with the same and different resultCode 
-----------------------------------------------------------------------------------------------

local function SpecialResponseChecks()

  --Begin Test case NegativeResponseCheck
  --Description: Check all negative response cases

  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup(self, "NewTestCasesGroupForNegativeResponseCheck")

  --Begin Test case NegativeResponseCheck.1
  --Description: Invalid JSON

  --ToDo: Check after APPLINK-14765 is resolved

  function Test:GetWayPoints_InvalidJsonSyntaxResponse()

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        --":" is changed by ";" after {"id"
        --self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.GetWayPoints", "code":0}}')
        self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.GetWayPoints", "code":0}}')
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
  end
  --End Test case NegativeResponseCheck.1
  
  -----------------------------------------------------------------------------------------

  --Begin Test case NegativeResponseCheck.2
  --Description: Invalid structure of response

  function Test:GetWayPoints_InvalidStructureResponse()

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending the response
        --self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
        self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"Navigation.GetWayPoints"}}')
      end)

    --mobile side: expect response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
    :Timeout(11000)
  end
  --End Test case NegativeResponseCheck.2

  -----------------------------------------------------------------------------------------

  --Begin Test case NegativeResponseCheck.3
  --Description: Check processing response with fake parameters

  --Requirement id in JAMA/or Jira ID: APPLINK-14765
  --Verification criteria: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

  --Begin Test case NegativeResponseCheck.3.1
  --Description: Parameter is not from API
   --[[ToDo: Check after APPLINK-14765 is resolved
  function Test:GetWayPoints_FakeParamsInResponse()

    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(exp,data)
        --hmi side: sending the response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    :ValidIf (function(_,data)
        if data.payload.fake then
          print(" \27[32m SDL resend fake parameter to mobile app \27[0m")
          return false
        else
          return true
        end
      end)
  end
  --End Test case NegativeResponseCheck.3.1

  -----------------------------------------------------------------------------------------

  --Begin Test case NegativeResponseCheck.3.2
  --Description: Parameter is not from another API
  function Test:GetWayPoints_AnotherParameterInResponse()
    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(exp,data)
        --hmi side: sending the response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    :ValidIf (function(_,data)
        if data.payload.sliderPosition then
          print(" \27[32m SDL resend fake parameter to mobile app \27[0m")
          return false
        else
          return true
        end
      end)]]
  end
  --End Test case NegativeResponseCheck.3.2
  --End Test case NegativeResponseCheck.3

  -----------------------------------------------------------------------------------------

  --Begin NegativeResponseCheck.4
  --Description: Check processing response without all parameters

  function Test:GetWayPoints_Response_MissedAllPArameters()
    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    UIParams = self:createUIParameters(RequestParams)

    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(_,data)
        --hmi side: sending Navigation.GetWayPoints response
        --self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.GetWayPoints", "code":0}}')
        self.hmiConnection:Send('{}')
      end)

    --mobile side: expect the response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
  end
  
  --End NegativeResponseCheck.4

  -----------------------------------------------------------------------------------------

  --Begin Test case NegativeResponseCheck.5
  --Description: Request without responses from HMI


  function Test:GetWayPoints_NoResponse()
    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)

    --mobile side: expect GetWayPoints response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
    :Timeout(11000)
  end
  --End NegativeResponseCheck.5

  -----------------------------------------------------------------------------------------
--[[ ToDo: Check after APPLINK-19834. ATF functionality to send messages with the same correlatioID is not implemented yet
  --Begin Test case NegativeResponseCheck.6
  --Description: Several response to one request

  function Test:GetWayPoints_SeveralResponsesToOneRequest()
    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(exp,data)
        --hmi side: sending the response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
        self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
      end)

    --mobile side: expect response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  end
  --End Test case NegativeResponseCheck.6

  -----------------------------------------------------------------------------------------
  --TODO: ToDo: Check after APPLINK-19834. ATF functionality to send messages with the same correlatioID is not implemented yet
  --Begin Test case NegativeResponseCheck.7
  --Description: Wrong response to correct correlationID
  function Test:GetWayPoints_WrongResponse()
    --mobile side: sending the request
    local RequestParams = Test:createRequest()
    local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

    --hmi side: expect the request
    local UIParams = self:createUIParameters(RequestParams)
    EXPECT_HMICALL("Navigation.GetWayPoints", UIParams)
    :Do(function(exp,data)
        --hmi side: sending the response
        self.hmiConnection:Send('{"error":{"code":4,"message":"GetWayPoints is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.GetWayPoints"}}')
      end)

    --mobile side: expect response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from system"})
    :Timeout(11000)
  end
  --End Test case NegativeResponseCheck.7
  --End Test case NegativeResponseCheck

end

ecialResponseChecks()
]]

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Description: TC's checks SDL behaviour by processing
-- different request sequence with timeout
-- with emulating of user's actions

--Check reseting timeout from HMI by notification OnResetTimeOut for responding APPLINK-21890
----------------------------------------------------------------------------------------------
function Test:GetWayPoints_OnResetTimeout()

  --mobile side: sending the request
  local Request = {
    wayPointType = "ALL",

  }

  local cid = self.mobileSession:SendRPC("GetWayPoints", Request)

  --hmi side: expect the request
  local UIRequest = Request
  UIRequest.appID = self.applications[config.application1.registerAppInterfaceParams.appName]

  EXPECT_HMICALL("Navigation.GetWayPoints", UIRequest)
  :Do(function(_,data)

      local function SendOnResetTimeout()
        self.hmiConnection:SendNotification("UI.OnResetTimeout", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], methodName = "Navigation.GetWayPoints"})
      end

      --send UI.OnResetTimeout notification after 8 seconds
      RUN_AFTER(SendOnResetTimeout, 8000)

      local function sendReponse()

        --hmi side: sending response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

      end
      RUN_AFTER(sendReponse, 15000)

    end)

  --mobile side: expect the response
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  :Timeout(16000)
end

--Check GetWayPoints Response For Each App APPLINK-21890
--------------------------------------------------------------------------------------------
--[[ Defect APPLINK-26784. Check after fix
-- Precondition Openning new session
function Test:Precondition_SecondSession()
  --mobile side: start new session
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
end

function Test:Precondition_AppRegistrationInSecondSession()
  --mobile side: start new
  self.mobileSession1:StartService(7)
  :Do(function()
      local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
        {
          syncMsgVersion =
          {
            majorVersion = 3,
            minorVersion = 0
          },
          appName = "Test Application2",
          isMediaApplication = true,
          languageDesired = 'EN-US',
          hmiDisplayLanguageDesired = 'EN-US',
          appHMIType = { "DEFAULT" },
          appID = "456"
        })

      --hmi side: expect BasicCommunication.OnAppRegistered request
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        {
          application =
          {
            appName = "Test Application2"
          }
        })
      :Do(function(_,data)
          self.applications["Test Application2"] = data.params.application.appID
        end)

      --mobile side: expect response
      self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
      :Timeout(2000)

      self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE",systemContext = "MAIN"})
    end)
end

function Test:Precondition_ActivateSecondApp()
  --hmi side: sending SDL.ActivateApp request
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application2"]})

  --hmi side: expect SDL.ActivateApp response
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
 
        if data.result.isSDLAllowed ~= true then
        local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})

        --hmi side: expect SDL.GetUserFriendlyMessage message response
        --TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
        EXPECT_HMIRESPONSE(RequestId)
        :Do(function(_,data)
            --hmi side: send request SDL.OnAllowSDLFunctionality
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

            --hmi side: expect BasicCommunication.ActivateApp request
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,data)
                --hmi side: sending BasicCommunication.ActivateApp response
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            :Times(AnyNumber())
          end)

      end
    end)

  --mobile side: expect notification from 2 app
  self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

end

function Test:GetWayPointse_Response_For_Each_App()
  
      --mobile side: sending the request
      local Request = {wayPointType = "ALL"}
      local Request2 = {wayPointType = "DESTINATION"}
      
      local cid = self.mobileSession:SendRPC("GetWayPoints", Request)
      local cid2 = self.mobileSession1:SendRPC("GetWayPoints", Request2)


      EXPECT_HMICALL("Navigation.GetWayPoints", UIRequest, UIRequest2)
      :Do(function(_,data)
         --hmi side: sending response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
      :Times(2)

      self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
      self.mobileSession1:ExpectResponse(cid2, { success = true, resultCode = "SUCCESS"})
    
end ]]

-- Check IN_USE result code if the same app sends GetWayPoints request during another GetWayPoints request in progress on HMI
-----------------------------------------------------------------------------------------------------------------------------------
function Test:GetWayPoints_IN_USE_ResultCode_If_Another_GetWayPoints_Is_Active_On_HMI_Same_App()
  
      --mobile side: sending the request
      local Request = {
                wayPointType = "ALL",

              }
      
      local cid = self.mobileSession:SendRPC("GetWayPoints", Request)

      local Request2 = {
                wayPointType = "DESTINATION"
              }
              
      --hmi side: expect the request
      local UIRequest = Request
      UIRequest.appID = self.applications[config.application1.registerAppInterfaceParams.appName]
      local UIRequest2 = Request2
      UIRequest2.appID = self.applications[config.application1.registerAppInterfaceParams.appName]
      EXPECT_HMICALL("Navigation.GetWayPoints", UIRequest, UIRequest2)
      :Do(function(_,data)
        
        if exp.occurences == 1 then
        
          local function sendSecondRequest()        
            local cid2 = self.mobileSession:SendRPC("GetWayPoints", Request2)

            EXPECT_RESPONSE(cid2, { success = false, resultCode = "IN_USE"})
          end
          RUN_AFTER(sendSecondRequest, 1000)
          
          local function sendReponse()
            
            --hmi side: sending response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
            
          end
          RUN_AFTER(sendReponse, 2000)
          
        else
          --hmi side: sending response
          self.hmiConnection:SendResponse(data.id, data.method, "IN_USE", {})
        end
            
      end)
      :Times(2)

      
      --mobile side: expect the response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
    
  end

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Requirement id in Jira: APPLINK-24151
--Verification criteria:
--[[
--An RPC request is not allowed by the backend. Policies Manager validates it as "disallowed".
1) SDL must support the following result-codes:

2) USER_DISALLOWED -
SDL must return 'user_dissallowed, success:false' in case the GetWayPoints RPC is included to the group disallowed by the user.

--]]
local function ResultCodeChecks()

--Print new line to separate new test cases group
commonFunctions:newTestCasesGroup(self, "NewTestCasesGroupForResultCodeChecks")

--Begin Test case ResultCodeChecks.1
--Description: Check resultCode APPLICATION_NOT_REGISTERED

--Precondition
function Test:Precondition_CreationNewSession()
-- Connected expectation
self.mobileSession2 = mobile_session.MobileSession(
  self,
  self.mobileConnection
)
end

function Test:GetWayPoints_resultCode_APPLICATION_NOT_REGISTERED()

--mobile side: sending the request
local RequestParams = Test:createRequest()
local cid = self.mobileSession2:SendRPC("GetWayPoints", RequestParams)

--mobile side: expect response
self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED"})
end
--End Test case ResultCodeChecks.1

-----------------------------------------------------------------------------------------

--Begin Test case ResultCodeChecks.2
--Description: Check resultCode DISALLOWED

--Begin Test case ResultCodeChecks.2.1
--Description: Check resultCode DISALLOWED when HMI level is NONE

--Covered by test case GetWayPoints_HMIStatus_NONE

--End Test case ResultCodeChecks.2.1

-----------------------------------------------------------------------------------------

--Begin Test case ResultCodeChecks.2.2
--Description: Check resultCode DISALLOWED when request is not assigned to app
function Test:checkPolicyWhenAPIIsNotExist()

policyTable:checkPolicyWhenAPIIsNotExist()

--End Test case ResultCodeChecks.2.2
end
-----------------------------------------------------------------------------------------

--Begin Test case ResultCodeChecks.2.3
--Description: Check resultCode USER_DISALLOWED when request is assigned to app but user does not allow

--Is not applicable for GENIVI
function Test:checkPolicyWhenUserDisallowed ()
policyTable:checkPolicyWhenUserDisallowed({"FULL", "LIMITED", "BACKGROUND"})

--End Test case ResultCodeChecks.2.3
-- ]]
end
--End Test case ResultCodeChecks.2

end
ResultCodeChecks()

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

local function DifferentHMIlevelChecks()

--Print new line to separate new test cases group
commonFunctions:newTestCasesGroup(self, "NewTestCasesGroupForSequenceChecks")
-----------------------------------------------------------------------------------------

--Begin Test case DifferentHMIlevelChecks.1
--Description: Check request is disallowed in NONE HMI level
function Test:Precondition_DeactivateToNone()
--hmi side: sending BasicCommunication.OnExitApplication notification
self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

EXPECT_NOTIFICATION("OnHMIStatus",
  { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:GetWayPoints_HMIStatus_NONE()

--mobile side: sending the request
local RequestParams = Test:createRequest()
local cid = self.mobileSession:SendRPC("GetWayPoints", RequestParams)

--mobile side: expect response
EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED"})
end

--Postcondition: Activate app
commonSteps:ActivationApp(self)

--End Test case DifferentHMIlevelChecks.1
-----------------------------------------------------------------------------------------

--Begin Test case DifferentHMIlevelChecks.2
--Description: Check HMI level Full

--It is covered by above test cases

--End Test case DifferentHMIlevelChecks.2
-----------------------------------------------------------------------------------------

--Begin Test case DifferentHMIlevelChecks.3
--Description: Check HMI level LIMITED
if
Test.isMediaApplication == true or
Test.appHMITypes["NAVIGATION"] == true then

--Precondition: Deactivate app to LIMITED HMI level
commonSteps:ChangeHMIToLimited(self)

function Test:GetWayPoints_HMIStatus_LIMITED()
  local RequestParams = Test:createRequest()
  self:verify_SUCCESS_Case(RequestParams)
end

--End Test case DifferentHMIlevelChecks.3

-- Precondition 1: Opening new session
function Test:AddNewSession()
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection)

  self.mobileSession2:StartService(7)
end

-- Precondition 2: Register app2
function Test:RegisterAppInterface_App2()

  --mobile side: RegisterAppInterface request
  local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
    {
      syncMsgVersion =
      {
        majorVersion = 2,
        minorVersion = 2,
      },
      appName ="SPT2",
      isMediaApplication = true,
      languageDesired ="EN-US",
      hmiDisplayLanguageDesired ="EN-US",
      appID ="2",
      ttsName =
      {
        {
          text ="SyncProxyTester2",
          type ="TEXT",
        },
      },
      vrSynonyms =
      {
        "vrSPT2",
      }
    })

  --hmi side: expect BasicCommunication.OnAppRegistered request
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {
      application =
      {
        appName = "SPT2"
      }
    })
  :Do(function(_,data)
      self.applications["Test Application2"] = data.params.application.appID
    end)

  --mobile side: RegisterAppInterface response
  self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  :Timeout(2000)

  self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

-- Precondition 3: Activate an other media app to change app to BACKGROUND
function Test:Activate_Media_App2()
  --HMI send ActivateApp request
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application2"]})
  EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)

        if data.result.isSDLAllowed and data.result.isSDLAllowed ~= true then
          local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
          EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
          :Do(function(_,data)
            --hmi side: send request SDL.OnAllowSDLFunctionality
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})
          end)

          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
            self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
          end)
          :Times(2)
        end
      end)
      :Timeout(5000)


  self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :Timeout(12000)

  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

end

elseif Test.isMediaApplication == false then
--Precondition: Deactivate app to BACKGOUND HMI level
commonSteps:DeactivateToBackground(self)
end

-----------------------------------------------------------------------------------------

--Begin Test case DifferentHMIlevelChecks.4
--Description: Check HMI level BACKGOUND
function Test:GetWayPoints_HMIStatus_BACKGOUND()
local RequestParams = Test:createRequest()
self:verify_SUCCESS_Case(RequestParams)
end
--End Test case DifferentHMIlevelChecks.4
end

DifferentHMIlevelChecks()

