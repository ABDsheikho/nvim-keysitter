---@class keysitter.Module
local TsTo = {}

-- 'nvim-treesitter-textobjects' has an _end_ for queries
TsTo.has_end = true

---Sets up a Neovim autocommand for TreeSitter textobject initialization.
---Create an augroup and registers the callback to run on specified events.
---
---@param event string|string[] Event(s) that will trigger the handler, see `:h nvim_create_autocmd()`.
---@param group string name or id of the autocommand group to match against.
---@param callback function|string callable function when the event(s) is triggered.
---@param opts? keysitter.SetupOpts Additional configs for autocmd & augroup
function TsTo.setup(event, group, callback, opts)
  opts = opts or {}
  local desc = opts.desc or ""

  -- Create the autocmd with the specified events
  vim.api.nvim_create_autocmd(event, {
    desc = desc, -- Set the description shown in :autocmd
    -- Create or get the augroup for this module
    group = vim.api.nvim_create_augroup(group, { clear = true }),
    callback = callback,
  })
end

---Validates that a textobject query exists in the treesitter query file.
---Checks the "textobjects" query for captures matching the given pattern.
---
---@param query_name string The textobject name (e.g., "function", "class")
---@param query_attribute string The attribute type ("outer" or "inner")
---@return string?, boolean
function TsTo.textobject_check(query_name, query_attribute)
  -- Construct the full query pattern to search for
  -- (e.g., "function.outer", "block.inner", "statement.lhs")
  local q = query_name .. "." .. query_attribute

  -- Get the language for the current buffer's filetype
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype) or ""
  -- Fetch the textobjects query for this language, or set it to {} if nil
  local query = vim.treesitter.query.get(lang, "textobjects") or {}

  -- Check if any capture in the query matches our pattern
  if vim.iter(query.captures or {}):any(function(val)
    return val:match(q)
  end) then
    -- (e.g., "@function.outer", "@block.inner", "@statement.lhs")
    return "@" .. q, true
  end
  return nil, false
end

---Factory function that creates TreeSitter-textobject keymap handlers.
---Each returned function creates a `vim.keymap.set` call with consistent defaults.
---
---@param default_motion string Default motion prefix (e.g., "a", "i", "]", "[")
---@param default_mode string|string[] Default vim modes (e.g., {"x", "o"} or {"n", "x", "o"})
---@param action_fn function Function to call for the textobject action
---@return fun(textobject: string, key: string, opts:keysitter.KeymapOpts, vim_opts:keysitter.VimKeymapOpts)
local function create_keymap_fn(default_motion, default_mode, action_fn)
  ---Create a keymap handler with the specified configuration.
  ---
  ---Note: opts & vim_opts are normalized, and can't be nil at this point.
  ---
  ---@param textobject string The textobject name for the action
  ---@param key string The key to bind for this mapping
  ---@param opts keysitter.KeymapOpts Override options for this specific mapping
  ---@param vim_opts keysitter.VimKeymapOpts options for `vim.keymap.set()`
  return function(textobject, key, opts, vim_opts)
    -- Use provided configs or fall back to default
    local mode = opts.mode or default_mode
    local motion = opts.motion or default_motion
    local group_prefix = opts.group_prefix or ""
    local callback = opts.callback or function()
      action_fn(textobject)
    end

    -- Construct the full key sequence: motion + group_prefix + key
    -- e.g., "]" + "g" + "f" = "]gf" for next function
    local k = motion .. group_prefix .. key

    vim.keymap.set(mode, k, callback, vim_opts)
  end
end

-- Load nvim-treesitter-textobjects modules for textobject selection and movement
local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")

---Create a keymap function for selecting the outer (around) textobject.
---Uses "a" motion prefix and operates in visual and operator-pending modes.
TsTo.outer_select = create_keymap_fn("a", { "x", "o" }, function(textobject)
  select.select_textobject(textobject, "textobjects")
end)

---Create a keymap function for selecting the inner textobject.
---Uses "i" motion prefix and operates in visual and operator-pending modes.
TsTo.inner_select = create_keymap_fn("i", { "x", "o" }, function(textobject)
  select.select_textobject(textobject, "textobjects")
end)

---Create a keymap function for moving to the start of the next textobject.
---Uses "]" motion prefix and operates in normal, visual, and operator-pending modes.
TsTo.next_start = create_keymap_fn("]", { "n", "x", "o" }, function(textobject)
  move.goto_next_start(textobject, "textobjects")
end)

---Create a keymap function for moving to the end of the next textobject.
---Uses "]" motion prefix and operates in normal, visual, and operator-pending modes.
TsTo.next_end = create_keymap_fn("]", { "n", "x", "o" }, function(textobject)
  move.goto_next_end(textobject, "textobjects")
end)

---Create a keymap function for moving to the start of the previous textobject.
---Uses "[" motion prefix and operates in normal, visual, and operator-pending modes.
TsTo.previous_start = create_keymap_fn("[", { "n", "x", "o" }, function(textobject)
  move.goto_previous_start(textobject, "textobjects")
end)

---Create a keymap function for moving to the end of the previous textobject.
---Uses "[" motion prefix and operates in normal, visual, and operator-pending modes.
TsTo.previous_end = create_keymap_fn("[", { "n", "x", "o" }, function(textobject)
  move.goto_previous_end(textobject, "textobjects")
end)

return TsTo
