require('atf.util')

local testCasesForPolicyCeritificates = {}

local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local json = require('json')
local events = require('events')
local Event = events.Event

--[[@update_preloaded_pt: update sdl_preloaded_pt
! @parameters:
! app_id - Id of application that will be included sdl_preloaded_pt.json
! include_certificate - true / false: true - certificate will be added in module_config
! update_retry_sequence - array with new values for seconds_between_retries.
]]
function testCasesForPolicyCeritificates.update_preloaded_pt(app_id, include_certificate, update_retry_sequence, timeout_after_x_seconds)
  if not timeout_after_x_seconds then timeout_after_x_seconds = 30 end
  commonPreconditions:BackupFile("sdl_preloaded_pt.json")
  local config_path = commonPreconditions:GetPathToSDL()

  local pathToFile = config_path .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all")
  file:close()

  local data = json.decode(json_data)
  if(data.policy_table.functional_groupings["DataConsent-2"]) then
    data.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  end

  data.policy_table.functional_groupings["Base-4"].rpcs.SetAudioStreamingIndicator = nil
  data.policy_table.functional_groupings["Base-4"].rpcs.SetAudioStreamingIndicator = { hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }}

  if (update_retry_sequence ~= nil) then
    data.policy_table.module_config.seconds_between_retries = update_retry_sequence
    data.policy_table.module_config.timeout_after_x_seconds = timeout_after_x_seconds
  end

  if(app_id ~= nil) then
    data.policy_table.app_policies[app_id] = nil
	  data.policy_table.app_policies[app_id] =
	  {
	    keep_context = false,
	    steal_focus = false,
	    priority = "NONE",
	    default_hmi = "NONE",
	    groups = {"Base-4"}
	  }
	end

  if(include_certificate == true) then
    io.input("files/Security/spt_credential.pem")
    local str_certificate = ""
    for line in io.lines() do
      str_certificate = str_certificate .. line .."\r\n"
    end

    data.policy_table.module_config.certificate = str_certificate
  end

  file = io.open(config_path .. 'sdl_preloaded_pt.json', "w")
  file:write(json.encode(data))
  file:close()
end

--[[@create_ptu_certificate_exist: creates PTU file:
! ptu_certificate_exist.json: module_config section contains certificate.
! @parameters:
! include_certificate - true / false: true - certificate will be added in module_config
! invalid_ptu - will add omit values + remove seconds_between_retries section -> PT file will become invalid.
]]
function testCasesForPolicyCeritificates.create_ptu_certificate_exist(include_certificate, invalid_ptu)
  local config_path = commonPreconditions:GetPathToSDL()
  local pathToFile = config_path .. 'sdl_preloaded_pt.json'

  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all")
  file:close()

  local data = json.decode(json_data)
  if(data.policy_table.functional_groupings["DataConsent-2"]) then
    data.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  end

  if(invalid_ptu ~= true) then
    data.policy_table.module_config.preloaded_pt = nil
    data.policy_table.module_config.preloaded_date = nil
  else
    data.policy_table.module_config.preloaded_pt = true
    data.policy_table.module_config.preloaded_date = "2017-04-13"
    data.policy_table.module_config.seconds_between_retries = nil
  end

  if(include_certificate == true) then
    io.input("files/Security/spt_credential.pem")
    local str_certificate = ""
    for line in io.lines() do
      str_certificate = str_certificate .. line .."\r\n"
    end

    data.policy_table.module_config.certificate = str_certificate
  end

  data = json.encode(data)
  file = io.open("files/ptu_certificate_exist.json", "w")
  file:write(data)
  file:close()
end

--[[@start_service_NACK: send specific protocol message with expected result NACK
! @parameters:
! msg - message with specific service and payload
! service - protocol service of msg
! name - protocol name of service for specified msg
]]
function testCasesForPolicyCeritificates.start_service_NACK(self, msg, service, name)
  self.mobileSession:Send(msg)

  local startserviceEvent = Event()
  startserviceEvent.matches =
  function(_, data)
    return ( data.frameType == 0 and data.serviceType == service)
  end

  self.mobileSession:ExpectEvent(startserviceEvent, "Service "..service..": StartServiceNACK")
  :ValidIf(function(_, data)
    if data.frameInfo == 2 then
      commonFunctions:printError("Service "..service..": StartServiceACK is received")
      return false
    elseif data.frameInfo == 3 then
      print("Service "..service..": "..name.." NACK")
      return true
    else
      commonFunctions:printError("Service "..service..": StartServiceACK/NACK is not received at all.")
      return false
    end
  end)

  commonTestCases:DelayedExp(10000)
end

--[[@StartService_encryption: send specific service with flag encryption true
! as result will check received ACK / NACK / No Response for service 0x07
! @parameters:
! service - protocol service of msg
]]
function testCasesForPolicyCeritificates.StartService_encryption(self,service)

  if service ~= 7 and self.mobileSession.sessionId == 0 then error("Session cannot be started") end
  local startSession =
  {
    frameType = 0,
    serviceType = service,
    frameInfo = 1,
    sessionId = self.mobileSession.sessionId,
    encryption = true
  }
  self.mobileSession:Send(startSession)

  -- prepare event to expect
  local startserviceEvent = Event()
  startserviceEvent.matches = function(_, data)
    return data.frameType == 0 and
    data.serviceType == service and
    (service == 7 or data.sessionId == self.mobileSession.sessionId) and
    (data.frameInfo == 2 or -- Start Service ACK
      data.frameInfo == 3) -- Start Service NACK
  end

  self.mobileSession:ExpectEvent(startserviceEvent, "StartService ACK")
  :ValidIf(function(_, data)
    if ( service == 7 ) then
      self.mobileSession.sessionId = data.sessionId
      self.mobileSession.hashCode = data.binaryData
    end

    if ( data.frameInfo == 2 ) then
      print("StartServiceACK, encryption: false")
      if(data.encryption == true) then
        commonFunctions:printError("Encryption flag should not be set.")
        return false
      end
      return true
    else
      return false, "StartService NACK received"
    end
  end)
end

return testCasesForPolicyCeritificates
