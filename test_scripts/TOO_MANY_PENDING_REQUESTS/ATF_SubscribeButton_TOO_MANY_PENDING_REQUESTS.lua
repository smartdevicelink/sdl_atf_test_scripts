Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')

local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
local srcPath = config.pathToSDL .. "smartDeviceLink.ini"
local dstPath = config.pathToSDL .. "smartDeviceLink.ini.origin"

local TooManyPenReqCount = 0

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 5000)
end

---------------------------------------------------------------------------
-- set value of PendingRequestsAmount to "2" in smartDeviceLink.ini file
local function SetPendingRequestsAmountto2()
  -- read current content
  local ini_file = io.open(srcPath, "r")
  -- read content 
  local content = ini_file:read("*a")
  ini_file:close()

  -- substitute pattern with "true"
  local res = string.gsub(content, "PendingRequestsAmount%s*=%s*%d+", "PendingRequestsAmount = 2")

    if res then
      -- now save data with correct value
      ini_file = io.open(srcPath, "w+")
      -- write result into dstfile 
      ini_file:write(res)
      ini_file:close()
    end

  -- check if set successfuly
  local check = string.find(res, "PendingRequestsAmount%s-=%s-2")
  if ( check ~= nil) then 
    print ("value of PendingRequestsAmount = 2")
    return true
  else
    print ("incorrect value of PendingRequestsAmount")
  return false
  end

end

-----------------------Precondition steps before start SDL---------------------------
--------------------------------------------------------------------------
--make reserve copy of smartDeviceLink.ini file
commonPreconditions:BackupFile("smartDeviceLink.ini")
print ("Backuping smartDeviceLink.ini")
--subsitute PendingRequestsAmount to 2
SetPendingRequestsAmountto2()


--///////////////////////////////////////////////////////////////////////////--
--Script cheks TOO_MANY_PENDING_REQUEST resultCode in SubscribeButton response from SDL
--///////////////////////////////////////////////////////////////////////////--

local buttonName = {"OK","PLAY_PAUSE","SEEKLEFT","SEEKRIGHT","TUNEUP","TUNEDOWN", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8","PRESET_9"}



--Precondition: app activation
commonSteps:ActivationApp()

--///////////////////////////////////////////////////////////////////////////--
--Check TOO_MANY_PENDING_REQUEST resultCode in SubscribeButton response from HMI
  function Test:SubscribeButton_TooManyPendingRequest()
  	--Sending 15 SubscribeButton requests
  	for i=1,#buttonName do
		--mobile side: sending SubscribeButton request
		local cid = self.mobileSession:SendRPC("SubscribeButton",
		{
			buttonName = buttonName[i]
		})		
	  end

    --expect response SubscribeButton
    EXPECT_RESPONSE("SubscribeButton")
    	:ValidIf(function(exp,data)
			if 
				data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
		    		TooManyPenReqCount = TooManyPenReqCount+1
		    		print(" \27[32m SubscribeButton response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
					return true
			elseif 
			   	exp.occurences == 15 and TooManyPenReqCount == 0 then 
			  		print(" \27[36m Response SubscribeButton with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
		  			return false
			elseif 
		  		data.payload.resultCode == "SUCCESS" then
		    		print(" \27[32m SubscribeButton response came with resultCode SUCCESS \27[0m")
		    		return true
			else
		    	print(" \27[36m SubscribeButton response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
		    	return false
			end
		end)
		:Times(15)
		:Timeout(5000)


    --expect absence of OnAppInterfaceUnregistered
    EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
    :Times(0)

    --expect absence of BasicCommunication.OnAppUnregistered
    EXPECT_HMICALL("BasicCommunication.OnAppUnregistered")
    :Times(0)

    DelayedExp()
  end

  function Test:RestoreINIFile()
	  print ("restoring smartDeviceLink.ini")
	  commonPreconditions:RestoreFile("smartDeviceLink.ini")
  end

