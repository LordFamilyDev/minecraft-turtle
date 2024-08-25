# minecraft-turtle

## Quick Start
Run one of the following commands:
```
wget run https://raw.githubusercontent.com/LordFamilyDev/minecraft-turtle/main/update.lua
wget run https://raw.githubusercontent.com/LordFamilyDev/minecraft-turtle/SCL/update.lua
wget run https://turtles.lordylordy.org/code/main/httpupdate.lua
```

To use the update feature, you need a key file named `token` with your personal access token. Learn more about personal access tokens [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).

## Project Structure

### Folders:
All libraries should be under `/lib`. You can update the Lua path by:
```lua
package.path = "/lib/?.lua;;"
```

Then include modules as:
```lua
mod = require("subfolder.modx")
```
Where `.` denotes a folder level.

### Additional Documentation:
- [Network Library Documentation](lib/net/README.md)
- [Tar Library Documentation](lib/tar/README.md)

## Contributing
Feel free to fork this project and submit pull requests with improvements or additional features.

## License
This project is open-source and available under the MIT License.