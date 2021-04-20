---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2427
---------------------------------
--[[ Required Shared libraries ]]
local common = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local SDL = require('SDL')
local test = require("user_modules/dummy_connecttest")
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2
config.ExitOnCrash = false

--[[ Local Variables ]]
local expNumOfRecords

--[[ Local Functions ]]
local function execCMD(pCmd)
  local handle = io.popen(pCmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

local function waitUntilSDLLoggerIsClosed()
  utils.cprint(35, "Wait until SDL Logger is closed ...")
  local function getNetStat()
    local cmd = "netstat"
      .. " | grep -E '" .. config.sdl_logs_host .. ":" .. config.sdl_logs_port .. "\\s*FIN_WAIT'"
      .. " | wc -l"
    return tonumber(execCMD(cmd))
  end
  while getNetStat() > 0 do
    os.execute("sleep 1")
  end
  os.execute("sleep 1")
end

local function cleanSessions()
  for i = 1, common.getAppsCount() do
    test.mobileSession[i] = nil
    utils.cprint(35, "Mobile session " .. i .. " deleted")
  end
  common.getMobileConnection():Close()
  utils.wait()
end

local function getDataFromPolicyDB()
  local db = commonPreconditions:GetPathToSDL() .. "storage/policy.sqlite"
  local query = "select count(*) from application"
  local result = commonFunctions:get_data_policy_sql(db, query)
  return tostring(result[1])
end

local function ignitionOff()
  expNumOfRecords = getDataFromPolicyDB()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
  end)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      local isSDLStoppedByItself = true
      local count = 0
      while SDL:CheckStatusSDL() == SDL.RUNNING do
        count = count + 1
        if count == 10 then
          SDL:StopSDL()
          waitUntilSDLLoggerIsClosed()
          isSDLStoppedByItself = false
        end
        os.execute("sleep 1")
      end
      if not isSDLStoppedByItself then
        utils.cprint(31, "SDL was not stopped")
      end
      cleanSessions()
    end)
end

local function checkDataInPolicyDB()
  local actNumOfRecords = getDataFromPolicyDB()
  if actNumOfRecords ~= expNumOfRecords then
    test:FailTestCase("Policy DB was corrupted: expected '" .. expNumOfRecords
      .. "' records in 'application' table, actual '" .. actNumOfRecords .. "'")
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Wait", utils.wait)

runner.Title("Test")
runner.Step("Send Ignition Off", ignitionOff)
runner.Step("Start new Ignition Cycle", common.start)
runner.Step("Check Policy DB", checkDataInPolicyDB)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
