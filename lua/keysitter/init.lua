local M = {}

local Keysitter = {}
Keysitter.__index = Keysitter

---Create a new Keysitter instance for the specified textobject-module.
function M.new(txtobj_module, opts)
  -- Dynamically requiring the associated module for the textobject.
  Keysitter.module = require("keysitter." .. txtobj_module)

  -- Define defaults for group if not provided
  local defaults = {
    group_prefix = "",
  }

  return setmetatable(opts or defaults, Keysitter)
end

---Sets a primary key and its associated textobject, that will be used to set related keymaps.
function Keysitter:set(key, object)
  self.key = key
  self.object = object
  return self
end

---Merges user-provided options with defaults.
local function normalize_opts(opts, vim_opts, defaults)
  -- Merge user options with defaults, keeping user values where provided using "keep".
  opts = vim.tbl_extend("keep", opts or {}, defaults)
  -- Ensure vim_opts is at least an empty table
  vim_opts = vim_opts or {}
  return opts, vim_opts
end

---Template method that executes operations from Keysitter-module with consistent
---option handling and early return on validation failure.
local function execute_operation(self, operation, opts, vim_opts)
  -- Validate that the textobject exists and is valid
  -- res: is value processed from self.object and opts.attribute
  -- ok: is validation flag
  local res, ok = Keysitter.module.textobject_check(self.object, opts.attribute)
  -- return if not valid
  if not ok then
    return self
  end

  -- Execute the operation with the validated textobject (res)
  Keysitter.module[operation](res, opts.key, opts, vim_opts)
  return self
end

---Create a keymap for selecting the outer textobject, including its boundaries (full scope).
function Keysitter:around(opts, vim_opts)
  -- Define default
  local defaults = {
    group_prefix = self.group_prefix,
    attribute = "outer",
    key = self.key,
  }

  -- Normalize options
  opts, vim_opts = normalize_opts(opts, vim_opts, defaults)

  -- Set simple-default description if not provided
  vim_opts.desc = vim_opts.desc or ("around " .. self.object)

  -- Execute "outer_select" operation
  return execute_operation(self, "outer_select", opts, vim_opts)
end

---Create a keymap for selecting the inner textobject, excluding its boundaries (inner scope).
function Keysitter:inner(opts, vim_opts)
  -- Define default
  local defaults = {
    group_prefix = self.group_prefix,
    attribute = "inner",
    key = self.key,
  }

  -- Normalize options
  opts, vim_opts = normalize_opts(opts, vim_opts, defaults)

  -- Set simple-default description if not provided
  vim_opts.desc = vim_opts.desc or ("inner " .. self.object)

  -- Execute "inner_select" operation
  return execute_operation(self, "inner_select", opts, vim_opts)
end

---Create a keymap for moving to the start of the next textobject.
function Keysitter:next_start(opts, vim_opts)
  -- Define default
  local defaults = {
    group_prefix = self.group_prefix,
    attribute = "outer",
    key = self.key,
  }

  -- Normalize options
  opts, vim_opts = normalize_opts(opts, vim_opts, defaults)

  -- Set simple-default description if not provided
  vim_opts.desc = vim_opts.desc or ("next " .. self.object .. " start")

  -- Execute "next_start" operation
  return execute_operation(self, "next_start", opts, vim_opts)
end

---Create a keymap for moving to the end of the next textobject.
---Only available if the TextObject-module supports end for its textobjects.
function Keysitter:next_end(opts, vim_opts)
  -- Check if the module supports end textobjects
  if not Keysitter.module.has_end then
    return self
  end

  -- Define default
  local defaults = {
    group_prefix = self.group_prefix,
    attribute = "outer",
    -- Uppercase key indicates targeting the "end" of a textobject.
    key = self.key:upper(),
  }

  -- Normalize options
  opts, vim_opts = normalize_opts(opts, vim_opts, defaults)

  -- Set simple-default description if not provided
  vim_opts.desc = vim_opts.desc or ("next " .. self.object .. " end")

  -- Execute "next_end" operation
  return execute_operation(self, "next_end", opts, vim_opts)
end

---Create keymaps for moving to both the start and end of the next textobject.
---Convenient method that chains next_start and next_end.
function Keysitter:next(opts, vim_opts)
  return self:next_start(opts, vim_opts):next_end(opts, vim_opts)
end

---Create a keymap for moving to the start of the previous textobject.
function Keysitter:previous_start(opts, vim_opts)
  -- Define default
  local defaults = {
    group_prefix = self.group_prefix,
    attribute = "outer",
    key = self.key,
  }

  -- Normalize options
  opts, vim_opts = normalize_opts(opts, vim_opts, defaults)

  -- Set simple-default description if not provided
  vim_opts.desc = vim_opts.desc or ("previous " .. self.object .. " start")

  -- Execute "previous_start" operation
  return execute_operation(self, "previous_start", opts, vim_opts)
end

---Create a keymap for moving to the end of the previous textobject.
---Only available if the TextObject-module supports end for its textobjects.
function Keysitter:previous_end(opts, vim_opts)
  -- Check if the module supports end textobjects
  if not Keysitter.module.has_end then
    return self
  end

  -- Define default
  local defaults = {
    group_prefix = self.group_prefix,
    attribute = "outer",
    -- Uppercase key indicates targeting the "end" of a textobject.
    key = self.key:upper(),
  }

  -- Normalize options
  opts, vim_opts = normalize_opts(opts, vim_opts, defaults)

  -- Set simple-default description if not provided
  vim_opts.desc = vim_opts.desc or ("previous " .. self.object .. " end")

  -- Execute "previous_end" operation
  return execute_operation(self, "previous_end", opts, vim_opts)
end

---Create keymaps for moving to both the start and end of the previous textobject.
---Convenient method that chains previous_start and previous_end.
function Keysitter:prev(opts, vim_opts)
  return self:previous_start(opts, vim_opts):previous_end(opts, vim_opts)
end

-- TODO:write a good desc
--
---Delegates setup to the loaded Keysitter module.
---Allows modules to configure their own autocommands and callbacks.
function Keysitter.setup(event, group, callback, opts)
  return Keysitter.module.setup(event, group, callback, opts)
end

return M
