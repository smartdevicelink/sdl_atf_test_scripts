---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_core/issues/1398
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobiles №1 and №2 are connected to SDL
--
-- Tests:
-- When SDL receives RegisterAppInterface RPC from mobile app, SDL must validate "appName" at first and validate the "appID" at second.
-- In case the app registers with the same "appName" and different "appID" as the already registered one, SDL must return "resultCode: APPLICATION_ALREADY_REGISTERED, success: false" to such app.
-- In case the app registers with the same "appName" and the same "appID" as the already registered one, SDL must return "resultCode: DUPLICATE_NAME, success: false" to such app.
-- In case the app registers with the same "appName" as one of already registered "vrSynonyms" of other apps, SDL must return "resultCode: DUPLICATE_NAME, success: false" to such app. (that is, appName should not coinside with any of VrSynonims of already registered apps)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort }
}

local appParams = {
  [1] = { appName = "EXISTING1", appID = "00000001", fullAppID = "00000001", vrSynonyms = {"VRSYNONYM1"} },
  [2] = { appName = "EXISTING2", appID = "00000002", fullAppID = "00000002", vrSynonyms = {"VRSYNONYM2"} },
  [3] = { appName = "EXISTING3", appID = "00000003", fullAppID = "00000003", vrSynonyms = {"VRSYNONYM3"} },
  [4] = { appName = "EXISTING1", appID = "00000001", fullAppID = "00000001" },
  [5] = { appName = "EXISTING2", appID = "00000005", fullAppID = "00000005" },
  [6] = { appName = "VRSYNONYM3", appID = "0000006", fullAppID = "0000006" },
  [7] = { appName = "UNIQUE1", appID = "00000007", fullAppID = "00000007", vrSynonyms = {"EXISTING1"} }
}

function registerAppExCustom(pAppId, pAppParams, pMobConnId, pResult)
    local appParams = common.app.getParams(pAppId)
    for k, v in pairs(pAppParams) do
      appParams[k] = v
    end
    local session = common.mobile.createSession(pAppId, pMobConnId)
    session:StartService(7)
    :Do(function()
        local corId = session:SendRPC("RegisterAppInterface", appParams)
        session:ExpectResponse(corId, pResult)
      end)
  end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect mobile device to SDL", common.connectMobDevices, {devices})

for i = 1, 3 do
    runner.Step("Register existing app " .. i, common.registerAppExVrSynonyms, { i, appParams[i], 1 })
end

config["application6"] = config["application5"]
config["application7"] = config["application5"]

runner.Title("Test")
runner.Step("Register App With Same AppId and AppName", registerAppExCustom, { 1, appParams[4], 1, { success = false, resultCode = "APPLICATION_REGISTERED_ALREADY" } })
runner.Step("Register App With Different AppId and Same AppName", registerAppExCustom, { 5, appParams[5], 1, { success = false, resultCode = "DUPLICATE_NAME" }  })
runner.Step("Register App With Other App's VR Synonym as Name", registerAppExCustom, { 6, appParams[6], 1, { success = false, resultCode = "DUPLICATE_NAME" }  })
runner.Step("Register App With Other App's Name as VR Synonym", registerAppExCustom, { 7, appParams[7], 1, { success = false, resultCode = "DUPLICATE_NAME" }  })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
