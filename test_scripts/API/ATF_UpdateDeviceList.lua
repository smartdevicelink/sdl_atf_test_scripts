-- Script is developed by Byanova Irina
-- for ATF version 2.2

--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

-- Cretion dummy connections fo script
os.execute("ifconfig lo:1 1.0.0.1 ; ifconfig lo:2 2.0.0.1 ; ifconfig lo:3 3.0.0.1 ; ifconfig lo:4 4.0.0.1 ; ifconfig lo:5 5.0.0.1 ; ifconfig lo:6 6.0.0.1 ; ifconfig lo:7 7.0.0.1 ; ifconfig lo:8 8.0.0.1 ; ifconfig lo:9 9.0.0.1 ; ifconfig lo:10 10.0.0.1 ; ifconfig lo:11 11.0.0.1 ; ifconfig lo:12 12.0.0.1 ; ifconfig lo:13 13.0.0.1 ; ifconfig lo:14 14.0.0.1 ; ifconfig lo:15 15.0.0.1 ; ifconfig lo:16 16.0.0.1 ; ifconfig lo:17 17.0.0.1 ; ifconfig lo:18 18.0.0.1 ; ifconfig lo:19 19.0.0.1 ; ifconfig lo:20 20.0.0.1 ; ifconfig lo:21 21.0.0.1 ; ifconfig lo:22 22.0.0.1 ; ifconfig lo:23 23.0.0.1 ; ifconfig lo:24 24.0.0.1 ; ifconfig lo:25 25.0.0.1 ; ifconfig lo:26 26.0.0.1 ; ifconfig lo:27 27.0.0.1 ; ifconfig lo:28 28.0.0.1 ; ifconfig lo:29 29.0.0.1 ; ifconfig lo:30 30.0.0.1 ; ifconfig lo:31 31.0.0.1 ; ifconfig lo:32 32.0.0.1 ; ifconfig lo:33 33.0.0.1 ; ifconfig lo:34 34.0.0.1 ; ifconfig lo:35 35.0.0.1 ; ifconfig lo:36 36.0.0.1 ; ifconfig lo:37 37.0.0.1 ; ifconfig lo:38 38.0.0.1 ; ifconfig lo:39 39.0.0.1 ; ifconfig lo:40 40.0.0.1 ; ifconfig lo:41 41.0.0.1 ; ifconfig lo:42 42.0.0.1 ; ifconfig lo:43 43.0.0.1 ; ifconfig lo:44 44.0.0.1 ; ifconfig lo:45 45.0.0.1 ; ifconfig lo:46 46.0.0.1 ; ifconfig lo:47 47.0.0.1 ; ifconfig lo:48 48.0.0.1 ; ifconfig lo:49 49.0.0.1 ; ifconfig lo:50 50.0.0.1 ; ifconfig lo:51 51.0.0.1 ; ifconfig lo:52 52.0.0.1 ; ifconfig lo:53 53.0.0.1 ; ifconfig lo:54 54.0.0.1 ; ifconfig lo:55 55.0.0.1 ; ifconfig lo:56 56.0.0.1 ; ifconfig lo:57 57.0.0.1 ; ifconfig lo:58 58.0.0.1 ; ifconfig lo:59 59.0.0.1 ; ifconfig lo:60 60.0.0.1 ; ifconfig lo:61 61.0.0.1 ; ifconfig lo:62 62.0.0.1 ; ifconfig lo:63 63.0.0.1 ; ifconfig lo:64 64.0.0.1 ; ifconfig lo:65 65.0.0.1 ; ifconfig lo:66 66.0.0.1 ; ifconfig lo:67 67.0.0.1 ; ifconfig lo:68 68.0.0.1 ; ifconfig lo:69 69.0.0.1 ; ifconfig lo:70 70.0.0.1 ; ifconfig lo:71 71.0.0.1 ; ifconfig lo:72 72.0.0.1 ; ifconfig lo:73 73.0.0.1 ; ifconfig lo:74 74.0.0.1 ; ifconfig lo:75 75.0.0.1 ; ifconfig lo:76 76.0.0.1 ; ifconfig lo:77 77.0.0.1 ; ifconfig lo:78 78.0.0.1 ; ifconfig lo:79 79.0.0.1 ; ifconfig lo:80 80.0.0.1 ; ifconfig lo:81 81.0.0.1 ; ifconfig lo:82 82.0.0.1 ; ifconfig lo:83 83.0.0.1 ; ifconfig lo:84 84.0.0.1 ; ifconfig lo:85 85.0.0.1 ; ifconfig lo:86 86.0.0.1 ; ifconfig lo:87 87.0.0.1 ; ifconfig lo:88 88.0.0.1 ; ifconfig lo:89 89.0.0.1 ; ifconfig lo:90 90.0.0.1 ; ifconfig lo:91 91.0.0.1 ; ifconfig lo:92 92.0.0.1 ; ifconfig lo:93 93.0.0.1 ; ifconfig lo:94 94.0.0.1 ; ifconfig lo:95 95.0.0.1 ; ifconfig lo:96 96.0.0.1 ; ifconfig lo:97 97.0.0.1 ; ifconfig lo:98 98.0.0.1 ; ifconfig lo:99 99.0.0.1 ; ifconfig lo:100 100.0.0.1 ; ifconfig lo:101 101.0.0.1")

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_UpdateDeviceList.lua
Preconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_UpdateDeviceList.lua")

Test = require('user_modules/connecttest_UpdateDeviceList')
require('cardinalities')
local mobile_session = require('mobile_session')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local mobile  = require('mobile_connection')

----------------------------------------------------------------------------
-- User required files

require('user_modules/AppTypes')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')

----------------------------------------------------------------------------
-- Postcondition: removing user_modules/connecttest_UpdateDeviceList.lua
function Test:Postcondition_remove_user_connecttest()
 	os.execute( "rm -f ./user_modules/connecttest_UpdateDeviceList.lua" )
end

-- deleting policy teable
commonSteps:DeleteLogsFileAndPolicyTable()

----------------------------------------------------------------------------
-- User required variables

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

local DeviceMacValues = {}

local Connections = { 
	{connection = Test.mobileConnection1, session = Test.mobileSession1}, 
	{connection = Test.mobileConnection2, session = Test.mobileSession2}, 
	{connection = Test.mobileConnection3, session = Test.mobileSession3}, 
	{connection = Test.mobileConnection4, session = Test.mobileSession4}, 
	{connection = Test.mobileConnection5, session = Test.mobileSession5}, 
	{connection = Test.mobileConnection6, session = Test.mobileSession6}, 
	{connection = Test.mobileConnection7, session = Test.mobileSession7}, 
	{connection = Test.mobileConnection8, session = Test.mobileSession8}, 
	{connection = Test.mobileConnection9, session = Test.mobileSession9},  
	{connection = Test.mobileConnection10, session = Test.mobileSession10},
	{connection = Test.mobileConnection11, session = Test.mobileSession11}, 
	{connection = Test.mobileConnection12, session = Test.mobileSession12}, 
	{connection = Test.mobileConnection13, session = Test.mobileSession13}, 
	{connection = Test.mobileConnection14, session = Test.mobileSession14}, 
	{connection = Test.mobileConnection15, session = Test.mobileSession15}, 
	{connection = Test.mobileConnection16, session = Test.mobileSession16}, 
	{connection = Test.mobileConnection17, session = Test.mobileSession17}, 
	{connection = Test.mobileConnection18, session = Test.mobileSession18}, 
	{connection = Test.mobileConnection19, session = Test.mobileSession19},  
	{connection = Test.mobileConnection20, session = Test.mobileSession20},
	{connection = Test.mobileConnection21, session = Test.mobileSession21}, 
	{connection = Test.mobileConnection22, session = Test.mobileSession22}, 
	{connection = Test.mobileConnection23, session = Test.mobileSession23}, 
	{connection = Test.mobileConnection24, session = Test.mobileSession24}, 
	{connection = Test.mobileConnection25, session = Test.mobileSession25}, 
	{connection = Test.mobileConnection26, session = Test.mobileSession26}, 
	{connection = Test.mobileConnection27, session = Test.mobileSession27}, 
	{connection = Test.mobileConnection28, session = Test.mobileSession28}, 
	{connection = Test.mobileConnection29, session = Test.mobileSession29},  
	{connection = Test.mobileConnection30, session = Test.mobileSession30},
	{connection = Test.mobileConnection31, session = Test.mobileSession31}, 
	{connection = Test.mobileConnection32, session = Test.mobileSession32}, 
	{connection = Test.mobileConnection33, session = Test.mobileSession33}, 
	{connection = Test.mobileConnection34, session = Test.mobileSession34}, 
	{connection = Test.mobileConnection35, session = Test.mobileSession35}, 
	{connection = Test.mobileConnection36, session = Test.mobileSession36}, 
	{connection = Test.mobileConnection37, session = Test.mobileSession37}, 
	{connection = Test.mobileConnection38, session = Test.mobileSession38}, 
	{connection = Test.mobileConnection39, session = Test.mobileSession39},  
	{connection = Test.mobileConnection40, session = Test.mobileSession40},
	{connection = Test.mobileConnection41, session = Test.mobileSession41}, 
	{connection = Test.mobileConnection42, session = Test.mobileSession42}, 
	{connection = Test.mobileConnection43, session = Test.mobileSession43}, 
	{connection = Test.mobileConnection44, session = Test.mobileSession44}, 
	{connection = Test.mobileConnection45, session = Test.mobileSession45}, 
	{connection = Test.mobileConnection46, session = Test.mobileSession46}, 
	{connection = Test.mobileConnection47, session = Test.mobileSession47}, 
	{connection = Test.mobileConnection48, session = Test.mobileSession48}, 
	{connection = Test.mobileConnection49, session = Test.mobileSession49},  
	{connection = Test.mobileConnection50, session = Test.mobileSession50},
	{connection = Test.mobileConnection51, session = Test.mobileSession51}, 
	{connection = Test.mobileConnection52, session = Test.mobileSession52}, 
	{connection = Test.mobileConnection53, session = Test.mobileSession53}, 
	{connection = Test.mobileConnection54, session = Test.mobileSession54}, 
	{connection = Test.mobileConnection55, session = Test.mobileSession55}, 
	{connection = Test.mobileConnection56, session = Test.mobileSession56}, 
	{connection = Test.mobileConnection57, session = Test.mobileSession57}, 
	{connection = Test.mobileConnection58, session = Test.mobileSession58}, 
	{connection = Test.mobileConnection59, session = Test.mobileSession59},  
	{connection = Test.mobileConnection60, session = Test.mobileSession60},
	{connection = Test.mobileConnection61, session = Test.mobileSession61}, 
	{connection = Test.mobileConnection62, session = Test.mobileSession62}, 
	{connection = Test.mobileConnection63, session = Test.mobileSession63}, 
	{connection = Test.mobileConnection64, session = Test.mobileSession64}, 
	{connection = Test.mobileConnection65, session = Test.mobileSession65}, 
	{connection = Test.mobileConnection66, session = Test.mobileSession66}, 
	{connection = Test.mobileConnection67, session = Test.mobileSession67}, 
	{connection = Test.mobileConnection68, session = Test.mobileSession68}, 
	{connection = Test.mobileConnection69, session = Test.mobileSession69},  
	{connection = Test.mobileConnection70, session = Test.mobileSession70},
	{connection = Test.mobileConnection71, session = Test.mobileSession71}, 
	{connection = Test.mobileConnection72, session = Test.mobileSession72}, 
	{connection = Test.mobileConnection73, session = Test.mobileSession73}, 
	{connection = Test.mobileConnection74, session = Test.mobileSession74}, 
	{connection = Test.mobileConnection75, session = Test.mobileSession75}, 
	{connection = Test.mobileConnection76, session = Test.mobileSession76}, 
	{connection = Test.mobileConnection77, session = Test.mobileSession77}, 
	{connection = Test.mobileConnection78, session = Test.mobileSession78}, 
	{connection = Test.mobileConnection79, session = Test.mobileSession79},  
	{connection = Test.mobileConnection80, session = Test.mobileSession80},
	{connection = Test.mobileConnection81, session = Test.mobileSession81}, 
	{connection = Test.mobileConnection82, session = Test.mobileSession82}, 
	{connection = Test.mobileConnection83, session = Test.mobileSession83}, 
	{connection = Test.mobileConnection84, session = Test.mobileSession84}, 
	{connection = Test.mobileConnection85, session = Test.mobileSession85}, 
	{connection = Test.mobileConnection86, session = Test.mobileSession86}, 
	{connection = Test.mobileConnection87, session = Test.mobileSession87}, 
	{connection = Test.mobileConnection88, session = Test.mobileSession88}, 
	{connection = Test.mobileConnection89, session = Test.mobileSession89},  
	{connection = Test.mobileConnection90, session = Test.mobileSession90},
	{connection = Test.mobileConnection91, session = Test.mobileSession91}, 
	{connection = Test.mobileConnection92, session = Test.mobileSession92}, 
	{connection = Test.mobileConnection93, session = Test.mobileSession93}, 
	{connection = Test.mobileConnection94, session = Test.mobileSession94}, 
	{connection = Test.mobileConnection95, session = Test.mobileSession95}, 
	{connection = Test.mobileConnection96, session = Test.mobileSession96}, 
	{connection = Test.mobileConnection97, session = Test.mobileSession97}, 
	{connection = Test.mobileConnection98, session = Test.mobileSession98}, 
	{connection = Test.mobileConnection99, session = Test.mobileSession99},  
	{connection = Test.mobileConnection100, session = Test.mobileSession100},
	{connection = Test.mobileConnection101, session = Test.mobileSession101},
}

local deviceListArray = {}


-- Storage path
local StoragePath = SDLConfig:GetValue("AppStorageFolder")
if 
	not StoragePath or
	StoragePath == "" then
	StoragePath = 'storage'
end

---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------

-- App registration
local function RegisterApp(self, RegisterData)

  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", RegisterData)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    :Do(function(_,data)
     self.HMIAppID = data.params.application.appID
    end)

  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })


  self.mobileSession:ExpectNotification("OnHMIStatus", 
    {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

-- Check direcrory existence 
local function Directory_exist(DirectoryPath)
    if type( DirectoryPath ) ~= 'string' then
            error('Directory_exist : Input parameter is not string : ' .. type(DirectoryPath) )
            return false
    else
        local response = os.execute( 'cd ' .. DirectoryPath .. " 2> /dev/null" )
        -- ATf returns as result of 'os.execute' boolean value, lua interp returns code. if conditions process result as for lua enterp and for ATF.
        if response == nil or response == false then
            return false
        end
        if response == true then
            return true
        end
        return response == 0;
    end
end


local function RestartSDL(prefix, DeleteStorageFolder)

	Test["StopSDL_" .. tostring(prefix) ] = function(self)
		commonFunctions:userPrint(35, "\n================= Precondition ==================")
		StopSDL()
	end

	if DeleteStorageFolder then
		Test["DeleteStorageFolder_" .. tostring(prefix)] = function(self)
			local ExistDirectoryResult = Directory_exist( tostring(config.pathToSDL .. "storage"))
			if ExistDirectoryResult == true then
				local RmFolder  = assert( os.execute( "rm -rf " .. tostring(config.pathToSDL .. "storage" )))
				if RmFolder ~= true then
					commonFunctions:userPrint(31, "Folder 'storage' is not deleted")
				end
			else
				commonFunctions:userPrint(33, "Folder 'storage' is absent")
			end
		end
	end

	Test["StartSDL_" .. tostring(prefix) ] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["InitHMI_" .. tostring(prefix) ] = function(self)
		self:initHMI()
	end

	Test["InitHMI_onReady_" .. tostring(prefix) ] = function(self)
		self:initHMI_onReady()
	end

end

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

--DB query
local function Exec(cmd) 
    local function trim(s)
      return s:gsub("^%s+", ""):gsub("%s+$", "")
    end
    local aHandle = assert(io.popen(cmd , 'r'))
    local output = aHandle:read( '*a' )
    return trim(output)
end

local function DataBaseQuery(self,  DBQueryV)

    local function query_success(output)
        if output == "" or DBQueryValue == " " then return false end
        local f, l = string.find(output, "Error:")
        if f == 1 then return false end
        return true;
    end
    for i=1,10 do 
        local DBQuery = 'sqlite3 ' .. config.pathToSDL .. StoragePath .. '/policy.sqlite "' .. tostring(DBQueryV) .. '"'
        DBQueryValue = Exec(DBQuery)
        if query_success(DBQueryValue) then
            return DBQueryValue
        end
        os.execute(" sleep 1 ")
    end
    return false
end

local function CheckArrayValues(elementValue)
	for j=1, #DeviceMacValues do
		if elementValue == DeviceMacValues[j] then
			commonFunctions:userPrint(31, " Duplicated DeviceMAC values. Such device is already existed!" )
		end
	end
end

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

--Not Applicable


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

--Not Applicable

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
---------------------------------Check normal cases of HMI response----------------------------
-----------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("Normal cases of HMI response with different result codes")

local resultCodes = {"SUCCESS", "UNSUPPORTED_REQUEST", "UNSUPPORTED_RESOURCE", "DISALLOWED", "REJECTED", "ABORTED", "IGNORED", "TIMED_OUT", "INVALID_DATA", "INVALID_ID", "OUT_OF_MEMORY", "TOO_MANY_PENDING_REQUESTS", "WARNINGS", "GENERIC_ERROR", "USER_DISALLOWED"}

for i=1, #resultCodes do
	Test[ "UpdateDeviceListResponse_" .. tostring(resultCodes[i]) ] = function(self)
		self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

		EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
			:Do(function(_,data)
				if resultCodes[i] == "SUCCESS" then
					self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i], { })
				else
					self.hmiConnection:SendError(data.id, data.method, resultCodes[i], " Error message " )
				end
			end)

		DelayedExp(1000)
	end
end

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
----------------------------Check special cases of HMI response---------------------------
----------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("Special cases of HMI response")
--Requirement id in JAMA or JIRA: 	
	--APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

-----------------------------------------------------------------------------------------------

--List of test cases for special cases of HMI response:
	--1. InvalidJsonSyntax
	--2. InvalidStructure
	--3. FakeParams 
	--4. FakeParameterIsFromAnotherAPI
	--5. MissedmandatoryParameters
	--6. MissedAllParameters
	--7. SeveralResponses with the same values
	--8. SeveralResponses with different values
----------------------------------------------------------------------------------------------
local event = events.Event()
----------------------------------------------------------------------------------------------
-- InvalidJsonSyntax
function Test:UpdateDeviceListResponse_InvalidJsonSyntax()
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			--<<!-- missing ':' after id
			self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.UpdateDeviceList", "code":0}}')
		end)

	DelayedExp(1000)
end

----------------------------------------------------------------------------------------------
-- InvalidStructure
function Test:UpdateDeviceListResponse_InvalidStructure()
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			--<<!-- method is not in result struct
			self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","method":"BasicCommunication.UpdateDeviceList", "result":{"code":0}}')
		end)

	DelayedExp(1000)
end


----------------------------------------------------------------------------------------------
-- FakeParams
function Test:UpdateDeviceListResponse_FakeParams()
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { fake = "fake" })
		end)

	DelayedExp(1000)
end

----------------------------------------------------------------------------------------------
-- FakeParameterIsFromAnotherAPI
function Test:UpdateDeviceListResponse_FakeParameterIsFromAnotherAPI()
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { sliderPosition = 5 })
		end)

	DelayedExp(1000)
end

----------------------------------------------------------------------------------------------
-- MissedmandatoryParameters: id
function Test:UpdateDeviceListResponse_missed_id()
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"BasicCommunication.UpdateDeviceList", "code":0}}')
		end)

	DelayedExp(1000)
end

----------------------------------------------------------------------------------------------
-- MissedmandatoryParameters: method
function Test:UpdateDeviceListResponse_missed_method()
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:Send('{"id":'..tostring(data.id)..', "jsonrpc":"2.0","result":{"code":0}}')
		end)

	DelayedExp(1000)
end

----------------------------------------------------------------------------------------------
-- MissedmandatoryParameters: code
function Test:UpdateDeviceListResponse_missed_code()
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:Send('{"id":'..tostring(data.id)..', "jsonrpc":"2.0","result":{"method":"BasicCommunication.UpdateDeviceList"}}')
		end)

	DelayedExp(1000)
end

----------------------------------------------------------------------------------------------
-- MissedmandatoryParameters: result
function Test:UpdateDeviceListResponse_missed_result()
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:Send('{"id":'..tostring(data.id)..', "jsonrpc":"2.0"')
		end)

	DelayedExp(1000)
end

----------------------------------------------------------------------------------------------
-- MissedAllParameters
function Test:UpdateDeviceListResponse_MissedAllParameters()
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:Send('{}')
		end)

	DelayedExp(1000)
end

----------------------------------------------------------------------------------------------
-- SeveralResponses with the same values
function Test:UpdateDeviceListResponse_SameSeveralResponses()
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

	DelayedExp(1000)
end

----------------------------------------------------------------------------------------------
-- SeveralResponses with different values
function Test:UpdateDeviceListResponse_DifferentSeveralResponses()
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
		end)

	DelayedExp(1000)
end

---------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK V----------------------------------------
-----------------------------------Checks All Result Codes-----------------------------------
---------------------------------------------------------------------------------------------

-- Not applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("Sequence with emulating of user's action(s)")

--======================================================================================--
--Initial precondition: Restart SDL 
-- RestartSDL("InitialPrecondition", true)
RestartSDL("InitialPrecondition")

-- APPLINK-18432: 01[P][MAN]_TC_SDL_sends_empty_deviceList
--======================================================================================--
-- SDL sends empty "deviceList" parameter in UpdateDeviceList request if no Apps were found during BT scan
--======================================================================================--

function Test:UpdateDeviceList_EmptyDeviceList()
	commonFunctions:userPrint(34, "=================== Test Case ===================")
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:ValidIf(function(_,data)
			if #data.params.deviceList ~= 0 then
				commonFunctions:userPrint(31, "deviceList array in UpdateDeviceList is not empty. Received elements number '" .. tostring(#data.params.deviceList) .. "'")
				return false
			else
			    return true
			end
		end)
end


-- APPLINK-18433: 02[P][MAN]_TC_SDL_sends_non-empty_deviceList
--======================================================================================--
-- SDL sends non-empty "deviceList" parameter in UpdateDeviceList request if no Apps were found during BT scan.
--======================================================================================--

function Test:ConnectDevice_NonEmptyDeviceList()
	commonFunctions:userPrint(35, "\n================= Precondition ==================")
	self:connectMobile()

	os.execute("sleep 0.5")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
		{
			deviceList = {
				{
					id = config.deviceMAC,
					isSDLAllowed = true,
					name = "127.0.0.1",
					transportType = "WIFI"
				}
			}
		})
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
end

-- TODO: can be updated after resolving APPLINK-25765
function Test:UpdateDeviceList_NonEmptyDeviceList()
	commonFunctions:userPrint(34, "=================== Test Case ===================")
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
		{
			deviceList = {
				{
					id = config.deviceMAC,
					isSDLAllowed = true,
					name = "127.0.0.1",
					transportType = "WIFI"
				}
			}
		})
		:DoOnce(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

			self.hmiConnection:SendNotification("BasicCommunication.OnDeviceChosen",
				{
					deviceInfo = {
						id = data.params.deviceList[1].id,
						name = data.params.deviceList[1].name
					}
				})

			self.hmiConnection:SendNotification("BasicCommunication.OnFindApplications",
				{
					deviceInfo = {
						id = data.params.deviceList[1].id,
						name = data.params.deviceList[1].name
					}
				})

		end)
		:ValidIf(function(_,data)
			if #data.params.deviceList ~= 1 then
				commonFunctions:userPrint(31, "deviceList array in UpdateDeviceList contains not one device in list. Received elements number '" .. tostring(#data.params.deviceList) .. "'")
				return false
			else
			    return true
			end
		end)

	EXPECT_HMICALL("BasicCommunication.UpdateAppList")
		:ValidIf(function(_,data)
			if #data.params.applications ~= 0 then
				commonFunctions:userPrint(31, "Number of applications in UpdateAppList in not 0, received number '" .. tostring(#data.params.applications) .. "'")
				return false
			else 
				return true
			end
		end)
end

-- APPLINK-18434: 03[P][MAN]_TC_SDL_sends_empty_deviceList_no_BT_device_connected_during_scan
--======================================================================================--
-- SDL sends empty "deviceList" parameter in UpdateDeviceList request if no one BT device is connected during scan
--======================================================================================--

function Test:CloseConnection()
	commonFunctions:userPrint(35, "\n================= Precondition ==================")
	self.mobileConnection:Close()

	DelayedExp(1000)
end

function Test:UpdateDeviceList_EmptyDeviceList_AfterConnectionIsClosed()
	commonFunctions:userPrint(34, "=================== Test Case ===================")
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:ValidIf(function(_,data)
			if #data.params.deviceList ~= 0 then
				commonFunctions:userPrint(31, "deviceList array in UpdateDeviceList is not empty. Received elements number '" .. tostring(#data.params.deviceList) .. "'")
				return false
			else
			    return true
			end
		end)

end

-- APPLINK-18434: 03[P][MAN]_TC_SDL_sends_empty_deviceList_no_BT_device_connected_during_scan
--======================================================================================--
-- SDL sends empty "deviceList" parameter in UpdateDeviceList request if no one BT device is connected during scan and in previous cycles the were some connected devices. 
--======================================================================================--

--======================================================================================--
--Precondition: Restart SDL 
RestartSDL("Initial_InPreviosIGNCycleWasConnectedDevice")


--======================================================================================--
-- Precondition: Check UpdateDeviceList after connection device
function Test:UpdateDeviceList_InPreviosIGNCycleWasConnectedDevice()
	commonFunctions:userPrint(34, "=================== Test Case ===================")
	-- connect device
	self:connectMobile()

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
		{
			deviceList = {
				{
					id = config.deviceMAC,
					isSDLAllowed = true,
					name = "127.0.0.1",
					transportType = "WIFI"
				}
			}
		})
		:DoOnce(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

		end)
		:ValidIf(function(_,data)
			if #data.params.deviceList ~= 1 then
				commonFunctions:userPrint(31, "deviceList array in UpdateDeviceList contains not one device in list. Received elements number '" .. tostring(#data.params.deviceList) .. "'")
				return false
			else
			    return true
			end
		end)


end

--======================================================================================--
--Precondition: Restart SDL 
RestartSDL("InPreviosIGNCycleWasConnectedDevice")


--======================================================================================--
-- SDL sends empty UpdateDeviceList in case some devicewas connected in previos ignition cycle
function Test:UpdateDeviceList_EmptyDeviceList_InPreviosIGNCycleWasConnectedDevice()
	commonFunctions:userPrint(34, "=================== Test Case ===================")
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:ValidIf(function(_,data)
			if #data.params.deviceList ~= 0 then
				commonFunctions:userPrint(31, "deviceList array in UpdateDeviceList is not empty. Received elements number '" .. tostring(#data.params.deviceList) .. "'")
				return false
			else
			    return true
			end
		end)

end

--======================================================================================--
-- Check device id value in device table, and absence of data in device_consent_group.is_consented
--======================================================================================--

--Precondition: Restart SDL, delete storage folder 
-- RestartSDL("DeleteStorageFolder_AfterDeviceIsAllowed", true)
RestartSDL("DeleteStorageFolder_CheckPT")

function Test:ConnectMobile_AfterDeviceIsAllowed()
	self:connectMobile()

	DelayedExp(1500)
end

--======================================================================================--
function Test:UpdateDeviceList_CheckPT()
	commonFunctions:userPrint(34, "=================== Test Case ===================")
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
		{
			deviceList = {
				{
					id = config.deviceMAC,
					isSDLAllowed = true,
					name = "127.0.0.1",
					transportType = "WIFI"
				}
			}
		})
		:Do(function(exp,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

			local deviceIdPTValue = DataBaseQuery(self, "SELECT id FROM device WHERE rowid = 1")

		    if not deviceIdPTValue then
		    	self:FailTestCase(" DB query to device.id is failed or field is empty in PT")
		    elseif
		    	deviceIdPTValue ~= config.deviceMAC then
		    	self:FailTestCase("Device id in PT is unexpected = '" .. tostring(deviceIdPTValue) ..  "', expected value is '" .. tostring(config.deviceMAC) .. "'")
		    end

		    local IsConsentedPTValue = DataBaseQuery(self, "SELECT is_consented FROM device_consent_group WHERE rowid = 1")

			if IsConsentedPTValue then
		    	self:FailTestCase(" device_consent_group.is_consented is present in PT")
	    	end

			self.hmiConnection:SendNotification("BasicCommunication.OnDeviceChosen",
				{
					deviceInfo = {
						id = data.params.deviceList[1].id,
						name = data.params.deviceList[1].name
					}
				})

		end)
		:ValidIf(function(_,data)
			if #data.params.deviceList ~= 1 then
				commonFunctions:userPrint(31, "deviceList array in UpdateDeviceList contains not one device in list. Received elements number '" .. tostring(#data.params.deviceList) .. "'")
				return false
			else
			    return true
			end
		end)
		:Times(2)

	DelayedExp(3000)
end


--======================================================================================--
-- UpdateDeviceList after clossing connnection on device with registered app
--======================================================================================--

--Precondition: Restart SDL, delete storage folder 
RestartSDL("DeleteStorageFolder_AfterClosingConnectionWithRegisteredApp")

function Test:ConnectMobile_AfterClosingConnectionWithRegisteredApp()
	self:connectMobile()

	os.execute("sleep 0.5")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
		{
			deviceList = {
				{
					id = config.deviceMAC,
					isSDLAllowed = true,
					name = "127.0.0.1",
					transportType = "WIFI"
				}
			}
		})
	:Do(function()
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	DelayedExp(1500)
end

function Test:RegisterApplication()
	self.mobileSession = mobile_session.MobileSession(
	      self,
	      self.mobileConnection)

	self.mobileSession:StartService(7)
	:Do(function()
		RegisterApp(self, config.application1.registerAppInterfaceParams)

		EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
			:Times(0)

		DelayedExp(1000)
	end)
end

function Test:UpdateDeviceList_AfterClosingConnectionWithRegisteredApp()
	commonFunctions:userPrint(34, "=================== Test Case ===================")
	-- close connection
	self.mobileConnection:Close()

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})

	EXPECT_HMICALL("BasicCommunication.UpdateAppList")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:ValidIf(function(_,data)
				if #data.params.applications ~= 0 then
					commonFunctions:userPrint(31, "applications array in UpdateAppList is not empty. Received elements number '" .. tostring(#data.params.applications) .. "'")
					return false
				else
				    return true
				end
			end)


	local function DeviceDiscovery()

		self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

		EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:ValidIf(function(_,data)
				if #data.params.deviceList ~= 0 then
					commonFunctions:userPrint(31, "deviceList array in UpdateDeviceList is not empty. Received elements number '" .. tostring(#data.params.deviceList) .. "'")
					return false
				else
				    return true
				end
			end)
	end

	RUN_AFTER(DeviceDiscovery, 1000)

	DelayedExp(2000)
end


--======================================================================================--
-- Different "deviceID" values in UpdateDeviceList for devices connected via WiFi
--======================================================================================--
--Precondition: Restart SDL, delete storage folder 
RestartSDL("DeleteStorageFolder_DifferentDeviceId")

function Test:CreateFirstConnection_DifferentDeviceId()
	self:connectMobile()

	os.execute(" sleep 0.5")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
		{
			deviceList = {
				{
					id = config.deviceMAC,
					isSDLAllowed = true,
					name = "127.0.0.1",
					transportType = "WIFI"
				}
			}
		})
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
end

function Test:UpdateDeviceList_DifferentDeviceId()
	commonFunctions:userPrint(34, "=================== Test Case ===================")
	local tcpConnection = tcp.Connection("1.0.0.1", config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection2 = mobile.MobileConnection(fileConnection)
    self.mobileSession2= mobile_session.MobileSession(
    self,
    self.mobileConnection2)
    event_dispatcher:AddConnection(self.mobileConnection2)
    self.mobileSession2:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection2:Connect()

    os.execute(" sleep 0.5")

    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
		{
			deviceList = {
				{
					id = config.deviceMAC,
					isSDLAllowed = true,
					name = "127.0.0.1",
					transportType = "WIFI"
				},
				{
					id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
					isSDLAllowed = true,
					name = "1.0.0.1",
					transportType = "WIFI"
				}
			}
		})
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
end


--======================================================================================--
-- Device is still present in UpdateDeviceList after all apps are unregistered
--======================================================================================--
--Precondition: Restart SDL, delete storage folder 
RestartSDL("DeleteStorageFolder_afterAllAppsAreUnregisteredFromDevice")

function Test:CreateConnection_afterAllAppsAreUnregisteredFromDevice()
	self:connectMobile()
end

function Test:RegisterApplication_afterAllAppsAreUnregisteredFromDevice()
	self.mobileSession = mobile_session.MobileSession(
	      self,
	      self.mobileConnection)

	self.mobileSession:StartService(7)
	:Do(function()
		RegisterApp(self, config.application1.registerAppInterfaceParams)
	end)
end

function Test:UpdateDeviceList_afterAllAppsAreUnregisteredFromDevice()
	commonFunctions:userPrint(34, "=================== Test Case ===================")
	--mobile side: UnregisterAppInterface request 
  	local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

  	--hmi side: expected  BasicCommunication.OnAppUnregistered
  	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})

  	--mobile side: UnregisterAppInterface response 
  	self.mobileSession:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})
  	:Do(function()

  		-- Close session
  		self.mobileSession:Stop()

  		local function DeviceDiscovery()

			self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

			EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
			{
				deviceList = {
					{
						id = config.deviceMAC,
						isSDLAllowed = true,
						name = "127.0.0.1",
						transportType = "WIFI"
					}
				}
			})
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		end

		RUN_AFTER(DeviceDiscovery, 1000)
  	end)

  	EXPECT_HMICALL("BasicCommunication.UpdateAppList")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:ValidIf(function(_,data)
			if #data.params.applications ~= 0 then
				commonFunctions:userPrint(31, "applications array in UpdateAppList is not empty. Received elements number '" .. tostring(#data.params.applications) .. "'")
				return false
			else
			    return true
			end
		end)

	DelayedExp(3000)
end

--======================================================================================--
-- Connect 101 device, UpdateDeviceListAfter each connection, 101 element is out bound value for deviceList array
--======================================================================================--
-- Precondition restart SDL, delete storage folder
RestartSDL("Connection101Devices")

--Connect 101 device
for i=1, 101 do 
	Test["UpdateDeviceList_Device" .. tostring(i)] = function(self)
	commonFunctions:userPrint(34, "=================== Test Case ===================")
		local mobileHost = tostring(i) .. ".0.0.1"

		local tcpConnection = tcp.Connection(mobileHost, config.mobilePort)
	    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
	    Connections[i].connection = mobile.MobileConnection(fileConnection)
	    Connections[i].session = mobile_session.MobileSession(
	    self,
	    Connections[i].connection)
	    event_dispatcher:AddConnection(Connections[i].connection)
	    Connections[i].session :ExpectEvent(events.connectedEvent, "Connection started")
	    Connections[i].connection:Connect()

	    os.execute(" sleep 0.3 ")

	    if i <=100 then
		    value = {
				isSDLAllowed = true,
				name = mobileHost,
				transportType = "WIFI"
			}
		    table.insert (deviceListArray, value)

		    if deviceListArray[i-1] then
		    	deviceListArray[i-1].id = DeviceMacValues[i-1]
		    end
		end

	    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
			{
				deviceList = deviceListArray
			})
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

				if not data.params.deviceList[i].id then
					self:FailTestCase(" Element " .. tostring(i) .. " in BasicCommunication.UpdateDeviceList came without 'id' parameter ")
				else

					CheckArrayValues(data.params.deviceList[i].id)

					DeviceMacValues[i] = data.params.deviceList[i].id
				end

			end)
			:ValidIf(function(_,data)
				if i <= 100 then
					if #data.params.deviceList ~= i then
						commonFunctions:userPrint(31, " deviceList array in UpdateDeviceList contains unexpected element number. Expected number is '" .. tostring(i) .. "', actual value is '" .. tostring(#data.params.deviceList) .. "'" )
						return false
					else 
						return true
					end
				else
					if #data.params.deviceList ~= 100 then
						commonFunctions:userPrint(31, " deviceList array in UpdateDeviceList contains unexpected element number. Expected number is '100', actual value is '" .. tostring(#data.params.deviceList) .. "'" )
						return false
					else 
						return true
					end
				end
			end)
	end

end

--======================================================================================--
-- Disconnect all devices, UpdateDeviceListAfter after each disconnection
--======================================================================================--

for i=101, 1, -1 do 

	Test["UpdateDeviceList_ByClossingConnectionDevice" .. tostring(i)] = function(self)
	commonFunctions:userPrint(34, "=================== Test Case ===================")

		Connections[i].connection:Close()

		os.execute(" sleep 0.5 ")

		self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

		local mobileHost = tostring(i) .. ".0.0.1"

	    if i <=99 then
	    	table.remove (deviceListArray,i+1)
		end

	 	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
			{
				deviceList = deviceListArray
			})
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

			end)
			:ValidIf(function(_,data)
				if i <= 100 then
					if #data.params.deviceList ~= i then
						commonFunctions:userPrint(31, " deviceList array in UpdateDeviceList contains unexpected element number. Expected number is '" .. tostring(i) .. "', actual value is '" .. tostring(#data.params.deviceList) .. "'" )
						return false
					else 
						return true
					end
				else
					if #data.params.deviceList ~= 100 then
						commonFunctions:userPrint(31, " deviceList array in UpdateDeviceList contains unexpected element number. Expected number is '100', actual value is '" .. tostring(#data.params.deviceList) .. "'" )
						return false
					else 
						return true
					end
				end
			end)

	end
end

--======================================================================================--
-- UpdateDeviceList with empty deviceList when in previos IGN cycle were connected 101 devices 
--======================================================================================--
RestartSDL("After100DevicesDisconnected")

function Test:UpdateDeviceList_EmptyDeviceList_After100DevicesWereConnectedInPrevIGNCycle()
	commonFunctions:userPrint(34, "=================== Test Case ===================")
	self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

	EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:ValidIf(function(_,data)
			if #data.params.deviceList ~= 0 then
				commonFunctions:userPrint(31, "deviceList array in UpdateDeviceList is not empty. Received elements number '" .. tostring(#data.params.deviceList) .. "'")
				return false
			else
			    return true
			end
		end)
end


function Test:RemoveCreatedDummyConnections()
	os.execute("ifconfig lo:1 down ; ifconfig lo:2 down ; ifconfig lo:3 down ; ifconfig lo:4 down ; ifconfig lo:5 down ; ifconfig lo:6 down ; ifconfig lo:7 down ; ifconfig lo:8 down ; ifconfig lo:9 down ; ifconfig lo:10 down ; ifconfig lo:11 down ; ifconfig lo:12 down ; ifconfig lo:13 down ; ifconfig lo:14 down ; ifconfig lo:15 down ; ifconfig lo:16 down ; ifconfig lo:17 down ; ifconfig lo:18 down ; ifconfig lo:19 down ; ifconfig lo:20 down ; ifconfig lo:21 down ; ifconfig lo:22 down ; ifconfig lo:23 down ; ifconfig lo:24 down ; ifconfig lo:25 down ; ifconfig lo:26 down ; ifconfig lo:27 down ; ifconfig lo:28 down ; ifconfig lo:29 down ; ifconfig lo:30 down ; ifconfig lo:31 down ; ifconfig lo:32 down ; ifconfig lo:33 down ; ifconfig lo:34 down ; ifconfig lo:35 down ; ifconfig lo:36 down ; ifconfig lo:37 down ; ifconfig lo:38 down ; ifconfig lo:39 down ; ifconfig lo:40 down ; ifconfig lo:41 down ; ifconfig lo:42 down ; ifconfig lo:43 down ; ifconfig lo:44 down ; ifconfig lo:45 down ; ifconfig lo:46 down ; ifconfig lo:47 down ; ifconfig lo:48 down ; ifconfig lo:49 down ; ifconfig lo:50 down ; ifconfig lo:51 down ; ifconfig lo:52 down ; ifconfig lo:53 down ; ifconfig lo:54 down ; ifconfig lo:55 down ; ifconfig lo:56 down ; ifconfig lo:57 down ; ifconfig lo:58 down ; ifconfig lo:59 down ; ifconfig lo:60 down ; ifconfig lo:61 down ; ifconfig lo:62 down ; ifconfig lo:63 down ; ifconfig lo:64 down ; ifconfig lo:65 down ; ifconfig lo:66 down ; ifconfig lo:67 down ; ifconfig lo:68 down ; ifconfig lo:69 down ; ifconfig lo:70 down ; ifconfig lo:71 down ; ifconfig lo:72 down ; ifconfig lo:73 down ; ifconfig lo:74 down ; ifconfig lo:75 down ; ifconfig lo:76 down ; ifconfig lo:77 down ; ifconfig lo:78 down ; ifconfig lo:79 down ; ifconfig lo:80 down ; ifconfig lo:81 down ; ifconfig lo:82 down ; ifconfig lo:83 down ; ifconfig lo:84 down ; ifconfig lo:85 down ; ifconfig lo:86 down ; ifconfig lo:87 down ; ifconfig lo:88 down ; ifconfig lo:89 down ; ifconfig lo:90 down ; ifconfig lo:91 down ; ifconfig lo:92 down ; ifconfig lo:93 down ; ifconfig lo:94 down ; ifconfig lo:95 down ; ifconfig lo:96 down ; ifconfig lo:97 down ; ifconfig lo:98 down ; ifconfig lo:99 down ; ifconfig lo:100 down ; ifconfig lo:101 down")

end