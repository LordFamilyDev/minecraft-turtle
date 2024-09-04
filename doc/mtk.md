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
- Advanced inventory management with automatic replenishment
- Ability to resume macros from a specific index
- Blind inventory selection and placement options
- Inventory snapshot serialization and deserialization
- Jump and return functionality for complex control flow

## Installation

1. Save the `mtk.lua` file to your turtle's file system.
2. (Optional) Place the `move.lua`, `item_types.lua`, and `lib_debug.lua` libraries in the `/lib/` directory for advanced functionality.

## Usage

### Command-line Interface

Run the script directly with:

```
mtk -m <macro_string> [-l <loop_count>] [-v] [-t] [-S <save_path>] [-s <load_path>] [-j <jump_list>]
```

Options:
- `-m, --macro`: Macro string (required unless -t is used)
- `-l, --loop`: Number of times to loop the macro (optional, default: 1)
- `-v, --verbose`: Enable debug output
- `-t, --test`: Enter test interface (REPL mode)
- `-S <path>`: Serialize and save inventory snapshot to file
- `-s <path>`: Load inventory snapshot from file
- `-j <list>`: Comma-separated list of numbers for jump list
- `-f <file>`: Load arguments from file
- `-h, --help`: Print help message

### As a Module

```lua
local mtk = require("mtk")
local success, error_message = mtk("mfmftrdfpf", 2)  -- Execute the macro "mfmftrdfpf" twice

if not success then
    print("Macro execution failed:", error_message)
end
```

### Macro Commands

- Movement: `mf` (forward), `mb` (back), `mu` (up), `md` (down), `tr` (turn right), `tl` (turn left)
- Digging: `df` (forward), `du` (up), `dd` (down)
- Placing: `pf` (forward), `pu` (up), `pd` (down)
- Blind Placing: `Pf` (forward), `Pu` (up), `Pd` (down)
- Inventory: `s[0-F]` (select slot with replenishment, hex)
- Blind Inventory Selection: `S[0-F]` (select slot without replenishment, hex)
- Inspection: `lf` (look forward), `lu` (look up), `ld` (look down)
- Waypoints: `W[c]` (set), `w[c]` (go to)
- Chests: `C[c]` (set), `c[c]` (go to)
- Utility: `re` (refuel), `dt` (dump trash), `gh` (go home), `Gh` (set home), `q` (quit)
- Jump and Return: `J[0-F]` (jump start), `j[0-F]` (jump), `r[0-F]` (return)

### Test Mode

In test mode, enter macro commands interactively. Special commands:
- `exit` or `q`: Quit the test interface
- `clear`: Clear the console

## Advanced Features

### Inventory Management

MTK includes advanced inventory management:
- At the start of a macro execution, a snapshot of the inventory is taken.
- When selecting a slot (`s[0-F]`), if the slot has 1 or fewer items and wasn't empty in the initial snapshot, MTK attempts to replenish it from other slots.
- When placing blocks (`pf`, `pu`, `pd`), if the current slot has 1 or fewer items, MTK attempts to replenish it based on the last selected slot's initial content.
- Blind selection (`S[0-F]`) and blind placement (`Pf`, `Pu`, `Pd`) commands are available for operations without automatic replenishment.

### Inventory Snapshot Serialization

You can save and load inventory snapshots:
- Use the `-S <path>` command-line option to save the current inventory snapshot to a file.
- Use the `-s <path>` command-line option to load a previously saved inventory snapshot.

### Jump and Return Functionality

MTK now supports complex control flow with jump and return commands:

- `J[0-F]`: Marks the start of a jump section (hex value 0-15)
- `j[0-F]`: Jumps to the corresponding `J` marker (hex value 0-15)
- `r[0-F]`: Returns from a jump section (hex value 0-15)

The `-j` command-line option allows you to specify a comma-separated list of numbers that determine how many times each jump section should be executed. Use empty values (e.g., `-j 2,,3`) to skip specifying counts for certain jumps.

Examples:

1. Simple jump:
   ```
   mtk -m "J0mfj0" -j 2
   ```
   This will execute `mf` twice.

2. Nested jumps:
   ```
   mtk -m "J0mfJ1trj1j0" -j 2,3
   ```
   This will move forward, turn right 3 times, and repeat this sequence twice.

3. Jump with return:
   ```
   mtk -m "j0J1mur1J0j1j1j1"
   ```
   This will move up three times by using jumps and returns.

## Error Handling

If MTK encounters an error during execution (e.g., failed movement, unable to place a block), it will pause execution and return:
- A boolean indicating success or failure
- An error message describing the issue

## Examples

1. Move forward 3 times, turn right, and dig:
   ```
   mtk -m mfmfmftrdf
   ```

2. Set a waypoint 'A', move in a square, and return to 'A':
   ```
   mtk -m WAmfmftrtrwA
   ```

3. Run a macro with jumps and returns:
   ```
   mtk -m "J0mfJ1trj1j0" -j 2,3
   ```

4. Save the current inventory snapshot and run a macro:
   ```
   mtk -S inventory.snap -m mfPfmfPf
   ```

5. Load a saved inventory snapshot and run a macro:
   ```
   mtk -s inventory.snap -m mfPfmfPf
   ```

6. Enter test mode:
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
