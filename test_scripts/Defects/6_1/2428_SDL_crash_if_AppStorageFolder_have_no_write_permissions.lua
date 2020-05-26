-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/2428
--
-- Precondition:
-- 1) Disallow read and write to AppStorageFolder (set in .ini file) directory.
-- Description:
-- SDL must exit correctly without crash if resumption storage is not initialized.
-- Steps to reproduce:
-- 1) Start SDL.
-- Expected result:
-- SDL cannot initialize resumption storage and exits with code 1.
-- Actual result:
-- Segmentation fault.
--
-- Note:
-- Current script uses `chmod` to change write permissions for storage directory.
-- After the test, permissions are restored. If not, all the following tests will fail.
-- So if current test failed, make sure permissions are restored for storage directory.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require('user_modules/utils')
local Test = require('testbase')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')

--[[ Test settings ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
local storagePath = commonPreconditions.GetPathToSDL() .. SDLConfig:GetValue('AppStorageFolder')
local storagePermissions
local uid

--[[ Local functions ]]
local function execute(command)
  local handle = io.popen(command)
  local result  = handle:read("*a")
  handle:close()
  return result
end

local function writeAllowed()
  local allowed = os.execute('test -w ' .. storagePath)
  if allowed then
    return true
  else
    return false
  end
end

local function defineUser()
  uid = tonumber(execute('id -u'))
  if not uid then
    Test.FailTestCase(_, 'UID cannot be defined!')
    Test.SkipTest()
    return
  end

  if uid == 0 then
    utils.cprint(35, 'Current user is root: UID is ' .. uid)
  else
    utils.cprint(35, 'Current user is non-root: UID is ' .. uid)
  end
end

local function changePermissions()
  if not uid then
    Test.FailTestCase(_, 'UID is not defined!')
    Test.SkipTest()
    return
  end

  os.execute('mkdir ' .. storagePath)
  if uid == 0 then
    os.execute('chattr +i ' .. storagePath)
  else
    storagePermissions = tonumber(execute('stat -c %a ' .. storagePath))
    os.execute('chmod -w ' .. storagePath)
    if writeAllowed() then
      Test.FailTestCase(_, 'Writing to ' .. storagePath .. 'is still allowed.')
      Test.SkipTest()
      return
    end
  end
end

local function restorePermissions()
  if not uid then
    Test.FailTestCase(_, 'UID is not defined!')
    Test.SkipTest()
    return
  end

  if uid == 0 then
    os.execute('chattr -i ' .. storagePath)
  else
    if storagePermissions then
      os.execute('chmod ' .. storagePermissions .. ' ' .. storagePath)
    else
      utils.cprint(35, 'Storage permissions are not defined. Please make sure, permissions have been changed')
    end
  end
end

local function runSDL(timeout)
  if not timeout then timeout = 5 end

  local longCmd = 'cd ' .. commonPreconditions.GetPathToSDL() .. ' && timeout ' .. tostring(timeout) .. ' ./' .. config.SDL ..  ' > /dev/null; echo $?'
  local exCode = tonumber(execute(longCmd))

  if exCode == 1 then
    utils.cprint(35, 'Exit code is ' .. exCode .. '; SDL stopped correctly.')
  elseif exCode == 124 then
    utils.cprint(31, 'Exit code is ' .. exCode .. ' (timeout expired); SDL is running.')
    Test.FailTestCase()
  else
    utils.cprint(31, 'Exit code is ' .. exCode .. '; SDL crashed.')
    Test.FailTestCase()
  end
end

local function help()
  utils.cprint(35,
'Keep in mind that current script uses \
- chmod for non-root user \
- chattr for root user. \
Make sure, permissions restored for storage folder. \
If not, execute one of following commands: \
for root: \
  chattr -i <storage dir> \
for non-root: \
  chmod +w <storage dir> ')
end

-- --[[ Scenario ]]
runner.Title('Preconditions')
runner.Step('ATTENTION', help)
runner.Step('Define current user', defineUser)
runner.Step('Clean environment', common.preconditions)
runner.Step('Change storage directory permissions', changePermissions)

runner.Title('Test')
runner.Step('Run SDL', runSDL, { 5 })

runner.Title('Postconditions')
runner.Step('Restore permissions', restorePermissions)
runner.Step('Restore SDL .ini parameters', common.restoreSDLIniParameters)
