---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Security/SSLHandshakeFlow/common")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local SDL = require("SDL")
local constants = require("protocol_handler/ford_protocol_constants")
local atf_logger = require("atf_logger")

--[[ General configuration parameters ]]
config.SecurityProtocol = "DTLS"
config.application1.registerAppInterfaceParams.appName = "server"
config.application1.registerAppInterfaceParams.fullAppID = "spt"
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application2.registerAppInterfaceParams.appName = "server2"
config.application2.registerAppInterfaceParams.fullAppID = "spt2"
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Module ]]
local m = common

--[[ Proxy Functions ]]
m.wait = utils.wait
m.const = constants
m.pt = utils.printTable
m.cprint = utils.cprint
m.readFile = utils.readFile
m.SDL = { PTS = SDL.PTS }

--[[ Common Functions ]]
function m.failTestCase(pReason)
  test:FailTestCase(pReason)
end

function m.sendGetSystemTimeResponse(pId, pMethod)
  local st = {
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
  m.getHMIConnection():SendResponse(pId, pMethod, "SUCCESS", { systemTime = st })
end

function m.start()
  test:runSDL()
  SDL.WaitForSDLStart(test)
  :Do(function()
      utils.cprint(35, "SDL started")
      test:initHMI()
      :Do(function()
          utils.cprint(35, "HMI initialized")
          test:initHMI_onReady()
          :Do(function()
              utils.cprint(35, "HMI is ready")
              m.getHMIConnection():SendNotification("BasicCommunication.OnSystemTimeReady")
              test:connectMobile()
              :Do(function()
                  utils.cprint(35, "Mobile connected")
                  m.allowSDL()
                end)
            end)
        end)
    end)
end

function m.ptUpdate(pTbl)
  local filePath = "./files/Security/client_credential.pem"
  local crt = utils.readFile(filePath)
  pTbl.policy_table.module_config.certificate = crt
end

local preconditionsOrig = common.preconditions
function m.preconditions(pForceProtectedServices, pForceUnprotectedServices)
  preconditionsOrig()
  if not pForceProtectedServices then pForceProtectedServices = "Non" end
  if not pForceUnprotectedServices then pForceUnprotectedServices = "Non" end
  m.setSDLIniParameter("ForceProtectedService", pForceProtectedServices)
  m.setSDLIniParameter("ForceUnprotectedService", pForceUnprotectedServices)
end

local postconditionsOrig = common.postconditions
function m.postconditions()
  postconditionsOrig()
  m.restoreSDLIniParameters()
end

function m.decryptCertificateRes(pId, pMethod)
  m.getHMIConnection():SendResponse(pId, pMethod, "SUCCESS", { })
end

function m.policyTableUpdateSuccess(pPTUpdateFunc)
  local function expNotificationFunc()
    m.getHMIConnection():ExpectRequest("BasicCommunication.DecryptCertificate")
    :Do(function(_, data)
        m.decryptCertificateRes(data.id, data.method)
      end)
    :Times(AtMost(1))
    :Timeout(15000)
    m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
    :Timeout(15000)
  end
  m.isPTUStarted()
  :Do(function(e, data)
      if e.occurences == 1 then
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        m.policyTableUpdate(pPTUpdateFunc, expNotificationFunc)
      end
    end)
end

function m.policyTableUpdateUnsuccess()
  local pPTUpdateFunc = function(pTbl)
    pTbl.policy_table.app_policies = nil
  end
  local expNotificationFunc = function()
    common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData")
    :Times(0)
    common.getHMIConnection():ExpectRequest("BasicCommunication.DecryptCertificate")
    :Times(0)
  end
  m.isPTUStarted()
  :Do(function(e, data)
      if e.occurences == 1 then
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        common.policyTableUpdate(pPTUpdateFunc, expNotificationFunc)
      end
    end)
  :Times(AtLeast(1))
end

function m.policyTableUpdateFunc()
  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
  :Times(3)

  m.policyTableUpdateSuccess(m.ptUpdate)
end

function m.startServiceFunc(pServiceId, pAppId)
  m.getMobileSession(pAppId):StartSecureService(pServiceId)
end

m.serviceData = {
  [7] = {
    forceCode = "0x07",
    serviceType = "RPC",
    startStreamFunc = function() end,
    streamingFunc = function() end
  },
  [10] = {
    forceCode = "0x0A",
    serviceType = "AUDIO",
    startStreamFunc = function()
      m.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
      :Do(function(_, data)
          m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
      :Times(AnyNumber())
    end
  },
  [11] = {
    forceCode = "0x0B",
    serviceType = "VIDEO",
    startStreamFunc = function()
      m.getHMIConnection():ExpectRequest("Navigation.StartStream")
      :Do(function(_, data)
          m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
      :Times(AnyNumber())
    end
  }
}

function m.startServiceWithOnServiceUpdate(pServiceId, pHandShakeExpeTimes, pGSTExpTimes, pAppId)
  if not pAppId then pAppId = 1 end

  m.startServiceFunc(pServiceId, pAppId)

  m.getHMIConnection():ExpectRequest("BasicCommunication.GetSystemTime")
  :Do(function(_, data)
      m.sendGetSystemTimeResponse(data.id, data.method)
    end)
  :Times(pGSTExpTimes)

  m.serviceData[pServiceId].startStreamFunc()

  m.onServiceUpdateFunc(m.serviceData[pServiceId].serviceType, pAppId)

  m.policyTableUpdateFunc()

  m.getMobileSession(pAppId):ExpectHandshakeMessage()
  :Times(pHandShakeExpeTimes)

  m.serviceResponseFunc(pServiceId, pAppId)
end

function m.setMobileCrt(pCrtFile)
  for _, v in pairs({"serverCertificatePath", "serverPrivateKeyPath", "serverCAChainCertPath" }) do
    config[v] = pCrtFile
  end
end

function m.log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  utils.cprint(35, str)
end

function m.checkResult(pResult)
  common.cprint(35, "retryFinishedTime:", pResult.retryFinishedTime)
  common.cprint(35, "serviceNackTime:", pResult.serviceNackTime)
  common.cprint(35, "onServiceUpdateTime:", pResult.onServiceUpdateTime)
  local tolerance = 200 -- ms
  local msg = ""
  if pResult.retryFinishedTime == 0 then
    msg = msg .. "\nRetry sequence was not finished"
  else
    if pResult.serviceNackTime == 0 then
      msg = msg .. "\nSTART_SERVICE_NACK was not sent by SDL"
    end
    local delay = math.abs(pResult.serviceNackTime - pResult.retryFinishedTime)
    common.cprint(35, "Delay serviceNackTime vs retryFinishedTime (ms):", delay)
    if math.abs(delay - tolerance) > tolerance then
      msg = msg .. "\nThere to much delay between START_SERVICE_NACK and finishing of Retry sequence"
    end
    delay = math.abs(pResult.onServiceUpdateTime - pResult.retryFinishedTime)
    common.cprint(35, "Delay onServiceUpdateTime vs retryFinishedTime (ms):", delay)
    if math.abs(delay - tolerance) > tolerance then
      msg = msg .. "\nThere to much delay between OnServiceUpdate notification and finishing of Retry sequence"
    end
  end
  if string.len(msg) > 0 then
    m.failTestCase(msg)
  end
end

return m
