This document describes the custom JSON format used to define structures for Minecraft turtles to build using the `print.lua` script.

## Format Overview

The JSON file should contain two main sections:
1. `palette`: A mapping of block identifiers to block information.
2. `layerMap`: A 3D representation of the structure, using the block identifiers defined in the palette.

### Basic Structure

```json
{
  "palette": {
    " ": {"name": "minecraft:air"},
    "0": {"name": "minecraft:stone"},
    "1": {"name": "minecraft:dirt"},
    ...
  },
  "layerMap": [
    [
      "000000",
      "0    0",
      "000000"
    ],
    [
      "111111",
      "1    1",
      "111111"
    ],
    ...
  ]
}
```

Palette
The palette object maps single-character identifiers to block information.

Keys: Single characters from 0 to f (hexadecimal digits) and space  .
Values: Objects containing block information.

Special Identifiers

Space  : Always represents air (empty space).

Block Information
Each block in the palette should have a name property, which is the Minecraft identifier for the block.
Example:
```json
"0": {"name": "minecraft:stone"},
"1": {"name": "minecraft:oak_planks"}
```

LayerMap
The layerMap is an array of layers, starting from the bottom of the structure.

Each layer is an array of strings.
Each string represents a column in the structure.
Characters in the strings correspond to the identifiers in the palette.

Layer Structure

The outermost array represents the Y-axis (vertical layers).
Each layer array contains strings representing the X-axis (width).
Characters within each string represent the Z-axis (depth).

Example:
```json
"layerMap": [
  [
    "000",  // First column (X=0)
    "0 0",  // Second column (X=1)
    "000"   // Third column (X=2)
  ],
  [
    "111",
    "1 1",
    "111"
  ]
]
```
This example defines a 3x3x2 structure with a hollow center.
Usage with print.lua

Create your JSON file following this format.
Ensure your turtle has the necessary blocks in its inventory.
Run the print.lua script with your JSON file as an argument:
```
print your_structure.json
```


The turtle will then build the structure layer by layer, using the blocks specified in the palette.
Notes

Ensure all layers have the same dimensions (width and depth).
The turtle's inventory slots correspond to the palette identifiers (0-f).
Air blocks (space  ) are not placed and are skipped during building.