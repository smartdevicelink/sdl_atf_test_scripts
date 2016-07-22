------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
config.defaultProtocolVersion = 2

Test = require('user_modules/connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local mobile  = require('mobile_connection')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local notificationState = {VRSession = false, EmergencyEvent = false, PhoneCall = false}
------------------------------------------------------------------------------------------------------
----------------------------------Steps before start ATF----------------------------------------------
------------------------------------------------------------------------------------------------------
-- delete sdl_snapshot
os.execute( "rm -f /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" )
-- delete app_info.dat, SmartDeviceLinkCore.log, TransportManager.log, ProtocolFordHandling.log, 
-- HmiFrameworkPlugin.log and policy.sqlite
commonSteps:DeleteLogsFileAndPolicyTable()

------------------------------------------------------------------------------------------------------
---------------------------------------Functions used-------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Check direcrory existence 
local function Directory_exist(DirectoryPath)
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

local function RestartSDL(prefix, DeleteStorageFolder)

	Test["Precondition_StopSDL_" .. tostring(prefix) ] = function(self)
		commonFunctions:userPrint(35, "================= Precondition ==================")
		StopSDL()
	end

	if DeleteStorageFolder then
		Test["Precondition_DeleteStorageFolder_" .. tostring(prefix)] = function(self)
			commonSteps:DeleteLogsFileAndPolicyTable()
		end
	end

	Test["Precondition_StartSDL_" .. tostring(prefix) ] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["Precondition_InitHMI_" .. tostring(prefix) ] = function(self)
		self:initHMI()
	end

	Test["Precondition_InitHMI_onReady_" .. tostring(prefix) ] = function(self)
		self:initHMI_onReady()
	end

	Test["Precondition_ConnectMobile_" .. tostring(prefix) ] = function(self)
  		self:connectMobile()
	end

	Test["Precondition_StartSessionRegisterApp_" .. tostring(prefix) ] = function(self)
  		self:startSession()
	end

end

local function StartSDL_Without_stop(self)

	Test["Precondition_StartSDL_" .. tostring(prefix) ] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["Precondition_InitHMI_" .. tostring(prefix) ] = function(self)
		self:initHMI()
	end

	Test["Precondition_InitHMI_onReady_" .. tostring(prefix) ] = function(self)
		self:initHMI_onReady()
	end

	Test["Precondition_ConnectMobile_" .. tostring(prefix) ] = function(self)
  		self:connectMobile()
	end

	Test["Precondition_StartSessionRegisterApp_" .. tostring(prefix) ] = function(self)
  		self:startSession()
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


local function get_preloaded_pt_value(self)   

  local sql_select = "sqlite3 " .. tostring(config.pathToSDL) .. "policy.sqlite \"SELECT preloaded_pt FROM module_config WHERE rowid = 1\""
   
           local aHandle = assert( io.popen( sql_select , 'r'))
    sql_output = aHandle:read( '*l' )
 
    if sql_output then
 
      print (sql_output) 
      
      if tonumber(sql_output) == 1 then
        return true
      else
        return false
      end 
    end
  return nul
end

local function IGNITION_OFF(self, appNumber)
	StopSDL()

	if appNumber == nil then 
		appNumber = 1
	end

	-- hmi side: sends OnExitAllApplications (SUSPENDED)
	self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
		{
		  reason = "IGNITION_OFF"
		})

	-- hmi side: expect OnSDLClose notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

	-- hmi side: expect OnAppUnregistered notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
		:Times(appNumber)
end

local function MASTER_RESET(self)

	-- hmi side: sends OnExitAllApplications (SUSPENDED)
	self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
		{
		  reason = "MASTER_RESET"
		})


	-- hmi side: expect OnSDLClose notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

end

------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- the value of "preloaded_pt" = true can be in case of first database creation based on PreloadedPT 
-- without any changes and updates (APPLINK-25652)

-- stop SDL
function Test:Check1_Precondition_StopSDL()
	commonFunctions:userPrint(35, "================= Precondition ==================")
				IGNITION_OFF(self, 1)
				DelayedExp(1000)
end

--start SDL
function Test:Check1_Precondition_startSDL()
	--RestartSDL("InitialStart", false)
	StartSDL_Without_stop()

end

-- activate App
function Test:Check1_ActivationOfApplication()
	commonFunctions:userPrint(34, "=================== Test Case ===================")
	commonSteps:ActivationApp(nil, "Activating_App")

	DelayedExp(3000)	
end

-- check localpt created
function Test:Check1_LocalPTCreated()

	local ExistDirectoryResult = Directory_exist(tostring(config.pathToSDL) .. "policy.sqlite")
		if ExistDirectoryResult == true then
				commonFunctions:userPrint(33, "localPT is created")
		else
			commonFunctions:userPrint(31, "localPT wasn't created")
	end
end


-- check localPT crated
function Test:Check1_LocalPTUpdated()
    local preloaded_pt = get_preloaded_pt_value()
	    if (preloaded_pt == nil or not preloaded_pt) then
	    commonFunctions:userPrint(31, "localPT wasn't updated")
	  end
end

-- check localpt.preloaded_pt=false
function Test:CheckValueOfPreloaded()  
  preloaded_pt = get_preloaded_pt_value()

  if (preloaded_pt == nil or preloaded_pt) then
    commonFunctions:userPrint(31, "preloaded_pt in localPT is true, should be false")
  end
end


--///////////////////////////////////////////////////////////////////////////////////////////
-- the value of "preloaded_pt" = true can be in case of MASTER_RESET (APPLINK-25652)
-- send master reset
function Test:Check2_ExecuteMasterReset() 
	commonFunctions:userPrint(34, "=================== Test Case ===================")
       MASTER_RESET(self)
end
-- start SDL, register App
function Test:Check2_startSDLAfterMasterReset()
	StartSDL_Without_stop("Restart after MASTER_RESET")
end

-- activate App
function Test:Check2_ActivationOfApplication()
	commonSteps:ActivationApp(nil, "Activating_App")

	DelayedExp(3000)	
end

-- check localPT crated
function Test:Check2_LocalPTCreated()
    local preloaded_pt = get_preloaded_pt_value()
	    if (preloaded_pt == nil or not preloaded_pt) then
	    commonFunctions:userPrint(31, "preloaded_pt in localPT is true, should be false")
	  end
end

-- check localpt.preloaded_pt=false
function Test:Check2_ValueOfPreloaded()  
  preloaded_pt = get_preloaded_pt_value()

  if (preloaded_pt == nil or preloaded_pt) then
    commonFunctions:userPrint(31, "preloaded_pt in localPT is true, should be false")
  end
end
