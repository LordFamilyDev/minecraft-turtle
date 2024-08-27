# minecraft-turtle

## Quick Start
'''
wget run https://turtles.lordylordy.org/code/main/update.lua -m
-m          pulls from main repo
-b <branch>  pulls from a published branch
-w <user>   pulls from that users WIP folder
-u <url>    pulls from a caddy fileserve with root at url
'''

## Update Process
### Intended Workflow:
- Use ~/turtles directory on lordylordy.org. 
    - This maps to a public fileserver at: `https:\\turtles.lordylordy.org\wip\<user>\`
- Checkout the github repository into your turtles folder via:
    - git clone <git url> ~/turtles
- Code / debug / have fun
- Pull your code into your turtle via the -w <user> option
    - wget run https://turtles.lordylordy.org/code/main/update.lua -w user
- Finish debugging
- Commit your code to your personal fork|branch
- Create pull request to merge your code into main.
- Approve and merge pull request
- Pull main repo into turtle usint `update -m'
    - Or full URL: `wget run https://turtles.lordylordy.org/code/main/update.lua -m`
- turtles away!

### Github
    Github is configured to publish code to `https:\\turtles.lordylordy.org\code\<branch>' on any
    merge or commit to that branch.  Main can be accessed via `-m` other branches can be accessed via
    `-b <branch>`

    Under the hood, Github posts to  `/usr/share/caddy/code/'  on lordylordy.org

### Local working Directory
    Each of you is set up with a working directory in your home directory: ~/turtles.  This is
    a symlinked directory '/usr/share/caddy/wip/<user>' Files in this directory can be accessed via:
    'https://turtles.lordylordy.org/wip/<user>'. The idea is to allow quick cycle times while debugging code.
    You can use your own file server with update by specifying your own root url with -u.  however it shoudl be noted
    that update currently relies on the json formatted directory listings provided by caddy file-server.

## Notes:
### Switching Branches:
    Internally update stores the last url used in .updateInfo.json
    When called without arguments update first looks for this file and if it exists uses that url to pull files.
    If the file does not exist update will prompt for a URL ala the -u option
    IF an argument is used update will switch to the new file location as specified by the args and 
    will store that for further use.

### File hashes / Timestamps:
   update stores the caddy json directory listings in `.listing.json` in the root of each directory.
   that file contains an update timestamp as well as a file size.  update uses this info to determine
   if it needs to pull a new version of any file.


## Depreciated methods
Run one of the following commands:
```
wget run https://raw.githubusercontent.com/LordFamilyDev/minecraft-turtle/main/gitupdate.lua
wget run https://raw.githubusercontent.com/LordFamilyDev/minecraft-turtle/SCL/gitupdate.lua
wget run https://turtles.lordylordy.org/code/main/httpupdate.lua
wget run https://turtles.lordylordy.org/wip/SCL/update.lua -w SCL
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