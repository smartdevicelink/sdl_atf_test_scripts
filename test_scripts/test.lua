
-- Get table size on top level
local function TableSize(T)
      local count = 0
      for _ in pairs(T) do count = count + 1 end
      return count
end

--Compare 2 tables
function is_table_equal(table1, table2)
 -- compare value types
  if type(table1) ~= type(table2) then return false end
  if type(table1) == 'number' then return table1 == table2 end
  if type(table1) == 'boolean' then return table1 == table2 end
  if type(table1) == 'string' then return table1 == table2 end
  -- non-table can't be comparing
  if type(table1) ~= 'table' then return false end
  if type(table1) == 'nil' then return true end

  -- Now, on to tables.
  -- If tables have different size they can't be equal
  --calc size t1
  local size_t1 = TableSize(table1)
  --calc size t2
  local size_t2 = TableSize(table2)
  if (size_t1 ~= size_t2) then return false end

  --compare arrays. Order in array must be equal
  if json.isArray(table1) and json.isArray(table2) then
    for k1,v1 in table1 do
      if not is_table_equal(v1, table2[k1]) then -- get element  by the same index
        return false
      end
    end
    return true
  end
  -- compare tables by elements
  local already_compared = {} --optimization
  for _,v1 in pairs(table1) do
    for k2,v2 in pairs(table2) do
      if not already_compared[k2] and is_table_equal(v1,v2) then
        already_compared[k2] = true
      end
    end
  end
  if size_t2 ~= TableSize(already_compared) then
    return false
  end
  return true
end

function IsDbContains(db_path, sql_query, exp_result)
      local commandToExecute = "sqlite3 "..db_path .." \""..sql_query.."\""
      local db = assert(io.popen(commandToExecute, 'r'))
      local selected_data = assert(db:read('*a'))
      db:close()
      print("Output:"..selected_data)
      print("Type is:"..type(selected_data))
      return is_table_equal(selected_data, exp_result);
end

local sqlite_path = "/home/ahrytsevich/Work/sdl_core/build/bin/storage/policy.sqlite"
local request = "SELECT * FROM application"

local result = "default NONE"


if IsDbContains(sqlite_path, request, result) then 
      print("Success")
else
      print("Fail")
end

-- body
-- local command = "sqlite3 " .. "/home/ahrytsevich/Work/sdl_core/build/bin/storage/policy.sqlite".." \"".."SELECT * FROM application".."\""
-- -- local command = "sqlite3 " .. pathToDB .. " \"" .. query .. "\" | grep extraTable | wc -l"
-- local handle = io.popen(command)
-- local commandResult = handle:read("*a")
-- handle:close()

-- print("Result: "..commandResult)