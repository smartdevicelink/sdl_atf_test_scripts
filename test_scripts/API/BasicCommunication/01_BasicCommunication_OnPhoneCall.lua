 
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1385



---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/BasicCommunication/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local onHMIStatusData = {}
local testCases = {
  [001] = { t = "isActive = true",            m = true,              e = "BasicCommunication.OnPhoneCall" } ,
  [002] = { t = "isActive = false",           m = false,             e = "BasicCommunication.OnPhoneCall" },
  [003] = { t = "Empty method",               m = true,              e = ""},
  [004] = { t = "Empty isActive",             m = "",                e = "BasicCommunication.OnPhoneCall" },
  [005] = { t = "Missing isActive parameter", m = nil,               e = "BasicCommunication.OnPhoneCall"},
  [006] = { t = "Wrong type of method",       m = true,              e = 1234},
  [006] = { t = "Wrong type of isActive",     m = 1234,              e ="BasicCommunication.OnPhoneCall"},
  [007] = { t = "HMI doen't respond",         _,                     e = "" },
  [008] = { t = "Missing all parameters",     _,                     e = "" },
  [009] = { t = "Missing Method parameter",   _,                     e = "" },
  [010] = { t = "Invalid Json",               _,                     e = "" }
}

--[[ Local Functions ]]
local function sendEvent(pTC, pEvent, pIsActive)
 
  local count = 1
  if onHMIStatusData.hmiL == "BACKGROUND" then count = 0 end
  local status = common.cloneTable(onHMIStatusData)
  if pIsActive == true then
    status.hmiL = "BACKGROUND"
    status.aSS = "NOT_AUDIBLE"

  end
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = pEvent,
    isActive = pIsActive })
  common.getMobileSession():ExpectNotification("OnHMIStatus", { hmiLevel = status.hmiL })

  :Times(count)
  common.wait(700)
end



--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "[hmiType:" .. tc.t .. ", isMedia:" .. tostring(tc.m) .. ", event:" .. tc.e .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Register App", common.registerApp)
  runner.Step("Activate App", common.activateApp) 
  runner.Step("Send event from HMI ", sendEvent, { n, tc.e, tc.m })
  runner.Step("Stop SDL", common.postconditions)
end
