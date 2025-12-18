# blobcat

Stream Azure Blob Storage files to stdout. Grep your data lake.

<img src="logo-bobcat.jpg" width="200" />


```bash
blobcat -a mystorageaccount -c lake -p "events/2025/12/18/" | grep "error"
```

## Why?

You have thousands of files in Azure Data Lake. You need to find something. Now you can grep it.

## Install

```bash
# Clone and make executable
git clone https://github.com/youruser/blobcat.git
chmod +x blobcat/blobcat

# Optional: add to PATH
sudo ln -s $(pwd)/blobcat/blobcat /usr/local/bin/blobcat
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
# Output: 2025-12-18_abc123.json:{"level":"ERROR","message":"..."}

# Skip cache, always download fresh
blobcat -a <account> -c <container> -p <path> --no-cache
```

## Options

| Flag | Long | Description |
|------|------|-------------|
| `-a` | `--account` | Storage account name |
| `-c` | `--container` | Container name |
| `-p` | `--path` | Folder path |
| `-n` | `--max` | Max files to stream |
| `-j` | `--jobs` | Parallel download workers (default: 8) |
| | `--no-cache` | Bypass local cache |
| | `--cache-info` | Show cache statistics |
| | `--cache-clean` | Remove all cached files |
| `-h` | `--help` | Show help |

## How it works

1. Lists all blobs in the specified path with sizes
2. Shows pre-flight: `Found 4813 files (1.2G). Streaming first 10...`
3. If all files are small (<100KB), downloads in parallel
4. Downloads each file and prefixes every line with the filename
5. Caches files locally for faster subsequent runs
6. Outputs to stdout for piping

Status messages go to stderr, content goes to stdout. Your pipes stay clean.

## Caching

Downloaded files are cached locally in `~/.cache/blobcat/` to speed up repeated queries.

```bash
# View cache statistics
blobcat --cache-info

# Clear the cache
blobcat --cache-clean

# Use custom cache directory
export BLOBCAT_CACHE_DIR=/tmp/blobcat-cache
```

The cache uses a simple file-based approach mirroring the blob path structure. Files are cached indefinitely until manually cleaned.

## Parallel Downloads

When all files in the query are small (<100KB), blobcat automatically downloads them in parallel using 8 workers (configurable with `-j`):

```bash
# Use 16 parallel workers
blobcat -a <account> -c <container> -p <path> -j 16
```

Large files are downloaded sequentially to avoid memory pressure.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `BLOBCAT_CACHE_DIR` | Override default cache directory (`~/.cache/blobcat`) |

## License

MIT
