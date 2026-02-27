# goofy.nvim

A silly plugin to enhance your Neovim experience with ASCII art animation feedback for commands.

## Overview

Goofy adds fun ASCII animations that trigger when you run configured commands. Save a file? Get a cool animation. Run a test? Why not celebrate with some ASCII art?

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "Itreau96/goofy.nvim",
  config = function()
    require("goofy").setup({
      animations = {
        -- Register animations for commands
        write = {
          command = "w",
          animation = "write",
        },
      },
    })
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "Itreau96/goofy.nvim",
  config = function()
    require("goofy").setup({
      animations = {
        write = {
          command = "w",
          animation = "write",
        },
      },
    })
  end,
})
```

## Configuration

### Setup

```lua
require("goofy").setup({
  window = {
    border = "rounded",
    position = "bottom_right",  -- or "center"
    width = nil,                -- auto-calculated if nil
    height = nil,               -- auto-calculated if nil
    color = nil,                -- highlight group (e.g., "String", "Error")
  },
  animation = {
    delay = 30,    -- default frame delay in ms
    loop = false,  -- whether to loop animations
  },
  animations = {
    -- your animation registrations here
  },
})
```

### Registering Animations

Animations can be triggered by:

#### Commands

```lua
animations = {
  write = {
    command = "w",           -- triggers on :w
    animation = "write",     -- name of animation file (without .lua)
  },
  quit = {
    command = "q",
    animation = "cool_glasses",
  },
}
```

#### Autocmd Events

```lua
animations = {
  save_event = {
    trigger = "BufWritePost",
    animation = "write",
  },
}
```

#### Filetypes

```lua
animations = {
  lua_files = {
    filetype = "lua",
    animation = "cool_glasses",
  },
}
```

## Creating Custom Animations

Create a new file in `lua/goofy/animations/` directory:

### Array Format (single/multi-line)

```lua
-- lua/goofy/animations/my_animation.lua
return {
  delay = 200,  -- milliseconds between frames
  frames = {
    { "Frame 1", "Line 2" },
    { "Frame 2", "Line 2" },
    { "Frame 3", "Line 2" },
  },
  opts = {
    color = "String",
    position = "center",
    width = 20,
    height = 5,
  },
}
```

### Heredoc Format (block text)

```lua
-- lua/goofy/animations/block_art.lua
return {
  delay = 500,
  frames = {
    [[
  ___
 /   \
|  W  |
 \___/
    ]],
    [[
  ___
 /   \
|  !  |
 \___/
    ]],
  },
  opts = {
    color = "WarningMsg",
    position = "center",
  },
}
```

## How It Works

1. **Setup**: Call `require("goofy").setup()` with your configuration
2. **Registration**: Goofy creates proxy commands (e.g., `:GoofyW`) that:
   - Execute the original command
   - Trigger the associated animation
3. **Animation**: A floating window displays the ASCII animation frame by frame

## Available Animations

- `write` - Simple "Saving..." animation
- `cool_glasses` - Cool glasses ASCII art
- Add your own in `lua/goofy/animations/`!

## License

MIT
