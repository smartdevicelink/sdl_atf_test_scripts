---------------------------------------------------------------------------------------------------
--  Precondition:
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with SetCloudAppProperties
--  3) Application defines 2 cloud apps in PT by sending SetCloudAppProperties RPC requests:
--    - AppA (hybridAppPreference=CLOUD)
--    - AppB (hybridAppPreference=BOTH)
--
--  Steps:
--  1) Cloud AppA is registered successfully
--  2) Mobile AppA is trying to register
--  SDL responds with USER_DISALLOWED
--  3) Cloud AppB is registered successfully
--  4) Mobile AppB is trying to register
--  SDL responds with SUCCESS
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/CloudAppRPCs/commonCloudAppRPCs')
local utils = require("user_modules/utils")

--[[ Conditions to scik test ]]
if config.defaultMobileAdapterType == "WS" or config.defaultMobileAdapterType == "WSS" then
  runner.skipTest("Test is not applicable for WS/WSS connection")
end

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function setHybridApp(pAppId, pAppNameCode, pHybridAppPreference)
  local params = {
    properties = {
      nicknames = { "HybridApp" .. pAppNameCode },
      appID = "000000" .. pAppId,
      enabled = true,
      authToken = "ABCD12345" .. pAppId,
      cloudTransportType = "WSS",
      hybridAppPreference = pHybridAppPreference,
      endpoint = "ws://127.0.0.1:8080/"
    }
  }

  local cid = common.getMobileSession():SendRPC("SetCloudAppProperties", params)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getCloudAppStoreConfig(1);
end

local function connectMobDevice()
  local conId = 2
  local deviceInfo = { host = "1.0.0.1", port = config.mobilePort }
  utils.addNetworkInterface(conId, deviceInfo.host)
  common.mobile.createConnection(conId, deviceInfo.host, deviceInfo.port)
  common.mobile.connect(conId)
  :Do(function()
      common.mobile.allowSDL(conId)
    end)
end

local function deleteMobDevices()
  utils.deleteNetworkInterface(2)
end

local function registerApp(pAppId, pConId, pAppNameCode, pResultCode)
  local success
  local occurences
  if pResultCode == "SUCCESS" then
    success = true
    occurences = 1
  elseif pResultCode == "USER_DISALLOWED" then
    success = false
    occurences = 0
  end
  local session = common.getMobileSession(pAppId, pConId)
  session:StartService(7)
  :Do(function()
    local params = utils.cloneTable(common.app.getParams())
    params.appName = "HybridApp" .. pAppNameCode
    params.appID = "000" .. pAppId
    params.fullAppID = "000000" .. pAppId
    local cid = session:SendRPC("RegisterAppInterface", params)
    session:ExpectResponse(cid, { success = success, resultCode = pResultCode })
    session:ExpectNotification("OnPermissionsChange"):Times(occurences)
    session:ExpectNotification("OnHMIStatus"):Times(occurences)
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered"):Times(occurences)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Add additional connection", connectMobDevice)
runner.Step("Define Hybrid App A in PT as CLOUD", setHybridApp, { 2, "A", "CLOUD" })
runner.Step("Define Hybrid App B in PT as BOTH", setHybridApp, { 3, "B", "BOTH" })

runner.Title("Test")
runner.Step("Register Cloud App A SUCCESS", registerApp, { 2, 2, "A", "SUCCESS"})
runner.Step("Register Mobile App A USER_DISALLOWED", registerApp, { 4, 1, "A", "USER_DISALLOWED" })
runner.Step("Register Cloud App B SUCCESS", registerApp, { 3, 2, "B", "SUCCESS"})
runner.Step("Register Mobile App B SUCCESS", registerApp, { 5, 1, "B", "SUCCESS" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Remove additional connection", deleteMobDevices)
