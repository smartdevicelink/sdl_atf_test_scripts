---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0149-mt-registration-limitation.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. App is connected with PROJECTION, NAVIGATION appHMIType and isMediaApplication=true
-- 2. Command1, Command2, Command3 commands with vrCommands are added
-- 3. Session is restarted
-- 4. High bandwidth transport is not connected
-- SDL does:
-- 1. Resume commands added in previous session
-- 2. Resume app to highest HMI level between `NavigationLowBandwidthResumptionLevel`, 
--    `ProjectionLowBandwidthResumptionLevel`, and `MediaLowBandwidthResumptionLevel`
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/ConditionalResumption/common')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.isMediaApplication = true
runner.testSettings.isSelfIncluded = false

function resumptionLevelMedia()
  common.getHMIConnection():ExpectNotification("BasicCommunication.ActivateApp"):Times(1)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE" },
    { hmiLevel = "FULL" })
  :Times(2)
end

local option = "EmptyApp"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Set appHMIType", common.setAppHMIType, { 1, {"NAVIGATION", "PROJECTION"} })
runner.Step("Clean environment", common.preconditions)
runner.Step("Set resumption config for " .. option, common.write_parameter_to_smart_device_link_ini, 
  { option .. "TransportRequiredForResumption", "IAP_USB" })
runner.Step("Set HMI level config for " .. option, common.writeLowBandwidthResumptionLevel, { "Navigation", "LIMITED" })
runner.Step("Set HMI level config for " .. option, common.writeLowBandwidthResumptionLevel, { "Projection", "BACKGROUND" })
runner.Step("Set HMI level config for " .. option, common.writeMediaLowBandwidthResumptionLevel, { "FULL" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Pin OnHashChange", common.pinOnHashChange)
runner.Step("App activation", common.activateApp)
for i = 1,3 do
  runner.Step("AddCommand" .. i, common.addCommand, { common.getAddCommandParams(i) })
end
  
runner.Title("Test")
runner.Step("App reconnect", common.reconnect)
runner.Step("App resumption", common.registrationWithResumption,
  { 1, resumptionLevelMedia, common.resumptionDataAddCommands })
  
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)