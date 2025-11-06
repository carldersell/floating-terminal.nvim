# floating-terminal.nvim

A lightweight Neovim plugin for quickly toggling floating and bottom terminals.
Includes optional keymaps, built-in commands, and user-configurable default sizes.

---

## ✨ Features

- 🎈 Floating terminal with rounded borders
- 📌 Bottom terminal with adjustable height
- 🧩 User-configurable default sizes (absolute or percentage)
- 🗝️ Optional default keymaps (`<leader>tf`, `<leader>tb`)
- 🔌 Lazy.nvim-friendly setup
- 🧼 Zero dependencies

---

## 📦 Installation

### Lazy.nvim

```lua
{
  "carldersell/floating-terminal.nvim",
  opts = {
    default_keymaps = true,

    floating = {
      width = 0.8,
      height = 0.8,
    },
    bottom = {
      height = 0.3,
    },

    keymaps = {
      toggle_floating = "<leader>tf",
      toggle_bottom = "<leader>tb",
    },
  },
}
```

### Packer

```lua
use {
  "carldersell/floating-terminal.nvim",
  config = function()
    require("floating-terminal").setup({
      default_keymaps = true,
    })
  end,
}
```

---

## 🚀 Usage

### Lua API

```lua
local term = require("floating-terminal")

term.toggle_floating_terminal()
term.toggle_bottom_terminal()
```

### Commands

| Command                        | Description                  |
|-------------------------------|------------------------------|
| :ToggleFloatingTerminal       | Toggle floating terminal     |
| :ToggleBottomTerminal         | Toggle bottom terminal       |
| :ResizeFloatingTerminal w h   | Resize floating terminal     |
| :ResizeBottomTerminal h       | Resize bottom terminal       |

---

## 🎛️ Configuration Options

### Default Configuration

```lua
{
  default_keymaps = false,

  floating = {
    width = 0.8,
    height = 0.8,
  },

  bottom = {
    height = 0.3,
  },

  keymaps = {
    toggle_floating = "<leader>tf",
    toggle_bottom = "<leader>tb",
  },
}
```

### Size Configuration Rules

- **Percentage values:**
  ```lua
  width = 0.8     -- 80% of screen
  ```

- **Absolute values:**
  ```lua
  width = 120     -- 120 columns
  ```

Both are supported.

---

## 🗝️ Optional Default Keymaps

Enable them:

```lua
require("floating-terminal").setup({
  default_keymaps = true,
})
```

This sets:

| Mode | Key | Action |
|------|-----|--------|
| n,t  | `<leader>tf` | Toggle floating terminal |
| n,t  | `<leader>tb` | Toggle bottom terminal   |

Override:

```lua
keymaps = {
  toggle_floating = "<leader>FF",
  toggle_bottom = "<leader>BB",
}
```

Disable:

```lua
keymaps = {
  toggle_floating = false,
}
```

---

## 📚 API Reference

### `toggle_floating_terminal(command?, width?, height?)`

Open or hide the floating terminal, optionally sending a shell command.

### `toggle_bottom_terminal(command?, height?)`

Open or hide the bottom terminal, optionally sending a shell command.

---

## 📝 License

MIT License
