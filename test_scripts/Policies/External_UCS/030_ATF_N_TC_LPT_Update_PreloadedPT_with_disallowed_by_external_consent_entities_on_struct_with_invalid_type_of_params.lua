---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] External UCS: PreloadedPT with "disallowed_by_external_consent_entities_on" struct with invalid type of params
--
-- Description:
-- In case:
-- SDL uploads PreloadedPolicyTable with "disallowed_by_external_consent_entities_on:
-- [entityType: <any_type_except_Integer>, entityId: <any_type_except_Integer>]"
-- -> of "<functional grouping>" -> from "functional_groupings" section
-- SDL must:
-- a. consider this PreloadedPT as invalid
-- b. log corresponding error internally
-- c. shut SDL down
--
-- Preconditions:
-- 1. Stop SDL (Ignition Off)
-- 2. Modify PreloadedPolicyTable (add 'disallowed_by_external_consent_entities_on' section)
-- Define not valid data type for entityType and/or entityId parameters
-- 3. Initiate Local Policy Table update by setting 'preloaded_date' parameter
--
-- Steps:
-- 1. Start SDL (Ignition On)
-- 2. Check SDL status
--
-- Expected result:
-- Status = 0 (SDL is stopped)
--
-- Note: Script is designed for EXTERNAL_PROPRIETARY flow
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.ExitOnCrash = false

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local sdl = require('SDL')
local testCasesForExternalUCS = require('user_modules/shared_testcases/testCasesForExternalUCS')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')

--[[ Local variables ]]
local grpId = "Location-1"
local checkedSection = "disallowed_by_external_consent_entities_on"
local params = { "entityId", "entityType" }
local values = {
  { v = "1", desc = "String" },
  { v = 1.23, desc = "Float" },
  { v = {}, desc = "Empty table" },
  { v = { entityType = 1, entityID = 1 }, desc = "Non-empty table" },
  { v = -1, desc = "Below Min" },
  { v = 129, desc = "Beyond Max" },
  { v = "", desc = "Blank" },
  { v = nil, desc = "Null" }
}

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:BackupFile("sdl_preloaded_pt.json")

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:CheckSDLStatus()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.RUNNING)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

local n = 1
local startLine = 1

local function sequence(desc, updateFunc)

  local tcName = "TC[" .. string.format("%02d", n) .. "] - [" .. desc .. "] "
  tcName = tcName .. string.rep("-", 50 - string.len(tcName))

  Test[tcName] = function() end

  function Test:StopSDL_IGNITION_OFF()
    testCasesForExternalUCS.ignitionOff(self)
  end

  function Test:CheckSDLStatus()
    testCasesForExternalUCS.checkSDLStatus(self, sdl.STOPPED)
  end

  function Test.UpdatePreloadedPT()
    testCasesForExternalUCS.updatePreloadedPT(updateFunc)
  end

  function Test.StartSDL()
    StartSDL(config.pathToSDL, config.ExitOnCrash)
    os.execute("sleep 5")
  end

  function Test:CheckSDLStatus()
    testCasesForExternalUCS.checkSDLStatus(self, sdl.STOPPED)
  end

  function Test:CheckLog()
    local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not initialized", startLine)
    if result ~= true then
      self:FailTestCase("Error message was not found in log file")
    end
    startLine = testCasesForPolicySDLErrorsStops.GetCountOfRows()
  end

  n = n + 1

end

local desc
local updateFunc

-- TCs: invalid values for one of parameters
for p = 1, #params do
  for i = 1, #values do
    desc = params[p] .. ": " .. values[i].desc
    updateFunc = function(preloadedTable)
      local function getParamValue(paramName)
        if paramName == params[p] then
          return values[i].v
        else
          return 1
        end
      end
      local function logParamValue(paramName)
        print(paramName .. ": '" .. tostring(getParamValue(paramName)) .. "'")
      end
      logParamValue("entityId")
      logParamValue("entityType")
      preloadedTable.policy_table.module_config.preloaded_date = os.date("%Y-%m-%d")
      preloadedTable.policy_table.functional_groupings[grpId][checkedSection] = {
        {
          entityID = getParamValue("entityId"),
          entityType = getParamValue("entityType"),
        }
      }
    end
    sequence(desc, updateFunc)
  end
end

-- TC: both parameters = nil
desc = "Both parameters = nil"
updateFunc = function(preloadedTable)
  preloadedTable.policy_table.module_config.preloaded_date = os.date("%Y-%m-%d")
  preloadedTable.policy_table.functional_groupings[grpId][checkedSection] = {
    {
      entityID = nil,
      entityType = nil
    }
  }
end
sequence(desc, updateFunc)

-- TC: Count of elements > 100
desc = "Max count of elements"
updateFunc = function(preloadedTable)
  preloadedTable.policy_table.module_config.preloaded_date = os.date("%Y-%m-%d")
  preloadedTable.policy_table.functional_groupings[grpId][checkedSection] = { }
  local maxCount = 100
  for i = 1, maxCount + 1 do
    local element = {
      entityID = i,
      entityType = maxCount + 2 - i
    }
    table.insert(preloadedTable.policy_table.functional_groupings[grpId][checkedSection], element)
  end
end
sequence(desc, updateFunc)

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.StopSDL()
  StopSDL()
end

function Test.RestorePreloadedFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

return Test
