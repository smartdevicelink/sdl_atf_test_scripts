---------------------------------------------------------------------------------------------------
-- GetPolicyConfigurationData common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.ValidateSchema = false

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local json = require("modules/json")
local utils = require('user_modules/utils')

--[[ Local Variables ]]
local common = {}
common.start = actions.start
common.getHMIConnection = actions.getHMIConnection
common.preconditions = actions.preconditions
common.postconditions = actions.postconditions
common.decode = json.decode
common.is_table_equal = commonFunctions.is_table_equal
common.GetPathToSDL = commonPreconditions.GetPathToSDL
common.read_parameter_from_smart_device_link_ini = commonFunctions.read_parameter_from_smart_device_link_ini
common.jsonFileToTable = utils.jsonFileToTable
common.tableToString = utils.tableToString

local preloadedTable = nil

function common.getPreloadedTable()
  if not preloadedTable then
    local preloadedFile = common:GetPathToSDL()
      .. common:read_parameter_from_smart_device_link_ini("PreloadedPT")
    preloadedTable = common.jsonFileToTable(preloadedFile)
  end
  return preloadedTable
end

function common.GetPolicyConfigurationData(pData)
  local requestId = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",pData.request)
  common.getHMIConnection():ExpectResponse(requestId, pData.response)
  :ValidIf(function(_, data)
    if pData.validIf then
      return pData.validIf(data)
    end
    return true
    end)
end

return common
