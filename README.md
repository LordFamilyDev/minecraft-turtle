# minecraft-turtle

`wget run https://raw.githubusercontent.com/LordFamilyDev/minecraft-turtle/main/update.lua`
`wget run https://raw.githubusercontent.com/LordFamilyDev/minecraft-turtle/SCL/update.lua`

'wget run https://turtles.lordylordy.org/code/httpupdate.lua'

to use update you need a key file:
'token'
with your personal access token
'https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens'


# Folders:
all libraries should be under /lib
lua path can be then updated by:
`package.path = "/lib/?.lua;;"`
then included as
`mod = require("subfolder.modx")`
where `.` denotes a folder level

# ComputerCraft Remote Shell System

This project implements a remote shell system for ComputerCraft, allowing you to securely connect to and control remote computers or turtles. The system consists of three main components: `tSSH`, `tSSHd`, and `tSCP`.

## Components

### tSSH (SSH Client)

`tSSH` is the client-side script that allows you to connect to a remote computer or turtle running `tSSHd`.

#### Features:
- Connect to remote computers/turtles
- Execute commands and Lua scripts remotely
- Perform file system operations (ls, cd, mkdir, rm)
- Real-time output display for remote script execution

#### Usage:
```
tSSH [-v] <remote_id>
```
- `-v`: Verbose mode (optional)
- `<remote_id>`: The ID of the remote computer/turtle

### tSSHd (SSH Daemon)

`tSSHd` is the server-side script that runs on the computer or turtle you want to connect to remotely.

#### Features:
- Accept incoming connections
- Execute commands and Lua scripts
- Handle file system operations
- Manage multiple client sessions

#### Usage:
```
tSSHd [-v]
```
- `-v`: Verbose mode (optional)

### tSCP (Secure Copy)

`tSCP` is a utility for securely copying files between local and remote computers/turtles.

#### Features:
- Copy files from local to remote
- Copy files from remote to local

#### Usage:
```
tSCP <source> <destination>
```
- `<source>`: Local file path or `<remote_id>:path`
- `<destination>`: Local file path or `<remote_id>:path`

## Setup

1. Install the `lib_ssh` library on all computers/turtles that will use these scripts.
2. Place `tSSHd` on the computer/turtle you want to connect to remotely.
3. Place `tSSH` and `tSCP` on the computer you'll use as a client.

## Usage Examples

### Starting the SSH daemon:
On the remote computer/turtle:
```
> tSSHd
```

### Connecting to a remote computer/turtle:
On the client computer:
```
> tSSH 1
```
Replace `1` with the ID of the remote computer/turtle.

### Remote shell commands:
Once connected with tSSH, you can use the following commands:
- `ls`: List files in the current directory
- `cd <dir>`: Change directory
- `pwd`: Print working directory
- `mkdir <dir>`: Create a new directory
- `rm <file/dir>`: Remove a file or directory
- `<filename>`: Execute a Lua script
- `exit`: Close the SSH connection

### Copying files:
To copy a file from local to remote:
```
> tSCP localfile.lua 1:remotefile.lua
```

To copy a file from remote to local:
```
> tSCP 1:remotefile.lua localfile.lua
```

## Security Considerations

This system uses ComputerCraft's built-in rednet protocol for communication. While it provides basic functionality, it may not be secure against advanced attacks. Use this system in trusted environments only.

## Troubleshooting

- Ensure all computers/turtles have wireless modems equipped and enabled.
- Check that the remote ID is correct when using tSSH or tSCP.
- Use the `-v` flag for verbose output to diagnose connection issues.

## Contributing

Feel free to fork this project and submit pull requests with improvements or additional features.

## License

This project is open-source and available under the MIT License.