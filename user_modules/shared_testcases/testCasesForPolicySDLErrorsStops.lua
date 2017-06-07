local testCasesForPolicySDLErrorsStops = {}
local json = require("modules/json")
local SDL = require('modules/SDL')
local commonTestCases =  require ('user_modules/shared_testcases/commonTestCases')
local commonPreconditions =  require ('user_modules/shared_testcases/commonPreconditions')

--[[@GetCountOfRows: Get count of rows in SmartDeviceLinkCore.log file
--! @parameters: NO
--]]
function testCasesForPolicySDLErrorsStops.GetCountOfRows()
  local fileName = commonPreconditions:GetPathToSDL() .. "SmartDeviceLinkCore.log"
  local i = 0
  for _ in io.lines(fileName) do
    i = i + 1
  end
  return i
end

--[[@ReadSpecificMessage: Check if 'message' is printed in SmartDeviceLinkCore.log file
--! @parameters:
--! message - string that has to be found
--! startLine - line in file starting from wich search will be performed (optional)
--]]
function testCasesForPolicySDLErrorsStops.ReadSpecificMessage(message, startLine)
  local fileName = commonPreconditions:GetPathToSDL() .. "SmartDeviceLinkCore.log"
  if not startLine then
    startLine = 1
  end
  local n = 1
  for l in io.lines(fileName) do
    if n >= startLine and string.find(l, message) ~= nil then
      return true
    end
    n = n + 1
  end
  return false
end

--The function will corrupt specific 'section' with data 'specificParameters'
function testCasesForPolicySDLErrorsStops.updatePreloadedPT(section, specificParameters)

  local pathToFile = config.pathToSDL .. "sdl_preloaded_pt.json"

  local file = io.open(pathToFile, "r")
  local json_data = file:read("*a")
  file:close()

  local data = json.decode(json_data)
  if data then
    for key, value in pairs(specificParameters) do
      -- TODO: should be done for all possible sections of preloaded_pt.json
      -- Example:
      if(section == "data.policy_table.module_config") then
        data.policy_table.module_config[key] = value
      elseif(section == "data.policy_table.app_policies") then
        data.policy_table.app_policies[key] = value
      end
    end
  end

  local dataToWrite = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(dataToWrite)
  file:close()
end

--The function checks when SDL will stop before ATF crush.
--TODO(istoimenova): Will be removed when ATF issue is resolved.
function testCasesForPolicySDLErrorsStops:CheckSDLShutdown(self)
  os.execute ("chmod 755 ./files/StartSDLwithoutWait.sh")
  local check_sdlstart = 1
  local stop_test = 1
  local is_test_failed = false
  local timestart = timestamp()

  local function Check()
      local status = SDL:CheckStatusSDL()
      if status == SDL.STOPPED then
        if(check_sdlstart == 1) then
          check_sdlstart = 2
          local result = os.execute ('./files/StartSDLwithoutWait.sh ' .. config.pathToSDL .. ' ' .. config.SDL)
          --local result = os.execute ('./StartSDLwithoutWait.sh ' .. config.pathToSDL .. ' ' .. config.SDL)
          if result then
            print( "SDL will be started" )
            return true
          end
        else
          stop_test = 2
          print( "SDL is STOPPED" )
          is_test_failed = true
        end
        return true
      --elseif(status == SDL.RUNNING) then
        -- print( "SDL is still running" )
        --EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose"):Timeout(1000)
      elseif(status == SDL.CRASH) then
         --StopSDL(self)
         SDL.CRASH = SDL.STOPPED
         print( "SDL is CRASHED" )
         os.execute ('./files/StartSDLwithoutWait.sh ' ..config.pathToSDL .. ' ' .. config.SDL)
         --os.execute ('./StartSDLwithoutWait.sh ' ..config.pathToSDL .. ' ' .. config.SDL)
         stop_test = 2
         StopSDL(self)
         is_test_failed = true
      end
  end

  --TODO(istoimenova): should be checked again, for now 5000->(DelayedExp ~=60 sec)
  for _ = 1, 5000 do
    if(stop_test == 1) then
      Check()
      commonTestCases:DelayedExp(1)
    else
      break
    end
  end
  if(stop_test == 1) then
    local timeend = timestamp()

    print("SDL is still running. "..(timeend - timestart).." msec. elapsed. Verification will be stopped.")
  end
  return is_test_failed
end

return testCasesForPolicySDLErrorsStops
