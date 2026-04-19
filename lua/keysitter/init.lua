---@module "types"

local M = {}

---@class keysitter.Keysitter
local Keysitter = {}
Keysitter.__index = Keysitter

---Create a new Keysitter instance for the specified textobject-module.
---
---@param txtobj_module keysitter.TextObjectModule The name of the textobject group (e.g., "treesitter-textobjects")
---@param opts keysitter.GroupOpts? Optional group-configuration options
---@return keysitter.Keysitter self The Keysitter instance.
function M.new(txtobj_module, opts)
  -- Dynamically requiring the associated module for the textobject.
  Keysitter.module = require("keysitter." .. txtobj_module)

  -- Define defaults for group if not provided
  ---@as keysitter.KeymapOpts
  opts = vim.tbl_extend("keep", opts or {}, {
    group_prefix = "",
  })

  return setmetatable(opts, Keysitter)
end

---Sets a primary key and its associated textobject, that will be used to set related keymaps.
---
---@param key string The primary key for the keymap (e.g., "f" for "function")
---@param object string The textobject name (e.g., "function", "class")
---@return keysitter.Keysitter self The same instance (for method chaining/piping)
function Keysitter:set(key, object)
  self.key = key
  self.object = object
  return self
end

---Merges user-provided options with defaults.
---
---@param opts keysitter.KeymapOpts? User options
---@param vim_opts keysitter.VimKeymapOpts? options for `vim.keymap.set()`
---@param defaults keysitter.KeymapOpts Default values for the operation type
---@return keysitter.KeymapOpts, keysitter.VimKeymapOpts
local function normalize_opts(opts, vim_opts, defaults)
  -- Merge user options with defaults, keeping user values where provided using "keep".
  opts = vim.tbl_extend("keep", opts or {}, defaults)
  -- Ensure vim_opts is at least an empty table
  vim_opts = vim_opts or {}
  return opts, vim_opts
end

---Template method that executes operations from Keysitter-module with consistent
---option handling and early return on validation failure.
---
---@param self keysitter.Keysitter The Keysitter instance
---@param operation keysitter.Module.Operations Module's method name to call
---@param opts keysitter.KeymapOpts Normalized options
---@param vim_opts keysitter.VimKeymapOpts options for `vim.keymap.set()`
---@return keysitter.Keysitter self
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
---
---@param opts keysitter.KeymapOpts? User options (overrides defaults)
---@param vim_opts keysitter.VimKeymapOpts? options for `vim.keymap.set()`
---@return keysitter.Keysitter self The same instance (for method chaining/piping)
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
---
---@param opts keysitter.KeymapOpts? User options (overrides defaults)
---@param vim_opts keysitter.VimKeymapOpts? options for `vim.keymap.set()`
---@return keysitter.Keysitter self The same instance (for method chaining/piping)
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
---
---@param opts keysitter.KeymapOpts? User options (overrides defaults)
---@param vim_opts keysitter.VimKeymapOpts? options for `vim.keymap.set()`
---@return keysitter.Keysitter self The same instance (for method chaining/piping)
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
---
---@param opts keysitter.KeymapOpts? User options (overrides defaults)
---@param vim_opts keysitter.VimKeymapOpts? options for `vim.keymap.set()`
---@return keysitter.Keysitter self The same instance (for method chaining/piping)
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
---
---@param opts keysitter.KeymapOpts? User options (overrides defaults)
---@param vim_opts keysitter.VimKeymapOpts? options for `vim.keymap.set()`
---@return keysitter.Keysitter self The same instance (for method chaining/piping)
function Keysitter:next(opts, vim_opts)
  return self:next_start(opts, vim_opts):next_end(opts, vim_opts)
end

---Create a keymap for moving to the start of the previous textobject.
---
---@param opts keysitter.KeymapOpts? User options (overrides defaults)
---@param vim_opts keysitter.VimKeymapOpts? options for `vim.keymap.set()`
---@return keysitter.Keysitter self The same instance (for method chaining/piping)
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
---
---@param opts keysitter.KeymapOpts? User options (overrides defaults)
---@param vim_opts keysitter.VimKeymapOpts? options for `vim.keymap.set()`
---@return keysitter.Keysitter self The same instance (for method chaining/piping)
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
---
---@param opts keysitter.KeymapOpts? User options (overrides defaults)
---@param vim_opts keysitter.VimKeymapOpts? options for `vim.keymap.set()`
---@return keysitter.Keysitter self The same instance (for method chaining/piping)
function Keysitter:prev(opts, vim_opts)
  return self:previous_start(opts, vim_opts):previous_end(opts, vim_opts)
end

---Create keymaps for moving to the start of the next and previous textobject.
---Convenient method that chains next_start and previous_start.
---
---@param opts keysitter.KeymapOpts? User options (overrides defaults)
---@param vim_opts keysitter.VimKeymapOpts? options for `vim.keymap.set()`
---@return keysitter.Keysitter self The same instance (for method chaining/piping)
function Keysitter:goto_start(opts, vim_opts)
  return self:next_start(opts, vim_opts):previous_start(opts, vim_opts)
end

---Create keymaps for moving to the end of the next and previous textobject.
---Convenient method that chains next_end and previous_end.
---Only available if the TextObject-module supports end for its textobjects.
---
---@param opts keysitter.KeymapOpts? User options (overrides defaults)
---@param vim_opts keysitter.VimKeymapOpts? options for `vim.keymap.set()`
---@return keysitter.Keysitter self The same instance (for method chaining/piping)
function Keysitter:goto_end(opts, vim_opts)
  return self:next_end(opts, vim_opts):previous_end(opts, vim_opts)
end

-- TODO:write a better desc for setup() function

---Delegates setup to the loaded Keysitter module.
---Allows modules to configure their own autocommands and callbacks.
---
---@param event string|string[] List of Neovim event(s) that will trigger the handler, see `:h nvim_create_autocmd()`
---@param group string Name or id of the autocommand group to match against
---@param callback (function|string) Callable function for the autocommand
---@param opts? keysitter.SetupOpts Module-specific options
---@return any res Result from the module's setup function
function Keysitter.setup(event, group, callback, opts)
  return Keysitter.module.setup(event, group, callback, opts)
end

return M
