# nvim-keysitter

A utility plugin for those who write their own neovim config,
and want to write some complex textobject related movements.

## Features

- **Chain/Pipping** - Chain methods to create complex keymaps with minimal boilerplate
- **Convenient defaults** - Common textobject patterns (around/inner/next/prev) with out-of-the-box defaults
- **Group prefixes** - Organize related motions under a single key prefix
- **Flexible overrides** - Override any default on a per-keymap basis

## Quick Start

```lua
-- 1. Require and create instance with a prefix for grouped keymaps
local keysitter = require 'keysitter'
local tsto = keysitter.new('treesitter-textobjects', { group_prefix = 'o' })

-- 2. Setup autocommand to define keymaps
tsto.setup({ 'FileType', 'BufEnter' }, 'keysitter', function()
  -- 3. Chain methods to create keymaps
  tsto:set('f', 'function'):around():inner():next():prev()
end, { desc = 'Set keysitter keymaps' })

-- Result: vaof, viof, ]of, ]oF, [of, [oF
```

## Usage

This plugin is made to simplify writing complex keymaps for selecting/jumping textobjects,
while also perform some checks and simple logical guards.
And it's designed to be used in association with other plugins.

> [!NOTE]
> Currently, ['nvim-treesitter-textobjects'](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) is the only supported plugin.
> But if you find it useful and need it to support other plugins then let me know, _I'll try my best to add it_.

### Example

```lua
local keysitter = require 'keysitter'
local tsto = keysitter.new('treesitter-textobjects', { group_prefix = 'o' })

-- a setup function for the group, a new group requires a new setup.
tsto.setup({ 'FileType', 'BufEnter' }, 'keysitter', function()
  -- the following will set:
  tsto:set('f', 'function')
    :around() -- `vaof` for visual-select around a function
    :inner()  -- `viof` for visual-select inner function
    :next()   -- `]of` and `]oF` for jumping to the next start & end of a function
    :prev()   -- `[of` and `[oF` for jumping to the previous start & end of a function

  -- notice how all keymaps are _prefixed_ with `o`, and it will continue unless its overridden per method.

  tsto
    :set('=', 'assignment') -- setting new keymaps
    :around() -- `vao=` for visual-select around an assignment
    -- for inner, we want to target the right-hand-side of the assignment
    :inner({ attribute = 'rhs' }) -- `vio=` for visual-select inner (rhs) assignment
    -- next & prev methods are only for convenience, and you can split their functionality
    :next_start({ attribute = 'lhs' })
    :previous_start({ attribute = 'lhs' })
    :next_start({ attribute = 'rhs', key = '-' }, { desc = 'next rhs assignment' })
    :previous_start({ attribute = 'rhs', key = '-' }, { desc = 'previous rhs assignment' })

  -- or some complex mapping
  tsto
    :set('c', 'class')
    :around()  -- `vaoc` for visual-select around a class
    :inner()   -- `vioc` for visual-select inner class
    :next_start({ motion = ']', group_prefix = '', key = ']' })      -- ']]' for next class start
    :next_end({ motion = ']', group_prefix = '', key = '[' })        -- '][' for next class end
    :previous_start({ motion = '[', group_prefix = '', key = '[' })  -- '[[' for prev class start
    :previous_end({ motion = '[', group_prefix= '', key = ']' })     -- '[]' for next class end

end, { desc = 'Set keysitter keymaps for nvim-treesitter-textobjects' })
```

### Steps

1. Import/require the plugin

1. Use [`new`](#new) function to get a new instance of [`Keysitter`](#Keysitter) object.

1. Use [`setup`](#setup) method to setup the [`Keysitter`](#Keysitter) instance for keymap setting.

1. Use the `callback` within [`setup`](#setup) method to define a function that sets keymaps.

   1. Use `set` method to define targeted _textobject_ (e.g., "function", "class") and associated primary key (e.g., "f", "c")
   1. Use methods like `around`, `inner`, `next`, `prev`, etc.

## Requirements

- neovim >= 0.11.0
- ['nvim-treesitter-textobjects'](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)

## Installation

### vim.pack

### lazy.nvim

#### As dependency for `nvim-treesitter-textobjects`

```lua
return {
  'nvim-treesitter/nvim-treesitter-textobjects',
  branch = 'main',
  dependencies = {
    {
      'ABDsheikho/nvim-keysitter',
      config = function()
        local keysitter = require 'keysitter'
        local tsto = keysitter.new('treesitter-textobjects', { group_prefix = 'o' })

        -- setup function, see [setup](#setup)
        tsto.setup({ 'FileType', 'BufEnter' }, 'keysitter', function()
          -- your keymaps go here
          tsto:set('f', 'function'):around():inner():next():prev()

        end, { desc = 'Set keysitter keymaps for nvim-treesitter-textobjects' })
      end,
    },
  },
  -- the rest of nvim-treesitter-textobject
}
```

#### As stand alone plugin

```lua
return {
  'ABDsheikho/nvim-keysitter',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  config = function()
    local keysitter = require 'keysitter'
    local tsto = keysitter.new('treesitter-textobjects', { group_prefix = 'o' })

    -- setup function, see [setup](#setup)
    tsto.setup({ 'FileType', 'BufEnter' }, 'keysitter', function()
      -- your keymaps go here
      tsto:set('f', 'function'):around():inner():next():prev()

    end, { desc = 'Set keysitter keymaps for nvim-treesitter-textobjects' })
  end,
}
```

______________________________________________________________________

## API: Types

### `Keysitter`

- key (`string`):
  The primary key for keymap
- object (`string`):
  The textobject name (e.g., "function", "class")
- group_prefix (`string`): _optional_
  Prefix for the keymap group, good for grouping multiple related motions under one key/prefix. (default to "")

### `GroupOpts`

- group_prefix (`string`): _optional_
  Prefix for the keymap group, good for grouping multiple related motions under one key/prefix. (default to "")

### `KeymapOpts`

- mode (`string|string[]`): _optional_
  Override the default vim mode(s) for the keymap, see `:h vim.keymap.set()`
- motion (`string`): _optional_
  Override the main motion used to target the textobject while visual-selection/jumping (e.g., 'a', 'i', '\]', '\[' )
- key (`string`): _optional_
  Override the primary key for the keymap
- group_prefix (`string`): _optional_
  Override the group prefix for the keymap
- attribute (`keysitter.Attribute`): _optional_
  Attribute for the textobject node (e.g., "outer", "inner", "rhs", "lhs", etc.)
- callback (`function`): _optional_
  Optional callback to execute instead of default action

### `VimKeymapOpts`

Alias for `vim.keymap.set.Opts` see `:h vim.keymap.set()`

## API: Functions

### `new()`

Create a new `Keysitter` instance for the specified textobject-module.

param:

- txtobj_module (`keysitter.TextObjectModule`):
  The name of the textobject group (e.g., "treesitter-textobjects")
- opts (`keysitter.GroupOpts`): _optional_
  Optional group-configuration options

return:

- A Keysitter instance (`keysitter.Keysitter`)

### `setup()`

Delegates setup to the loaded Keysitter module.
Allows modules to configure their own autocommands and callbacks.

param:

- event (`string|string[]`):
  List of Neovim event(s) that will trigger the handler, see `:h nvim_create_autocmd()`
- group (`string`):
  Name or id of the autocommand group to match against
- callback (`function|string`):
  Callable function for the autocommand
- opts (`keysitter.SetupOpts`): _optional_
  Module-specific options

> [!NOTE]
> Currently (_with the only usage of `nvim-treesitter-textobject`_) this function acts as a wrapper
> for only `nvim_create_autocmd` & `nvim_create_augroup` as a simpler form. And it can be replaced
> by a snippet like: **(compare it to [example](#example))**
>
> ```lua
> vim.api.nvim_create_autocmd({ 'FileType', 'BufEnter' }, {
>   desc = 'Set keysitter keymaps for nvim-treesitter-textobjects'
>   group = vim.api.nvim_create_augroup('keysitter', { clear = true }),
>   callback = function()
>     -- this part is where you use Keysitter-instance to define keymaps.
>     tsto:set('f', 'function'):around():inner():next():prev()
>   end,
> })
> ```

### `around()`

Create a keymap for selecting the outer textobject, including its boundaries (full scope).

param:

- opts (`keysitter.KeymapOpts`): _optional_
  User options (overrides defaults)
- vim_opts (`keysitter.VimKeymapOpts`): _optional_
  options for `vim.keymap.set()`, see `:h vim.keymap.set()`

return:

- A Keysitter instance (`keysitter.Keysitter`)

### `inner()`

Create a keymap for selecting the inner textobject, excluding its boundaries (inner scope).

param:

- opts (`keysitter.KeymapOpts`): _optional_
  User options (overrides defaults)
- vim_opts (`keysitter.VimKeymapOpts`): _optional_
  options for `vim.keymap.set()`, see `:h vim.keymap.set()`

return:

- A Keysitter instance (`keysitter.Keysitter`)

### `next()`

Create keymaps for moving to both the start and end of the next textobject.
Convenient method that chains `next_start()` and `next_end()`.

param:

- opts (`keysitter.KeymapOpts`): _optional_
  User options (overrides defaults)
- vim_opts (`keysitter.VimKeymapOpts`): _optional_
  options for `vim.keymap.set()`, see `:h vim.keymap.set()`

return:

- A Keysitter instance (`keysitter.Keysitter`)

### `prev()`

Create keymaps for moving to both the start and end of the previous textobject.
Convenient method that chains `previous_start()` and `previous_end()`.

param:

- opts (`keysitter.KeymapOpts`): _optional_
  User options (overrides defaults)
- vim_opts (`keysitter.VimKeymapOpts`): _optional_
  options for `vim.keymap.set()`, see `:h vim.keymap.set()`

return:

- A Keysitter instance (`keysitter.Keysitter`)

### `next_start()`

Create a keymap for moving to the start of the next textobject.

param:

- opts (`keysitter.KeymapOpts`): _optional_
  User options (overrides defaults)
- vim_opts (`keysitter.VimKeymapOpts`): _optional_
  options for `vim.keymap.set()`, see `:h vim.keymap.set()`

return:

- A Keysitter instance (`keysitter.Keysitter`)

### `next_end()`

Create a keymap for moving to the end of the next textobject.
Only available if the textobject-module supports end for its textobjects.

param:

- opts (`keysitter.KeymapOpts`): _optional_
  User options (overrides defaults)
- vim_opts (`keysitter.VimKeymapOpts`): _optional_
  options for `vim.keymap.set()`, see `:h vim.keymap.set()`

return:

- A Keysitter instance (`keysitter.Keysitter`)

### `previous_start()`

Create a keymap for moving to the start of the previous textobject.

param:

- opts (`keysitter.KeymapOpts`): _optional_
  User options (overrides defaults)
- vim_opts (`keysitter.VimKeymapOpts`): _optional_
  options for `vim.keymap.set()`, see `:h vim.keymap.set()`

return:

- A Keysitter instance (`keysitter.Keysitter`)

### `previous_end()`

Create a keymap for moving to the end of the previous textobject.
Only available if the textobject-module supports end for its textobjects.

param:

- opts (`keysitter.KeymapOpts`): _optional_
  User options (overrides defaults)
- vim_opts (`keysitter.VimKeymapOpts`): _optional_
  options for `vim.keymap.set()`, see `:h vim.keymap.set()`

return:

- A Keysitter instance (`keysitter.Keysitter`)

______________________________________________________________________

## To-dos

- [ ] make `swap` functionality for `nvim-treesitter-textobjects`.
- [ ] check for other potential plugins (maybe `gitsings`?).
- [ ] add vim.pack installation section.

______________________________________________________________________

## Acknowledgment

My main motivation was write something for [`nvim-treesitter/nvim-treesitter-textobjects`](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)
that simplifies my config, which led me to separate it into its own plugin.
Thanks to them for their incredible work.

______________________________________________________________________

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](./LICENSE) for details.
