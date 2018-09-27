---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2442
--
-- Description:
-- The root cause of the issue is a stack overflow which is occurring due to recursive call of deeply nested areas 
-- and objects. We have readValue(..) which calls readObject(..) or readArray(..), which call readValue(...). 
-- Steps to reproduce:
-- 1) Generate Json file with more than 50 nestings.
-- 2) The starting point is a call to parse(..).
-- Expected:
-- 1) When recursion threshold is exceeded (50 nestings) SDL should STOP.
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local hmi_values = require('user_modules/hmi_values')
local test = require('user_modules/dummy_connecttest')
local utils = require("user_modules/utils")
local SDL = require('SDL')

 -- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--  [[ Local Functions ]]
local function getRTable(deep)
    if nil == deep then deep  = 0 end
    if 0 == deep then
        return {};
    end
    local curentrez = {};
    curentrez[#curentrez .. tostring(deep)] = getRTable(deep - 1);
    return curentrez;    
end

local function getHMIParams()
    local params = hmi_values.getDefaultHMITable()
    JsonTable = getRTable(51)
    params.RC.GetCapabilities.params = JsonTable
    return params
end

local function funcCausesStopOfSDL()
    commonRC.start(getHMIParams())    
    utils.wait(10000)   
end

function failTestCase(pCause)
    test:FailTestCase(pCause)
end

local  function checkStatusSDL()    
    if SDL:CheckStatusSDL() == SDL.STOP  then        
        return true, "SDL was stoped"
    end
    if SDL:CheckStatusSDL() == SDL.RUNNING then
        failTestCase("SDL was not stopped")
    end
end

 --[[ Scenario ]]
 runner.Title("Preconditions")
 runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
 runner.Step("Clean environment", commonRC.preconditions)

 -- [[ Test ]]
runner.Title("Test")
runner.Step("Start SDL, HMI, connect Mobile, start Session", funcCausesStopOfSDL)
runner.Step("Check status SDL", checkStatusSDL)

 -- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions) 
