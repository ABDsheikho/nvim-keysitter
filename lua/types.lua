---@class keysitter.Keysitter
---@field key string The primary key for keymap
---@field object string The textobject name (e.g., "function", "class")
---@field group_prefix? string Prefix for the keymap group, good for grouping multiple related motions under one key/prefix. (default to "")
---@field module keysitter.Module The loaded Keysitter module

---@class keysitter.Module
---@field has_end? boolean Whether the module supports end textobjects
---@field textobject_check fun(query_name: string, query_attribute: string): string|nil, boolean Validate textobject query
---@field setup fun(event: string|string[], group: string, callback: function|string, opts: keysitter.SetupOpts?) Setup function for the textobject-module
---@field outer_select fun(textobject: string, key: string, opts: keysitter.KeymapOpts, vim_opts: keysitter.VimKeymapOpts) Select outer textobject
---@field inner_select fun(textobject: string, key: string, opts: keysitter.KeymapOpts, vim_opts: keysitter.VimKeymapOpts) Select inner textobject
---@field next_start fun(textobject: string, key: string, opts: keysitter.KeymapOpts, vim_opts: keysitter.VimKeymapOpts) Move to next start
---@field next_end? fun(textobject: string, key: string, opts: keysitter.KeymapOpts, vim_opts: keysitter.VimKeymapOpts) Move to next end
---@field previous_start fun(textobject: string, key: string, opts: keysitter.KeymapOpts, vim_opts: keysitter.VimKeymapOpts) Move to previous start
---@field previous_end? fun(textobject: string, key: string, opts: keysitter.KeymapOpts, vim_opts: keysitter.VimKeymapOpts) Move to previous end

---@alias keysitter.VimKeymapOpts `vim.keymap.set.Opts` see `:h vim.keymap.set()`

---@class keysitter.GroupOpts
---@field group_prefix? string Prefix for the keymap group, good for grouping multiple related motions under one key/prefix. (default to "")

---@class keysitter.KeymapOpts
---@field mode? string|string[] Override the default vim mode(s) for the keymap, see `:h vim.keymap.set()`
---@field motion? string Override the main motion used to target the textobject while visual-selection/jumping (e.g., 'a', 'i', ']', '[' )
---@field key? string Override the primary key for the keymap
---@field group_prefix? string Override the group prefix for the keymap
---@field attribute? keysitter.Attribute Attribute for the textobject node (e.g., "outer" or "inner")
---@field callback? function Optional callback to execute instead of default action

---@class keysitter.SetupOpts
---@field desc? string Description for the autocmd

---@alias keysitter.TextObjectModule
---| 'treesitter-textobjects' for nvim-treesitter/nvim-treesitter-textobjects

---@alias keysitter.Attribute
---| 'outer'
---| 'inner'
---| 'lhs'
---| 'rhs'

---@alias keysitter.Module.Operations
---| 'outer_select'
---| 'inner_select'
---| 'next_start'
---| 'next_end'
---| 'previous_start'
---| 'previous_end'
