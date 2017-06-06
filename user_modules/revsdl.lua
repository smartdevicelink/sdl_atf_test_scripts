-- This script contains common functions to run REVSDL scripts

local revsdl_module = {}

--! @brief Adds to function_id.lua RPCs that are unknown for SDL but known to CANCooperation plugin
function revsdl_module.AddUnknownFunctionIDs()

  -- check if file was backed-up before; backup if was not
  local command_to_execute = "ls -l ./backup_atf_files/ | grep function_id.lua | wc -l"
  local execute = assert( io.popen(command_to_execute, 'r'))
  local result = tostring(execute:read( '*l' ))
  if result == "0" then -- if no back-up file
    command_to_execute = "mkdir backup_atf_files; cp ./modules/function_id.lua ./backup_atf_files/"
    os.execute(command_to_execute)

    -- read file
    command_to_execute = "./modules/function_id.lua"
    f = assert(io.open(command_to_execute, "r"))
    fileContent = f:read("*all")
    f:close()

    -- strings that should be add in function_id.lua
    local pattern = "return module.mobile_functions"
    local button_press_id = "module.mobile_functions[\"ButtonPress\"] = 100015"
    local get_interior_data_id = "module.mobile_functions[\"GetInteriorVehicleData\"] = 100017"
    local get_interior_capabilities_id = "module.mobile_functions[\"GetInteriorVehicleDataCapabilities\"] = 100016"
    local set_interior_data_id = "module.mobile_functions[\"SetInteriorVehicleData\"] = 100018"
    local on_interior_vehicle_data_id = "module.mobile_functions[\"OnInteriorVehicleData\"] = 100019"
    local replace = button_press_id .. "\n" ..
            get_interior_data_id .. "\n" ..
            get_interior_capabilities_id .. "\n" ..
            set_interior_data_id .. "\n" ..
            on_interior_vehicle_data_id .. "\n" ..
            pattern

    -- add unknown to SDL function IDs
    fileContent  =  string.gsub(fileContent, pattern, replace)
    f = assert(io.open(command_to_execute, "w+"))
    f:write(fileContent)
    f:close()
  end
end

--! @brief customizes InitHMI function in connecttest.lua to register RC interface
function revsdl_module.SubscribeToRcInterface()

  -- check if file was back-up before, backup if not
  local command_to_execute = "ls -l ./backup_atf_files/ | grep connecttest.lua | wc -l"
  local execute = assert( io.popen(command_to_execute, 'r'))
  local result = tostring(execute:read( '*l' ))
  if result == "0" then
    command_to_execute = "mkdir backup_atf_files; cp ./modules/connecttest.lua ./backup_atf_files/"
    os.execute(command_to_execute)
    -- read file
    command_to_execute = "./modules/connecttest.lua"
    f = assert(io.open(command_to_execute, "r"))

    fileContent = f:read("*all")
    f:close()

    local pattern = "registerComponent..VehicleInfo..\n"
    local to_add = "registerComponent(\"RC\")\n"
    local replace = "registerComponent(\"VehicleInfo\")\n\t\t\t" .. to_add
    fileContent  =  string.gsub(fileContent, pattern, replace)

    f = assert(io.open(command_to_execute, "w+"))
    f:write(fileContent)
    f:close()
  end
end


function revsdl_module.arrayGroups_PrimaryRC( )
  return
          {
              permissionItem = {
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED"},
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "AddCommand"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED"},
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "AddSubMenu"
                  },
                  {
                   hmiPermissions = {
                    allowed = {"FULL", "LIMITED"},
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "Alert"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "ButtonPress"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "ChangeRegistration"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED"},
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "CreateInteractionChoiceSet"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED"},
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "DeleteCommand"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "DeleteFile"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED"},
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "DeleteInteractionChoiceSet"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED"},
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "DeleteSubMenu"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "EncodedSyncPData"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED"},
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "EndAudioPassThru"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED"},
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "GenericResponse"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "GetInteriorVehicleData"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "GetInteriorVehicleDataCapabilities"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "ListFiles"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnAppInterfaceUnregistered"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnAudioPassThru"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnButtonEvent"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnButtonPress"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnCommand"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnDriverDistraction"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnEncodedSyncPData"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnHMIStatus"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnHashChange"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnInteriorVehicleData"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnLanguageChange"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnPermissionsChange"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "OnSystemRequest"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "PerformAudioPassThru"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "PerformInteraction"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "PutFile"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "RegisterAppInterface"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "ResetGlobalProperties"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "FULL" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "ScrollableMessage"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "SetAppIcon"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "SetDisplayLayout"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "SetGlobalProperties"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "SetInteriorVehicleData"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "SetMediaClockTimer"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "Show"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "FULL" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "Slider"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "Speak"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "SubscribeButton"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "SystemRequest"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "UnregisterAppInterface"
                  },
                  {
                   hmiPermissions = {
                    allowed = { "BACKGROUND", "FULL", "LIMITED" },
                    userDisallowed = {}
                   },
                   parameterPermissions = {
                    allowed = {},
                    userDisallowed = {}
                   },
                   rpcName = "UnsubscribeButton"
                  }
                }
            }
end



function revsdl_module.arrayGroups_nonPrimaryRCNotification( )
  return
    {
      permissionItem = {
          {
           hmiPermissions = {
            allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
            userDisallowed = {}
           },
           parameterPermissions = {
            allowed = {},
            userDisallowed = {}
           },
           rpcName = "OnHMIStatus"
          },
          {
           hmiPermissions = {
            allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
            userDisallowed = {}
           },
           parameterPermissions = {
            allowed = {},
            userDisallowed = {}
           },
           rpcName = "OnPermissionsChange"
          }
         }
      }
end



function revsdl_module.arrayGroups_nonPrimaryRC( )
  return
{
                permissionItem = {
                    {
                     hmiPermissions = {
                      allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                      userDisallowed = {}
                     },
                     parameterPermissions = {
                      allowed = {},
                      userDisallowed = {}
                     },
                     rpcName = "ButtonPress"
                    },
                    {
                     hmiPermissions = {
                      allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                      userDisallowed = {}
                     },
                     parameterPermissions = {
                      allowed = {},
                      userDisallowed = {}
                     },
                     rpcName = "GetInteriorVehicleData"
                    },
                    {
                     hmiPermissions = {
                      allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                      userDisallowed = {}
                     },
                     parameterPermissions = {
                      allowed = {},
                      userDisallowed = {}
                     },
                     rpcName = "GetInteriorVehicleDataCapabilities"
                    },
                    {
                     hmiPermissions = {
                      allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                      userDisallowed = {}
                     },
                     parameterPermissions = {
                      allowed = {},
                      userDisallowed = {}
                     },
                     rpcName = "OnHMIStatus"
                    },
                    {
                     hmiPermissions = {
                      allowed = { "BACKGROUND", "FULL", "LIMITED" },
                      userDisallowed = {}
                     },
                     parameterPermissions = {
                      allowed = {},
                      userDisallowed = {}
                     },
                     rpcName = "OnInteriorVehicleData"
                    },
                    {
                     hmiPermissions = {
                      allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                      userDisallowed = {}
                     },
                     parameterPermissions = {
                      allowed = {},
                      userDisallowed = {}
                     },
                     rpcName = "OnPermissionsChange"
                    },
                    {
                     hmiPermissions = {
                      allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                      userDisallowed = {}
                     },
                     parameterPermissions = {
                      allowed = {},
                      userDisallowed = {}
                     },
                     rpcName = "OnSystemRequest"
                    },
                    {
                     hmiPermissions = {
                      allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                      userDisallowed = {}
                     },
                     parameterPermissions = {
                      allowed = {},
                      userDisallowed = {}
                     },
                     rpcName = "SetInteriorVehicleData"
                    },
                    {
                     hmiPermissions = {
                      allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
                      userDisallowed = {}
                     },
                     parameterPermissions = {
                      allowed = {},
                      userDisallowed = {}
                     },
                     rpcName = "SystemRequest"
                    },
                   }
            }
end

return revsdl_module
