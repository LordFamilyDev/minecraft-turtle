# Macro Toolkit (MTK) for ComputerCraft

## Overview

The Macro Toolkit (MTK) is a powerful scripting tool for ComputerCraft turtles, allowing users to create complex sequences of actions using simple, compact commands. MTK is designed to streamline turtle programming, making it easier to automate tasks in Minecraft.

## Features

- Compact command syntax for turtle actions
- Support for movement, digging, placing blocks, and inventory management
- Waypoint system for easy navigation
- Chest operations for automated storage management
- Jump and return functionality for creating loops and subroutines
- Inventory snapshot and replenishment capabilities

## Installation

1. Save the MTK script as `/bin/mtk` on your ComputerCraft computer or turtle.
2. Ensure that the required libraries (`move`, `item_types`, and `lib_debug`) are present in the `/lib/` directory.

## Usage

### Basic Syntax

MTK commands are typically two-character combinations. Here are some examples:

- `mf`: Move forward
- `mb`: Move backward
- `mu`: Move up
- `md`: Move down
- `tl`: Turn left
- `tr`: Turn right
- `df`: Dig forward
- `du`: Dig up
- `dd`: Dig down
- `pf`: Place forward
- `pu`: Place up
- `pd`: Place down

### Running MTK

To execute a sequence of MTK commands:

```lua
mtk("mfmftrdfpf")
```

This would move the turtle forward twice, turn right, dig forward, and place a block forward.

### Command-line Interface

MTK can be run from the command line with various options:

```
mtk [-m <macro_string>] [-j <jump_counts>] [-x <loop_counts>] [-v] [-t] [-S <save_path>] [-s <load_path>]
```

- `-m, --macro`: Specify the macro string to execute
- `-j, --jumps`: Specify jump counts for loops (e.g., "5,2,,2")
- `-x`: (Deprecated) Specify loop counts (use `-j` instead)
- `-v, --verbose`: Enable verbose debug output
- `-t, --test`: Enter test interface (REPL mode)
- `-S <path>`: Save inventory snapshot to file
- `-s <path>`: Load inventory snapshot from file

### Waypoints and Chests

- `W<x>`: Set waypoint (e.g., `W0` sets waypoint 0)
- `w<x>`: Go to waypoint (e.g., `w0` goes to waypoint 0)
- `C<x>`: Set chest position (e.g., `C0` sets chest 0)
- `c<x>`: Go to chest (e.g., `c0` goes to chest 0)

### Jumps and Returns

- `J<x>`: Set a jump label (e.g., `J0`)
- `j<x>`: Jump to a label (e.g., `j0`)
- `r<x>`: Return from a jump (e.g., `r0`)

Use these to create loops and subroutines in your macros.

### Inventory Management

- `s<x>`: Select inventory slot (hex value, e.g., `s0` for slot 1, `sa` for slot 11)
- `re`: Refuel the turtle
- `dt`: Dump trash items

## Examples

1. Simple mining operation:
   ```
   mtk -m "mfdfmfdfmfdf"
   ```

2. Create a 3x3 platform:
   ```
   mtk -m "pdmfpdmftrpdmfpdtrpdmfpd"
   ```

3. Loop with jumps:
   ```
   mtk -m "J0mfdfj0" -j 5
   ```
   This will move forward and dig 5 times.

4. Function-like behavior:
   ```
   mtk -m "J0mfdfr0muj0mdj0"
   ```
   This creates a reusable "move and dig" function.

## Note on Deprecated Features

The `-x` argument for specifying loop counts is deprecated. Please use the `-j` argument instead. The `-x` argument will be removed in a future version.

## Contributing

Contributions to MTK are welcome! Please submit pull requests or open issues on the project's GitHub repository.

## License

[Specify your license here]