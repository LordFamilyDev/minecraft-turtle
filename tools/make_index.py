import os
import json
import hashlib
# import argparse

# Constants for argument names
ignore_list = [
    ".gitignore",
    "tools",
    ".git",
    "index.html"
]

output_file = "code_index.json"


def generate_directory_listing(directory_path, ignore_list, output_file):
    result = {}
    
    for root, dirs, files in os.walk(directory_path):
        for file in files:
            file_path = os.path.join(root, file)
            print(file_path)
            relative_path = os.path.relpath(file_path, directory_path)
            print(relative_path)
            
            # Skip files in the ignore list
            if any(ignore_item in relative_path for ignore_item in ignore_list):
                continue
            
            # Calculate SHA-256 hash
            sha256_hash = hashlib.sha256()
            with open(file_path, "rb") as f:
                for byte_block in iter(lambda: f.read(4096), b""):
                    sha256_hash.update(byte_block)
            file_hash = sha256_hash.hexdigest()
            
            # Add file info to result
            result[relative_path] = {
                "sha256": file_hash,
                "size": os.path.getsize(file_path)
            }
    
    # Write result to JSON file
    with open(output_file, 'w') as f:
        json.dump(result, f, indent=2)

if __name__ == "__main__":
    directory_path = os.getcwd()
    generate_directory_listing(directory_path, ignore_list, output_file)
    print(f"Directory listing has been saved to {output_file}")