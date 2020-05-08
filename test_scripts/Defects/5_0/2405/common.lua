---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")
local json = require("modules/json")

local m = common

m.EMPTY_ARRAY = json.EMPTY_ARRAY

local ptuOrig = common.policyTableUpdate
function m.policyTableUpdate(pGrp)
  local function ptUpdate(pTbl)
    local dfltGrpData = {
      rpcs = {
        GetVehicleData = {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
        }
      }
    }
    local fg = pTbl.policy_table.functional_groupings
    local appId = common.getConfigAppParams().fullAppID
    if not pTbl.policy_table.app_policies[appId] then
      pTbl.policy_table.app_policies[appId] = utils.cloneTable(pTbl.policy_table.app_policies.default)
    end
    pTbl.policy_table.app_policies[appId].groups = { "Base-4" }
    for i = 1, #pGrp do
      fg[pGrp[i].name] = utils.cloneTable(dfltGrpData)
      fg[pGrp[i].name].user_consent_prompt = pGrp[i].prompt
      fg[pGrp[i].name].rpcs.GetVehicleData.parameters = pGrp[i].params
      table.insert(pTbl.policy_table.app_policies[appId].groups, pGrp[i].name)
    end
  end
  ptuOrig(ptUpdate)
end

local function getGroupId(pData, pGrpName)
  for i = 1, #pData.result.allowedFunctions do
    if(pData.result.allowedFunctions[i].name == pGrpName) then
      return pData.result.allowedFunctions[i].id
    end
  end
end

function m.getListOfPermissions(pGrp)
  local rid = common.getHMIConnection():SendRequest("SDL.GetListOfPermissions")
  common.getHMIConnection():ExpectResponse(rid)
  :Do(function(_,data)
      for i = 1, #pGrp do
        pGrp[i].id = getGroupId(data, pGrp[i].prompt)
        print(pGrp[i].name .. ":", tostring(pGrp[i].id))
      end
    end)
end

local function consentGroupsByAFewMsg(pGrp)
  local count = 0
  for i = 1, #pGrp do
    if pGrp[i].id then
      count = count + 1
      common.getHMIConnection():SendNotification("SDL.OnAppPermissionConsent", {
          appID = common.getHMIAppId,
          source = "GUI",
          consentedFunctions = {{ name = pGrp[i].prompt, id = pGrp[i].id, allowed = true }}
        })
    end
  end
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
  :Times(count)
end

local function consentGroupsBySingleMsg(pGrp)
  local consentedFunctions = {}
  for i = 1, #pGrp do
    if pGrp[i].id then
      table.insert(consentedFunctions, { name = pGrp[i].prompt, id = pGrp[i].id, allowed = true })
    end
  end
  common.getHMIConnection():SendNotification("SDL.OnAppPermissionConsent", {
      appID = common.getHMIAppId,
      source = "GUI",
      consentedFunctions = consentedFunctions
    })
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
end

function m.consentGroups(pGrp)
  consentGroupsBySingleMsg(pGrp)
end

function m.getVD(pParam, pResultCode, pSuccess)
  local valMap = {
    speed = 1.11,
    rpm = 222
  }
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { [pParam] = true })
  if pSuccess == true then
    common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData")
    :Do(function(_,data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = valMap[pParam] })
      end)
  end
  common.getMobileSession():ExpectResponse(cid, { success = pSuccess, resultCode = pResultCode })
end

return m
