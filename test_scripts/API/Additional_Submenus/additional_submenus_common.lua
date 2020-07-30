local common = require('test_scripts/Smoke/commonSmoke')

local function reverseArray(arr)
    local rev = {}
    for i=#arr, 1, -1 do
        rev[#rev+1] = arr[i]
    end
    return rev
end

common.reqParams = {
    AddCommand = {
      mob = { cmdID = 1, vrCommands = { "OnlyVRCommand" }}
    },
    AddSubMenu = {
      mob = { menuID = 1, position = 500, menuName = "SubMenu" }
    }
  }

function common.addSubMenu(requestParams)
    if requestParams == nil then
        requestParams = common.reqParams.AddSubMenu.mob
    end
    local parentPresent = (requestParams.parentID ~= nil)
    local hmiRequestParams = {
        menuID = requestParams.menuID, 
        menuParams = {
          position = requestParams.position,
          menuName = requestParams.menuName
        }
     }
    local cid = common.getMobileSession():SendRPC("AddSubMenu", requestParams)
    common.getHMIConnection():ExpectRequest("UI.AddSubMenu", hmiRequestParams)
    :ValidIf(function(_, data)
        if parentPresent == true then
            return true
        else
            return data.params.menuParams["parentID"] == nil or data.params.menuParams["parentID"] == 0
        end
      end)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession():ExpectNotification("OnHashChange")
    :Do(function(_, data)
        common.hashId = data.payload.hashID
      end)
end

function common.addCommand(mobileParams)
    local hmiRequestParams = mobileParams
    if requestParams == nil then
        requestParams = common.reqParams.AddCommand.mob
        hmiRequestParams = common.reqParams.AddCommand.hmi
    end

    local cid = common.getMobileSession():SendRPC("AddCommand", mobileParams)
    common.getHMIConnection():ExpectRequest("UI.AddCommand", hmiParams)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession():ExpectNotification("OnHashChange")
    :Do(function(_, data)
        common.hashId = data.payload.hashID
    end)
end

function common.DeleteSubMenu(mobileParams, hmiDeleteCommandParams, hmiDeleteSubMenuParams)
    local cid = common.getMobileSession():SendRPC("DeleteSubMenu", mobileParams)

    common.getHMIConnection():ExpectRequest("UI.DeleteCommand", 
        unpack(reverseArray(hmiDeleteCommandParams))
    )
    :Times(#hmiDeleteCommandParams)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    common.getHMIConnection():ExpectRequest("UI.DeleteSubMenu", 
        unpack(reverseArray(hmiDeleteSubMenuParams))
    )
    :Times(#hmiDeleteSubMenuParams)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

return common
