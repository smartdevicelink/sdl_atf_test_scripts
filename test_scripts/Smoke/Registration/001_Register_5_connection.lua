--  Requirement summary:
--  [RegisterAppInterface] SUCCESS
--  [RegisterAppInterface] RegisterAppInterface and HMILevel
--
--  Description:
--  Check that it is able to register up to 5 Apps on different connections via one transport.
--
--  1. Used precondition
--  SDL, HMI are running on system.
--
--  2. Performed steps
--  1st mobile device connect to system
--  appID_1->RegisterAppInterface(params)
--  2nd mobile device connect to system
--  appID_2->RegisterAppInterface(params)
--  3rd mobile device connect to system
--  appID_3->RegisterAppInterface(params)
--  4th mobile device connect to system
--  appID_4->RegisterAppInterface(params)
--  5th mobile device connect to system
--  appID_5->RegisterAppInterface(params)
--
--  Expected behavior:
--  1. SDL successfully registers all five applications and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--  2. SDL assignes HMILevel after application registering:
--     SDL->appID: OnHMIStatus(HMlLevel, audioStreamingState, systemContext)
---------------------------------------------------------------------------------------------------

--[[ Required Shared Libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultMobileAdapterType = "TCP"

--[[ Local Variables ]]
local numOfDevices = 5
local interface
local device = {}

--[[ Local Variables ]]
-- local function split(pStr)
--   local result = {}
--   for match in (pStr.."."):gmatch("(.-)%.") do
--     table.insert(result, match)
--   end
--   return result
-- end

local function execCmd(pCmd)
  local handle = io.popen(pCmd)
  local result = handle:read("*a")
  handle:close()
  return string.gsub(result, "[\n\r]+", "")
end

local function start()
  local event = common.createEvent()
  common.init.SDL()
  :Do(function()
      common.init.HMI()
      :Do(function()
          common.init.HMI_onReady()
          :Do(function()
              common.getHMIConnection():RaiseEvent(event, "Start event")
            end)
        end)
    end)
  return common.getHMIConnection():ExpectEvent(event, "Start event")
end

local function registerApp(pAppId)
  common.createMobileSession(pAppId, nil, pAppId)
  common.getMobileSession(pAppId):StartService(7)
  :Do(function()
      local corId = common.getMobileSession(pAppId):SendRPC("RegisterAppInterface", common.getConfigAppParams(pAppId))
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = {
          appName = common.getConfigAppParams(pAppId).appName,
          appID = common.getHMIAppId(pAppId),
          deviceInfo = {
            name = common.getDeviceName(device[pAppId]),
            id = common.getDeviceMAC(device[pAppId])
          }
        }
      })
      common.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        end)
    end)
end

local function preconditions()
  common.preconditions()
  for i = 1, numOfDevices do
    if execCmd("ip addr | grep " .. device[i]) == "" then
      os.execute("ip addr add " .. device[i] .. "/24 dev " .. interface)
    end
  end
end

local function postconditions()
  common.postconditions()
  for i = 1, numOfDevices do
    if execCmd("ip addr | grep " .. device[i]) ~= "" then
      os.execute("ip addr del " .. device[i] .. "/24 dev " .. interface)
    end
  end
end

local function generateDeviceData()
  interface = execCmd("ip addr | grep " .. config.mobileHost ..  " | rev | awk '{print $1}' | rev")
  common.cprint(35, "Interface:", interface)
  -- local curAddr = split(config.mobileHost, ".")
  common.cprint(35, "IP-addresses:")
  for i = 1, numOfDevices do
    device[i] = string.match(config.mobileHost, ".+%.") .. 50 + i
    common.cprint(35, " " .. device[i])
  end
end

generateDeviceData()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", preconditions)
runner.Step("Start SDL, HMI, connect Mobile", start)

runner.Title("Test")
for i = 1, numOfDevices do
  runner.Step("Create connection " .. i, common.createConnection, { i, device[i] })
  runner.Step("Register App " .. i, registerApp, { i })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", postconditions)
