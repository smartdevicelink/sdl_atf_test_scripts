---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3409
---------------------------------------------------------------------------------------------------
-- Description: Check appID in 'BC.OnAppUnregistered' corresponds to 'BC.OnAppRegistered'
-- Multiple transports scenario
--
-- Steps:
-- 1. App is registered via WS transport
-- SDL does:
--  - assign new HMI AppID and provide it in 'BC.OnAppRegistered' notification to HMI
-- 2. App unexpectedly disconnects
-- SDL does:
--  - provide the same HMI AppID in 'BC.OnAppUnregistered' notification to HMI
-- 3. App is registered via TCP transport
-- SDL does:
--  - assign new HMI AppID and provide it in 'BC.OnAppRegistered' notification to HMI
-- 4. App unexpectedly disconnects
-- SDL does:
--  - provide the same HMI AppID in 'BC.OnAppUnregistered' notification to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")
local color = require("user_modules/consts").color
local atf_logger = require("atf_logger")

--[[ Conditions to skip test ]]
if config.defaultMobileAdapterType == "WS" or config.defaultMobileAdapterType == "WSS" then
  runner.skipTest("Test is not applicable for default WS/WSS connection")
end

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = {{webSocketServerSupport = {"ON"}}}

--[[ Local Variables ]]
local numOfApps = 5
local numOfIterations = 10

--[[ Local Functions ]]
local function log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  utils.cprint(color.magenta, str)
end

local function unexpectedDisconnect(pNumOfApps, pMobConnId)
  if not pNumOfApps then pNumOfApps = 1 end
  local exp = {}
  for i = 1, pNumOfApps do
    table.insert(exp, { unexpectedDisconnect = true, appID = common.app.getHMIId(i) })
  end
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", table.unpack(exp))
  :Do(function(_, data)
      log("BC.OnAppUnreg", data.params.appID)
    end)
  :Times(pNumOfApps)
  common.mobile.disconnect(pMobConnId)
  utils.wait(1000)
end

local function registerApp(pAppId, pMobConnId)
  local session = common.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local params = utils.cloneTable(common.app.getParams(pAppId))
      local cid = session:SendRPC("RegisterAppInterface", params)
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appID = common.app.getHMIId(pAppId) } })
      :Do(function(_, data)
          log("BC.OnAppReg", data.params.application.appID)
          common.app.setHMIId(data.params.application.appID, pAppId)
        end)
      session:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    end)
end

local function getWebEngineConParams(pConnectionType)
  if pConnectionType == "TCP" then return config.mobileHost, config.mobilePort end
  if pConnectionType == "WS" then return config.wsMobileURL, config.wsMobilePort end
  if pConnectionType == "WSS" then return config.wssMobileURL, config.wssMobilePort end
end

local function connectDevice(pConnectionType, pMobConnId)
  local url, port = getWebEngineConParams(pConnectionType)
  common.mobile.createConnection(pMobConnId, url, port, common.mobile.CONNECTION_TYPE[pConnectionType])
  common.mobile.connect(pMobConnId)
end

local function start()
  local event = common.run.createEvent()
  common.init.SDL()
  :Do(function()
      common.init.HMI()
      :Do(function()
          common.init.HMI_onReady()
          :Do(function()
              common.hmi.getConnection():RaiseEvent(event, "Start event")
            end)
        end)
    end)
  return common.hmi.getConnection():ExpectEvent(event, "Start event")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", start)

runner.Title("Test")
for it = 1, numOfIterations do
  runner.Title("Iteration " .. it)
  runner.Step("Connect WS device", connectDevice, { "WS", 1 })
  for i = 1, numOfApps do
    runner.Step("Register App " .. i .. " on WS connection", registerApp, { i, 1 })
  end
  runner.Step("Disconnect", unexpectedDisconnect, { numOfApps, 1 })
  runner.Step("Connect TCP device", connectDevice, { "TCP", 2 })
  for i = 1, numOfApps do
    runner.Step("Register App " .. i .. " on TCP connection", registerApp, { i, 2 })
  end
  runner.Step("Disconnect", unexpectedDisconnect, { numOfApps, 2 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
