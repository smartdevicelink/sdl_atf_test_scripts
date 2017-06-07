local module = {}

local common_functions = require("user_modules/common_functions")
local api_loader = require("modules/api_loader")
local mobile_api = api_loader.init("data/MOBILE_API.xml")
local interface_schema = mobile_api.interface["Ford Sync RAPI"]

--! @brief Function which returns unordered key set from any table
--! @param table - table from which we are going to get the keys
function module.GetUnorderedTableKeyset(source_table)
  local keyset = {}

  for k in pairs(source_table) do
    table.insert(keyset, k)
  end
  return keyset
end

--! @brief Function converts time in TZ format to epoch seconds
--! @param tz_date - date in TZ format
--! @return value - value in epoch seconds
--! @usage Function usage example: epoch_seconds = module.ConvertTZDateToEpochSeconds("2017-02-13T19:28:19Z")
function module.ConvertTZDateToEpochSeconds(tz_date)
  local tz_table = {year = 0, month = 0, day = 0, hour = 0, min = 0, sec = 0}
  local keyset = {"year", "month", "day", "hour", "min", "sec"}
  local count = 1
  for element in string.gmatch(tz_date,'%d+') do
    tz_table[keyset[count]] = element
    count = count + 1
  end
  return os.time(tz_table)
end

--! @brief Allows to get struct value from any mobile api struct
--! @param struct_name - name of needed struct
--! @param param_name - struct parameter
--! @param value_to_read - value which is needed to be read
--! @usage Function usage example: maxvalueMenuParams = module.GetStructValueFromMobileApi( "MenuParams", "parentID", "maxvalue")
function module.GetStructValueFromMobileApi(struct_name, param_name, value_to_read)
  if not interface_schema.struct[struct_name] then
    common_functions:UserPrint(31, "Struct with name:", " ")
    common_functions:UserPrint(0, struct_name, " ")
    common_functions:UserPrint(31, "does not exist")
    return nil
  end
  if not interface_schema.struct[struct_name].param[param_name] then
    common_functions:UserPrint(31, "Param with name:", " ")
    common_functions:UserPrint(0, param_name, " ")
    common_functions:UserPrint(31, "does not exist in structure:", " ")
    common_functions:UserPrint(0, struct_name)
    return nil
  end
  return interface_schema.struct[struct_name].param[param_name][value_to_read]
end

--! @brief Function allows to get an enum from mobile api
--! @param enum_name - enum name which we are going to get
--! @param Function usage example: local sampling_rates = utils.GetEnumFromMobileApi("SamplingRate")
function module.GetEnumFromMobileApi(enum_name)
  if not interface_schema.enum[enum_name] then
    common_functions:UserPrint(31, "Enum with name:", " ")
    common_functions:UserPrint(0, enum_name, " ")
    common_functions:UserPrint(31, "does not exist")
    return nil
  end
  return module.GetUnorderedTableKeyset(interface_schema.enum[enum_name])
end

--! @brief Function allows to get any enum size(number of elements) from mobile api
--! @param enum_name - enum name which size we are going to get
--! @param Function usage example: maxlength = enum_size = module.GetEnumSizeFromMobileApi("AppInterfaceUnregisteredReason")
function module.GetEnumSizeFromMobileApi(enum_name)
  if not interface_schema.enum[enum_name] then
    common_functions:UserPrint(31, "Enum with name:", " ")
    common_functions:UserPrint(0, enum_name, " ")
    common_functions:UserPrint(31, "does not exist")
    return nil
  end
  return #module.GetUnorderedTableKeyset(interface_schema.enum[enum_name])
end

--! @brief Function allows to get value from any mobile api function
--! @param function_type - request, response or notification
--! @param function_name - name of the function
--! @param param_name - function parameter
--! @param value_to_read - value which is needed to be read
--! @param Function usage example: maxlength = module.GetFunctionValueFromMobileApi("request", "Show", "mainField2", "maxlength")
function module.GetFunctionValueFromMobileApi(function_type, function_name, param_name, value_to_read)
  if not interface_schema.type[function_type] then
    common_functions:UserPrint(31, "Function with type:", " ")
    common_functions:UserPrint(0, function_type, " ")
    common_functions:UserPrint(31, "does not exist")
    return nil
  end
  if not interface_schema.type[function_type].functions[function_name] then
    common_functions:UserPrint(31, "Function with name:", " ")
    common_functions:UserPrint(0, function_name, " ")
    common_functions:UserPrint(31, "does not exist")
    return nil
  end
  if not interface_schema.type[function_type].functions[function_name].param[param_name] then
    common_functions:UserPrint(31, "Parameter with name:", " ")
    common_functions:UserPrint(0, param_name, " ")
    common_functions:UserPrint(31, "does not exist")
    return nil
  end
  return interface_schema.type[function_type].functions[function_name].param[param_name][value_to_read]
end

return module

