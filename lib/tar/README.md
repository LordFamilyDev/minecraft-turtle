# Tar and Untar for ComputerCraft

This project provides `tar` and `untar` functionality for ComputerCraft, allowing you to compress and decompress files and directories within your ComputerCraft environment.

## Features

- Compress files and directories into a single file
- Decompress tar files while preserving directory structure
- Uses LZP compression algorithm when native compression is unavailable
- Handles nested directories
- Ignores the `/rom` directory during compression

## Usage

### Tar (Compress)

To compress a file or directory:

```
tar <output_file_path> [target_file_path]
```

- `output_file_path`: The path where the compressed file will be saved.
- `target_file_path`: (Optional) The file or directory to compress. If not specified, the current directory will be used.

Example:
```
tar /compressed/myarchive.tar /documents
```

### Untar (Decompress)

To decompress a tar file:

```
untar <input_file_path> [target_file_path]
```

- `input_file_path`: The path to the compressed file.
- `target_file_path`: (Optional) The directory where files will be extracted. If not specified, the current directory will be used.

Example:
```
untar /compressed/myarchive.tar /extracted
```

## Important Considerations

1. **File Size Limits**: Be aware that ComputerCraft has file size limits. Very large files or collections of files might not be compressible.

2. **Rednet Limitations**: If you plan to transfer compressed files using Rednet, note that there's a 512 KB limit per message. Large compressed files might need to be split or transferred using alternative methods.

3. **Compression Method**: The script uses native ComputerCraft compression if available. Otherwise, it falls back to a custom LZP (Lempel-Ziv-Prediction) implementation.

4. **Nested Directories**: The tar functionality handles nested directories, compressing their structure and contents recursively.

5. **ROM Exclusion**: The `/rom` directory is always excluded from compression to avoid issues with read-only system files.

## Troubleshooting

If you encounter any issues:

- Ensure all scripts (`tar.lua`, `untar.lua`, and `lib_compression.lua`) are in the correct locations.
- Check that you have sufficient disk space for compression/decompression operations.
- For large files or directories, consider compressing/decompressing smaller chunks at a time.

## Contributing

Feel free to fork this project and submit pull requests with any improvements or bug fixes. Please ensure your code follows ComputerCraft Lua conventions and includes appropriate comments.

## License

This project is open source and available under the MIT License.