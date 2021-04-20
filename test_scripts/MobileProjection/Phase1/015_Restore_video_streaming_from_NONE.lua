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
-- 2) and starts video streaming
-- 3)user performs 'user exit'
-- SDL must:
-- 1) stop service
-- 2) after activation start service successfully
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase1/common')
local runner = require('user_modules/script_runner')
local events = require('events')
local constants = require('protocol_handler/ford_protocol_constants')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appHMIType = "NAVIGATION"
local FileForStreaming = "files/SampleVideo_5mb.mp4"
local Service = 11

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].AppHMIType = { appHMIType }
end

local function EndServiceByUserExit()
  local EndServiceEvent = events.Event()
  EndServiceEvent.matches =	function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME
      and data.serviceType == constants.SERVICE_TYPE.VIDEO
      and data.sessionId == common.getMobileSession().sessionId
      and data.frameInfo == constants.FRAME_INFO.END_SERVICE
	end
  common.getMobileSession():ExpectEvent(EndServiceEvent, "Expect EndServiceEvent")
  :DoOnce(function()
      common.getMobileSession():StopStreaming(FileForStreaming)
	    common.getMobileSession():Send({
        frameType = constants.FRAME_TYPE.CONTROL_FRAME,
        serviceType = constants.SERVICE_TYPE.VIDEO,
        frameInfo = constants.FRAME_INFO.END_SERVICE_ACK
	    })
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus", {
    systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
  common.getHMIConnection():ExpectRequest("Navigation.StopStream")
  :Do(function(_, data)
	    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false })
  :Times(AtLeast(1))
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication", {
    appID = common.getHMIAppId(), reason = "USER_EXIT" })
  common.wait(1000)
end

local function RestoreService()
  common.getMobileSession():StartService(Service)
  common.getHMIConnection():ExpectRequest("Navigation.StartStream")
  :Do(function(_,data)
	    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate with HMI types", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)
runner.Step("Start video service", common.startService, { Service })
runner.Step("Start video streaming", common.StartStreaming, { Service, FileForStreaming })

runner.Title("Test")
runner.Step("EndService by USER_EXIT", EndServiceByUserExit)
runner.Step("Activate App after user exit", common.activateApp)
runner.Step("Restoring service", RestoreService)

runner.Title("Postconditions")
runner.Step("Stop service", common.StopService, { Service })
runner.Step("Stop SDL", common.postconditions)
