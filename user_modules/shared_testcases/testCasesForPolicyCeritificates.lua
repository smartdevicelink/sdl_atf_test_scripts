require('atf.util')

local testCasesForPolicyCeritificates = {}

local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local json = require('json')

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

--[[@create_ptu_certificate_exist: creates PTU file
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

--[[@ptu: perform PTU
! @parameters:
! self - Test module
]]
function testCasesForPolicyCeritificates.ptu(self)
  local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestId_GetUrls, { result = {code = 0, method = "SDL.GetURLS"}} )
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate" })
      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate" }, "files/ptu_certificate_exist.json")
          EXPECT_HMICALL("BasicCommunication.SystemRequest",
            { requestType = "PROPRIETARY", fileName = SystemFilesPath .. "/PolicyTableUpdate" })
          :Do(function(_, data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                { policyfile = SystemFilesPath .. "/PolicyTableUpdate" })
            end)
          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS" })
        end)
    end)
end

--[[@getServiceType: returns service type by id
! @parameters:
! id - service id
]]
function testCasesForPolicyCeritificates.getServiceType(id)
  if id == 0 then return "CONTROL"
  elseif id == 7 then return "RPC"
  elseif id == 10 then return "PCM"
  elseif id == 11 then return "VIDEO"
  elseif id == 15 then return "BULK_DATA"
  else return tostring(id) end
end

--[[@getFrameInfo: returns frame info by id
! @parameters:
! id - info id
]]
function testCasesForPolicyCeritificates.getFrameInfo(id)
  if id == 0 then return "HEARTBEAT"
  elseif id == 1 then return "START_SERVICE"
  elseif id == 2 then return "START_SERVICE_ACK"
  elseif id == 3 then return "START_SERVICE_NACK"
  elseif id == 4 then return "END_SERVICE"
  elseif id == 5 then return "END_SERVICE_ACK"
  elseif id == 6 then return "END_SERVICE_NACK"
  else return tostring(id) end
end

return testCasesForPolicyCeritificates
