# goofy.nvim

A silly plugin to enhance your Neovim experience with ASCII art animation feedback for commands.

> **Note :construction:**: This project is currently under active development. v1.0 is coming soon with more features, better documentation, and additional built-in animations. Expect some rough edges and potential breaking changes until then.

## Overview

Goofy adds fun ASCII animations that trigger when you run configured commands. Save a file? Get a cool animation. Run a test? Why not celebrate with some ASCII art?

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "itreau/goofy.nvim",
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
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "itreau/goofy.nvim",
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
    delay = 30,                 -- default frame delay in ms
    loop = false,               -- whether to loop animations
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
    command = "w",              -- triggers on :w
    animation = "write",        -- name of animation file (without .lua)
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

## Animation Strategies

Goofy supports multiple animation strategies. Each strategy defines how the animation is played.

### Keyframe Strategy (Default)

The keyframe strategy plays through a sequence of frames, displaying each for a set duration. This is the default strategy if no `type` is specified.

```lua
-- lua/goofy/animations/my_keyframe.lua
return {
  type = "keyframe",  -- optional, this is the default
  delay = 200,        -- milliseconds between frames
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

#### Heredoc Format (block text)

```lua
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

### Swipe Strategy

The swipe strategy moves a single frame across the screen in a specified direction until it swipes off-screen.

```lua
-- lua/goofy/animations/my_swipe.lua
return {
  type = "swipe",
  direction = "left",     -- "left", "right", "up", or "down"
  duration = 500,         -- total swipe duration in milliseconds
  frames = {
    [[
  ___
 /   \
|  W  |
 \___/
    ]],
  },
  opts = {
    color = "String",
    position = "center",
  },
}
```

#### Swipe Options

| Option      | Type   | Required | Description                                               |
| ----------- | ------ | -------- | --------------------------------------------------------- |
| `type`      | string | Yes      | Must be `"swipe"`                                         |
| `direction` | string | Yes      | Direction to swipe: `"left"`, `"right"`, `"up"`, `"down"` |
| `duration`  | number | Yes      | Total duration of the swipe animation in milliseconds     |
| `frames`    | table  | Yes      | Single frame to animate (array with one element)          |
| `opts`      | table  | No       | Window options (color, position, width, height)           |

## How It Works

1. **Setup**: Call `require("goofy").setup()` with your configuration
2. **Registration**: Goofy creates proxy commands (e.g., `:GoofyW`) that:
   - Execute the original command
   - Trigger the associated animation
3. **Animation**: A floating window displays the ASCII animation using the specified strategy

## Available Animations

- `write` - Simple "Saving..." animation
- `cool_glasses` - Cool glasses ASCII art
- `fire_meme` - Fire meme ASCII art
- Add your own in `lua/goofy/animations/`!

## Contributing

We welcome contributions! While users can create their own custom animations, we're building a standard library of fun ASCII animations that everyone can enjoy.

### Ways to Contribute

1. **New Animations** - Add creative ASCII animations to `lua/goofy/animations/`
2. **Bug Fixes** - Help squash those bugs
3. **Documentation** - Improve docs and examples
4. **Feature Requests** - Share your ideas for new animation strategies or triggers

### Contributing Animations

To contribute a new animation:

1. Create a new file in `lua/goofy/animations/`
2. Use one of the supported strategies (keyframe or swipe)
3. Test it works with your Neovim setup
4. Submit a PR with a description and preview (gif/screenshot appreciated!)

We especially welcome:

- Seasonal animations (holidays, events)
- Programming-themed ASCII art
- Fun reactions (success, error, celebration)
- Minimal, elegant animations

## License

MIT
