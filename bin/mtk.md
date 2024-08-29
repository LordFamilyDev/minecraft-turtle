# Macro Toolkit (MTK) for ComputerCraft Turtles

## Overview

The Macro Toolkit (MTK) is a versatile Lua script designed for ComputerCraft turtles. It provides a simple yet powerful macro system for automating turtle actions, with support for both command-line execution and integration as a module in other scripts.

## Features

- Compact macro language for turtle actions
- Support for movement, digging, placing, and inventory management
- Waypoint and chest position management
- Integration with advanced movement libraries (when available)
- Command-line interface with looping and verbose mode options
- Interactive test mode (REPL) for easy experimentation
- Extensible with custom functions

## Installation

1. Save the `mtk.lua` file to your turtle's file system.
2. (Optional) Place the `move.lua`, `item_types.lua`, and `lib_debug.lua` libraries in the `/lib/` directory for advanced functionality.

## Usage

### Command-line Interface

Run the script directly with:

```
mtk -m <macro_string> [-l <loop_count>] [-v] [-t]
```

Options:
- `-m, --macro`: Macro string (required unless -t is used)
- `-l, --loop`: Number of times to loop the macro (optional, default: 1)
- `-v, --verbose`: Enable debug output
- `-t, --test`: Enter test interface (REPL mode)
- `-h, --help`: Print help message

### As a Module

```lua
local mtk = require("mtk")
mtk("mfmftrdfpf", 2)  -- Execute the macro "mfmftrdfpf" twice
```

### Macro Commands

- Movement: `mf` (forward), `mb` (back), `mu` (up), `md` (down), `tr` (turn right), `tl` (turn left)
- Digging: `df` (forward), `du` (up), `dd` (down)
- Placing: `pf` (forward), `pu` (up), `pd` (down)
- Inventory: `s[0-F]` (select slot, hex)
- Inspection: `lf` (look forward), `lu` (look up), `ld` (look down)
- Waypoints: `W[c]` (set), `w[c]` (go to)
- Chests: `C[c]` (set), `c[c]` (go to)
- Utility: `re` (refuel), `dt` (dump trash), `gh` (go home), `Gh` (set home), `q` (quit)

### Test Mode

In test mode, enter macro commands interactively. Special commands:
- `exit` or `q`: Quit the test interface
- `clear`: Clear the console

## Examples

1. Move forward 3 times, turn right, and dig:
   ```
   mtk -m mfmfmftrdf
   ```

2. Set a waypoint 'A', move in a square, and return to 'A':
   ```
   mtk -m WAmfmftrtrwA
   ```

3. Run a macro 5 times with verbose output:
   ```
   mtk -m mfdfmbdu -l 5 -v
   ```

4. Enter test mode:
   ```
   mtk -t
   ```

## Extending MTK

Custom functions can be added to `mtk.func` table:

```lua
local mtk = require("mtk")
mtk.func.x = function() 
    -- Custom function logic
end
```

Then use `fx` in your macro to call this function.

## Dependencies

- ComputerCraft environment
- (Optional) Move Library (`/lib/move.lua`)
- (Optional) Item Types Library (`/lib/item_types.lua`)
- (Optional) Debug Library (`/lib/lib_debug.lua`)

## License

[Specify your license here]

## Contributing

[Add contribution guidelines if applicable]