local db = require("lapis.db")
local escape_literal
escape_literal = db.escape_literal
local concat
do
  local _obj_0 = table
  concat = _obj_0.concat
end
local append_all
append_all = function(t, ...)
  for i = 1, select("#", ...) do
    t[#t + 1] = select(i, ...)
  end
end
local extract_options
extract_options = function(cols)
  local options = { }
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #cols do
      local _continue_0 = false
      repeat
        local col = cols[_index_0]
        if type(col) == "table" then
          for k, v in pairs(col) do
            options[k] = v
          end
          _continue_0 = true
          break
        end
        local _value_0 = col
        _accum_0[_len_0] = _value_0
        _len_0 = _len_0 + 1
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    cols = _accum_0
  end
  return cols, options
end
local entity_exists
entity_exists = function(name)
  name = db.escape_literal(name)
  local res = unpack(db.select("COUNT(*) as c from pg_class where relname = " .. tostring(name)))
  return res.c > 0
end
local gen_index_name
gen_index_name = function(...)
  local parts
  do
    local _accum_0 = { }
    local _len_0 = 1
    local _list_0 = {
      ...
    }
    for _index_0 = 1, #_list_0 do
      local p = _list_0[_index_0]
      if type(p) == "string" then
        _accum_0[_len_0] = p
        _len_0 = _len_0 + 1
      end
    end
    parts = _accum_0
  end
  return concat(parts, "_") .. "_idx"
end
local create_table
create_table = function(name, columns)
  local buffer = {
    "CREATE TABLE IF NOT EXISTS " .. tostring(db.escape_identifier(name)) .. " ("
  }
  local add
  add = function(...)
    return append_all(buffer, ...)
  end
  for i, c in ipairs(columns) do
    add("\n  ")
    if type(c) == "table" then
      local kind
      name, kind = unpack(c)
      add(db.escape_identifier(name), " ", tostring(kind))
    else
      add(c)
    end
    if not (i == #columns) then
      add(",")
    end
  end
  if #columns > 0 then
    add("\n")
  end
  add(");")
  return db.query(concat(buffer))
end
local create_index
create_index = function(tname, ...)
  local index_name = gen_index_name(tname, ...)
  if entity_exists(index_name) then
    return 
  end
  local columns, options = extract_options({
    ...
  })
  local buffer = {
    "CREATE"
  }
  if options.unique then
    append_all(buffer, " UNIQUE")
  end
  append_all(buffer, " INDEX ON " .. tostring(db.escape_identifier(tname)) .. " (")
  for i, col in ipairs(columns) do
    append_all(buffer, db.escape_identifier(col))
    if not (i == #columns) then
      append_all(buffer, ", ")
    end
  end
  append_all(buffer, ")")
  if options.where then
    append_all(buffer, " WHERE ", options.where)
  end
  append_all(buffer, ";")
  return db.query(concat(buffer))
end
local drop_index
drop_index = function(...)
  local index_name = gen_index_name(...)
  return db.query("DROP INDEX IF EXISTS " .. tostring(db.escape_identifier(index_name)))
end
local drop_table
drop_table = function(tname)
  return db.query("DROP TABLE IF EXISTS " .. tostring(db.escape_identifier(tname)) .. ";")
end
local add_column
add_column = function(tname, col_name, col_type)
  tname = db.escape_identifier(tname)
  col_name = db.escape_identifier(col_name)
  return db.query("ALTER TABLE " .. tostring(tname) .. " ADD COLUMN " .. tostring(col_name) .. " " .. tostring(col_type))
end
local drop_column
drop_column = function(tname, col_name)
  tname = db.escape_identifier(tname)
  col_name = db.escape_identifier(col_name)
  return db.query("ALTER TABLE " .. tostring(tname) .. " DROP COLUMN " .. tostring(col_name))
end
local rename_column
rename_column = function(tname, col_from, col_to)
  tname = db.escape_identifier(tname)
  col_from = db.escape_identifier(col_from)
  col_to = db.escape_identifier(col_to)
  return db.query("ALTER TABLE " .. tostring(tname) .. " RENAME COLUMN " .. tostring(col_from) .. " TO " .. tostring(col_to))
end
local rename_table
rename_table = function(tname_from, tname_to)
  tname_from = db.escape_identifier(tname_from)
  tname_to = db.escape_identifier(tname_to)
  return db.query("ALTER TABLE " .. tostring(tname_from) .. " RENAME TO " .. tostring(tname_to))
end
local ColumnType
do
  local _base_0 = {
    default_options = {
      null = false
    },
    __call = function(self, opts)
      local out = self.base
      for k, v in pairs(self.default_options) do
        if not (opts[k] ~= nil) then
          opts[k] = v
        end
      end
      if not (opts.null) then
        out = out .. " NOT NULL"
      end
      if opts.default ~= nil then
        out = out .. (" DEFAULT " .. escape_literal(opts.default))
      end
      if opts.unique then
        out = out .. " UNIQUE"
      end
      if opts.primary_key then
        out = out .. " PRIMARY KEY"
      end
      return out
    end,
    __tostring = function(self)
      return self:__call(self.default_options)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, base, default_options)
      self.base, self.default_options = base, default_options
    end,
    __base = _base_0,
    __name = "ColumnType"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  ColumnType = _class_0
end
local C = ColumnType
local types = setmetatable({
  serial = C("serial"),
  varchar = C("character varying(255)"),
  text = C("text"),
  time = C("timestamp without time zone"),
  date = C("date"),
  integer = C("integer", {
    null = false,
    default = 0
  }),
  numeric = C("numeric", {
    null = false,
    default = 0
  }),
  real = C("real", {
    null = false,
    default = 0
  }),
  double = C("double precision", {
    null = false,
    default = 0
  }),
  boolean = C("boolean", {
    null = false,
    default = false
  }),
  foreign_key = C("integer")
}, {
  __index = function(self, key)
    return error("Don't know column type `" .. tostring(key) .. "`")
  end
})
return {
  types = types,
  create_table = create_table,
  drop_table = drop_table,
  create_index = create_index,
  drop_index = drop_index,
  add_column = add_column,
  drop_column = drop_column,
  rename_column = rename_column,
  rename_table = rename_table,
  entity_exists = entity_exists
}
