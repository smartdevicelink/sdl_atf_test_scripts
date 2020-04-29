Test = require('connecttest')
common_functions = require('user_modules/common_functions')
common_steps = require('user_modules/common_steps')
const = require('user_modules/consts')
json = require('json4lua/json/json')
require('user_modules/AppTypes')
mobile_session = require('mobile_session')
module = require('testbase')
require('cardinalities')
events = require('events')
mobile = require('mobile_connection')
file_connection = require('file_connection')
expectations = require('expectations')
Expectation = expectations.Expectation
sdl = require('SDL')
update_policy = require('user_modules/shared_testcases_custom/testCasesForPolicyTable')
common_preconditions = require('user_modules/shared_testcases_custom/commonPreconditions')
sdl_config = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
-- Remove default precondition from connecttest.lua
common_functions:RemoveTest("RunSDL", Test)
common_functions:RemoveTest("InitHMI", Test)
common_functions:RemoveTest("InitHMI_onReady", Test)
common_functions:RemoveTest("ConnectMobile", Test)
common_functions:RemoveTest("StartSession", Test)
common_functions:CheckSdlPath()
-------------------- Set default settings for ATF script --------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2
common_functions:DeleteLogsFileAndPolicyTable()
if common_functions:IsFileExist("sdl.pid") then
  os.execute("rm sdl.pid")
end
os.execute("kill -9 $(ps aux | grep -e smartDeviceLinkCore | awk '{print$2}')")
-- Remove app_info.dat to avoid resumption.
if common_functions:IsFileExist(config.pathToSDL  .. "app_info.dat") then
  os.execute("rm -rf " .. config.pathToSDL  .. "app_info.dat")
end
local path_to_sdl_without_bin = string.gsub(config.pathToSDL, "bin/", "")
local sdl_bin_bk = path_to_sdl_without_bin .. "sdl_bin_bk/"
if common_functions:IsDirectoryExist(sdl_bin_bk) == false then
  os.execute("mkdir " .. sdl_bin_bk)
end
if common_functions:IsFileExist(sdl_bin_bk .. "hmi_capabilities.json") then
  os.execute("cp -f -r " .. sdl_bin_bk .. "hmi_capabilities.json " .. config.pathToSDL)
else
  os.execute("cp -f -r " .. config.pathToSDL .. "hmi_capabilities.json " ..  sdl_bin_bk .. "hmi_capabilities.json")
end
if common_functions:IsFileExist(sdl_bin_bk .. "smartDeviceLink.ini") then
  os.execute("cp -f -r " .. sdl_bin_bk .. "smartDeviceLink.ini " .. config.pathToSDL)
else
  os.execute("cp -f -r " .. config.pathToSDL .. "smartDeviceLink.ini " ..  sdl_bin_bk .. "smartDeviceLink.ini")
end
if common_functions:IsFileExist(sdl_bin_bk .. "sdl_preloaded_pt.json") then
  os.execute("cp -f -r " .. sdl_bin_bk .. "sdl_preloaded_pt.json " .. config.pathToSDL)
else
  os.execute("cp -f -r " .. config.pathToSDL .. "sdl_preloaded_pt.json " ..  sdl_bin_bk .. "sdl_preloaded_pt.json")
end
