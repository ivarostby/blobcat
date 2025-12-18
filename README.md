# blobcat

Stream Azure Blob Storage files to stdout. Grep your data lake.

```bash
blobcat -a mystorageaccount -c lake -p "events/2025/12/18/" | grep "error"
```

## Why?

You have thousands of files in Azure Data Lake. You need to find something. Now you can grep it.

## Install

```bash
# Clone and make executable
git clone https://github.com/youruser/lake-grep.git
chmod +x lake-grep/blobcat

# Optional: add to PATH
sudo ln -s $(pwd)/lake-grep/blobcat /usr/local/bin/blobcat
```

**Requirements:** Azure CLI installed and logged in (`az login`)

## Usage

```bash
# Stream all files in a folder
blobcat -a <account> -c <container> -p <path>

# Limit to first 10 files (recommended for large folders)
blobcat -a <account> -c <container> -p <path> -n 10

# Grep for something
blobcat -a <account> -c <container> -p <path> | grep "needle"

# Find which file contains an error
blobcat -a <account> -c <container> -p <path> | grep "ERROR"
# Output: 2025-12-18_abc123.xml.gz:{"level":"ERROR","message":"..."}
```

## Options

| Flag | Long | Description |
|------|------|-------------|
| `-a` | `--account` | Storage account name |
| `-c` | `--container` | Container name |
| `-p` | `--path` | Folder path |
| `-n` | `--max` | Max files to stream |
| `-h` | `--help` | Show help |

## How it works

1. Lists all blobs in the specified path
2. Shows pre-flight: `Found 4813 files. Streaming first 10...`
3. Downloads each file and prefixes every line with the filename
4. Outputs to stdout for piping

Status messages go to stderr, content goes to stdout. Your pipes stay clean.

## License

MIT
