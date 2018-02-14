---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Application is registered with PROJECTION appHMIType
-- 2) and starts audio services
-- 3) HMI rejects StartStream
-- SDL must:
-- 1) end service
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/PROJECTION/common')
local runner = require('user_modules/script_runner')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local events = require('events')
local constants = require('protocol_handler/ford_protocol_constants')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appHMIType = "PROJECTION"

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getAppID()].AppHMIType = { appHMIType }
end

local function BackUpIniFileAndSetStreamRetryValue()
  commonPreconditions:BackupFile("smartDeviceLink.ini")
  commonFunctions:write_parameter_to_smart_device_link_ini("StartStreamRetry", "3,500")
end

local function RestoreIniFile()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

local function startService()
  common.getMobileSession():StartService(11)
  local EndServiceEvent = events.Event()
  EndServiceEvent.matches =
  function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
    data.serviceType == constants.SERVICE_TYPE.VIDEO and
    data.sessionId == common.getMobileSession().sessionId and
    data.frameInfo == constants.FRAME_INFO.END_SERVICE
  end
  common.getMobileSession():ExpectEvent(EndServiceEvent, "Expect EndServiceEvent")
  :Do(function( )
    common.getMobileSession():Send({
      frameType = constants.FRAME_TYPE.CONTROL_FRAME,
      serviceType = constants.SERVICE_TYPE.VIDEO,
      frameInfo = constants.FRAME_INFO.END_SERVICE_ACK
    })
  end)
  EXPECT_HMICALL("Navigation.StartStream")
  :Do(function(_, data)
    common.getHMIConnection():SendError(data.id, data.method, "REJECTED", "Request is rejected")
  end)
  :Times(4)
  EXPECT_HMICALL("Navigation.StopStream")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("BackUp ini file and set StartStreamRetry value to 3,500", BackUpIniFileAndSetStreamRetryValue)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate with HMI types", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Stop video service by rejecting StartStream", startService)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore ini file", RestoreIniFile)
