-------------------------------------------------------------------------------------------------
------------------------------------------- Automated preconditions -----------------------------
-------------------------------------------------------------------------------------------------
local commonSteps   = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--Backup smartDeviceLink.ini file
function Precondition_ArchivateINI()
    commonPreconditions:BackupFile("smartDeviceLink.ini")
end

function Precondition_PendingRequestsAmount()
    local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")
    local StringToReplace = "PendingRequestsAmount = 3\n"
    f = assert(io.open(SDLini, "r"))
    if f then
        fileContent = f:read("*all")

        fileContentUpdated  =  string.gsub(fileContent, "%p?PendingRequestsAmount%s-=%s?[%w%d;]-\n", StringToReplace)

        if fileContentUpdated then
          f = assert(io.open(SDLini, "w"))
          f:write(fileContentUpdated)
        else 
          userPrint(31, "Finding of 'PendingRequestsAmount = value' is failed. Expect string finding and replacing of value to true")
        end
        f:close()
    end
end
Precondition_ArchivateINI()
Precondition_PendingRequestsAmount()

-------------------------------------------------------------------------------------------------
-------------------------------------------END Automated preconditions --------------------------
-------------------------------------------------------------------------------------------------


Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------

require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

APIName = "Show" -- use for above required scripts.
--UPDATED:
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
local storagePath = config.pathToSDL .. "storage/" ..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"

local TooManyPenReqCount = 0
local IDsArray = {}
local CorIdDialNumber = {}


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

--1. Activate application
commonSteps:ActivationApp()
	
--2. PutFiles	
commonSteps:PutFile("PutFile_action_png", "action.png")

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeChecks
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-496

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.

	
	function Test:Show_SendsTooManyPendingRequest()
		
		local numberOfRequest = 10
		
		for i = 1, numberOfRequest do
			--mobile side: send Show request 	 	
			self.mobileSession:SendRPC("Show", {
												mediaClock = "12:34",
												mainField1 = "Show Line 1",
												mainField2 = "Show Line 2",
												mainField3 = "Show Line 3",
												mainField4 = "Show Line 4",
												graphic =
												{
													value = "action.png",
													imageType = "DYNAMIC"
												},
												softButtons =
												{
													 {
														text = "Close",
														systemAction = "KEEP_CONTEXT",
														type = "BOTH",
														isHighlighted = true,																
														image =
														{
														   imageType = "DYNAMIC",
														   value = "action.png"
														},																
														softButtonID = 1
													 }
												 },
												secondaryGraphic =
												{
													value = "action.png",
													imageType = "DYNAMIC"
												},
												statusBar = "status bar",
												mediaTrack = "Media Track",
												alignment = "CENTERED",
												customPresets =
												{
													"Preset1",
													"Preset2",
													"Preset3"													
												}
											})			
		end
		
		commonTestCases:verifyResultCode_TOO_MANY_PENDING_REQUESTS(numberOfRequest)
	end	

	
	
--End Test suit ResultCodeChecks

function Test:Postcondition_RestoreINI()
    commonPreconditions:RestoreFile("smartDeviceLink.ini")
end