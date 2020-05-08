--------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local security = require("user_modules/sequences/security")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local common = require("test_scripts/Security/SSLHandshakeFlow/common")
local SDL = require("SDL")

--[[ General configuration parameters ]]
config.serverCertificatePath = "./files/Security/GetSystemTime_certificates/spt_credential.pem"
config.serverPrivateKeyPath = "./files/Security/GetSystemTime_certificates/spt_credential.pem"
config.serverCAChainCertPath = "./files/Security/GetSystemTime_certificates/spt_credential.pem"

--[[ Module ]]
local m = actions

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3
config.isCheckClientCertificate = false
config.application1.registerAppInterfaceParams.appName = "server"
config.application1.registerAppInterfaceParams.fullAppID = "SPT"
m.appHMIType = "DEFAULT"
config.application1.registerAppInterfaceParams.appHMIType = { m.appHMIType }

--[[ Variables ]]
m.frameInfo = security.frameInfo
m.delayedExp = utils.wait
m.readFile = utils.readFile

--[[ Functions ]]
function m.getSystemTimeValue()
  return {
    millisecond = 100,
    second = 30,
    minute = 29,
    hour = 15,
    day = 20,
    month = 3,
    year = 2018,
    tz_hour = -3,
    tz_minute = 10
  }
end

function m.getAppID(pAppId)
  return m.getConfigAppParams(pAppId).appID
end

function m.start(pOnSystemTime, pHMIParams)
  test:runSDL()
  SDL.WaitForSDLStart(test)
  :Do(function()
      test:initHMI()
      :Do(function()
          utils.cprint(35, "HMI initialized")
          test:initHMI_onReady(pHMIParams)
          :Do(function()
              utils.cprint(35, "HMI is ready")
              if pOnSystemTime then
                m.getHMIConnection():SendNotification("BasicCommunication.OnSystemTimeReady")
              end
              test:connectMobile()
              :Do(function()
                  utils.cprint(35, "Mobile connected")
                  m.allowSDL(test)
                end)
            end)
        end)
    end)
end

local function expectHandshakeMessage(pGetSystemTimeOccur, pTime, pHandshakeOccurences)
  m.getMobileSession():ExpectHandshakeMessage()
  :Times(pHandshakeOccurences)

  EXPECT_HMICALL("BasicCommunication.GetSystemTime")
  :Do(function(_, d)
    m.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { systemTime = pTime })
  end)
  :Times(pGetSystemTimeOccur)
end

function m.startServiceSecured(pData, pServiceId, pGetSystemTimeOccur, pTime, pHandshakeOccurences)
  m.getMobileSession():StartSecureService(pServiceId)
  m.getMobileSession():ExpectControlMessage(pServiceId, pData)

  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate")
  :Times(0)

  expectHandshakeMessage(pGetSystemTimeOccur, pTime, pHandshakeOccurences)
end

function m.startServiceSecuredwithPTU(pData, pServiceId, pGetSystemTimeOccur, pTime, pPTUpdateFunc, pHandshakeOccurences)
  m.getMobileSession():StartSecureService(pServiceId)
  m.getMobileSession():ExpectControlMessage(pServiceId, pData)

  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
    :Times(3)
    :Do(function(e)
      if e.occurences == 1 then
        m.policyTableUpdate(pPTUpdateFunc)
      end
    end)

  expectHandshakeMessage(pGetSystemTimeOccur, pTime, pHandshakeOccurences)
end

m.postconditions = common.postconditions

local preconditionsOrig = m.preconditions
function m.preconditions()
  preconditionsOrig()
  common.initSDLCertificates("./files/Security/GetSystemTime_certificates/client_credential.pem", false)
end

return m
