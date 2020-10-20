---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Module ]]
local m = require('test_scripts/API/VehicleData/common')

function m.processGetVDsuccess(pData)
  local reqParams = {
     [pData] = true
  }
  local hmiResParams = {
    [pData] = m.vdValues[pData]
  }
  local cid = m.getMobileSession():SendRPC("GetVehicleData", reqParams)
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", reqParams)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResParams)
    end)
  local mobResParams = m.cloneTable(hmiResParams)
  mobResParams.success = true
  mobResParams.resultCode = "SUCCESS"
  m.getMobileSession():ExpectResponse(cid, mobResParams)
end

function m.processGetVDunsuccess(pData)
  local reqParams = {
     [pData] = true
  }
  local cid = m.getMobileSession():SendRPC("GetVehicleData", reqParams)
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", reqParams) :Times(0)
  m.getMobileSession():ExpectResponse(cid, { resultCode = "INVALID_DATA", success = false })
end

function m.processGetVDwithCustomDataSuccess()
  local cid = m.getMobileSession():SendRPC("GetVehicleData", { custom_vd_item1_integer =  true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { OEM_REF_INT = true })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { OEM_REF_INT = 10 })
    end)
  local mobResParams = { custom_vd_item1_integer = 10 }
  mobResParams.success = true
  mobResParams.resultCode = "SUCCESS"
  m.getMobileSession():ExpectResponse(cid, mobResParams)
end

function m.updatePreloadedFile(pUpdateFunc)
  local pt = m.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = m.json.null
  pUpdateFunc(pt)
  m.setPreloadedPT(pt)
end

return m
