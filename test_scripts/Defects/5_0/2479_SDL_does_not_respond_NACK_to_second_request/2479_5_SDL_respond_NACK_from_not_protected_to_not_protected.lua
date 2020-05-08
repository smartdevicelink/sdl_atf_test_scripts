---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2379
--
-- Description:
-- 1) SDL does not respond NACK on second service: if first service NOT Protected started, second service NOT Protected too.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Security/DTLS/common')
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local constants = require('protocol_handler/ford_protocol_constants')
local events = require('events')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

-- [[ Local functions ]]
local function appStartVideoStreamingNotProtected(pServiceId)
    common.getMobileSession():StartService(pServiceId)
    common.getHMIConnection():ExpectRequest("Navigation.StartStream")
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        common.getMobileSession():StartStreaming(pServiceId, "files/SampleVideo_5mb.mp4")
        common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
    end)
    common.getMobileSession():ExpectNotification("OnHMIStatus")
    :Times(0)
end

local function StartVideoServiceVia2Protocol()
    local StartServiceResponseEvent = events.Event()
    StartServiceResponseEvent.matches =
    function(_, data)
        return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
        data.serviceType == constants.SERVICE_TYPE.VIDEO and
        data.sessionId == common.getMobileSession().sessionId and
        (data.frameInfo == constants.FRAME_INFO.START_SERVICE_NACK or
        data.frameInfo == constants.FRAME_INFO.START_SERVICE_ACK)
    end
    common.getMobileSession():Send({
        frameType = constants.FRAME_TYPE.CONTROL_FRAME,
        serviceType = constants.SERVICE_TYPE.VIDEO,
        frameInfo = constants.FRAME_INFO.START_SERVICE
    })
    common.getMobileSession():ExpectEvent(StartServiceResponseEvent, "Expect StartServiceNACK")
    :ValidIf(function(_, data)
        if data.frameInfo == constants.FRAME_INFO.START_SERVICE_NACK then
            return true
        else
            return false, "StartService ACK received"
        end
    end)
    utils.wait(7000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set DTLS protocol in SDL", common.setSDLIniParameter, { "Protocol", "DTLSv1.0" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Policy Table Update Certificate", common.policyTableUpdate, { common.ptUpdate })
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Start first Service NOT protected and start Stream", appStartVideoStreamingNotProtected, { 11 })
runner.Step("Start video service via 2 protocol with expectation of StartServiceNACK", StartVideoServiceVia2Protocol )

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
