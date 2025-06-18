# Firestore Favorites Cleanup

A tool to clean up orphaned favorites that reference deleted AI bots in your Firestore database.

## Overview

This tool helps maintain data integrity by finding and removing "orphaned" favorites - user favorites that reference AI bots that no longer exist in the `aiSettings` collection. This can happen when bot creators delete their bots but the favorites remain in users' collections.

## Features

- 🔍 **Comprehensive Scanning**: Checks all users and their favorites subcollections
- 🛡️ **Safe Operation**: Asks for confirmation before deleting (unless auto-confirm is enabled)
- 📊 **Detailed Reporting**: Shows statistics and progress during operation
- 🏃‍♂️ **Dry Run Mode**: Preview what would be deleted without making changes
- 🎨 **Colorized Output**: Easy-to-read console output with colors
- 🔧 **Multiple Interfaces**: Both Bash and Node.js scripts available

## Prerequisites

- Node.js (version 14 or higher)
- A Firebase service account JSON file with Firestore read/write permissions

## Installation

1. Clone or download this repository
2. Install dependencies:
   ```bash
   npm install
   ```

Alternatively, if you prefer to install dependencies manually:
```bash
npm install firebase-admin
```

## Usage

### Node.js Script (Recommended)

```bash
# Basic usage
node cleanup-favorites.js /path/to/serviceAccount.json

# Dry run (preview only)
node cleanup-favorites.js /path/to/serviceAccount.json --dry-run

# Auto-confirm deletions
node cleanup-favorites.js /path/to/serviceAccount.json --yes

# Verbose output
node cleanup-favorites.js /path/to/serviceAccount.json --verbose

# Combine options
node cleanup-favorites.js /path/to/serviceAccount.json --dry-run --verbose
```

### Bash Script

```bash
# Make script executable
chmod +x cleanup-favorites.sh

# Basic usage
./cleanup-favorites.sh /path/to/serviceAccount.json

# Auto-confirm deletions
./cleanup-favorites.sh /path/to/serviceAccount.json --yes
```

### NPM Scripts

```bash
# Run cleanup (you'll need to edit package.json to add your service account path)
npm run cleanup

# Dry run
npm run cleanup-dry

# Auto-confirm
npm run cleanup-auto

# Show help
npm run help
```

## Command Line Options

### Node.js Script Options

| Option | Description |
|--------|-------------|
| `-y, --yes` | Auto-confirm deletions without prompting |
| `--dry-run` | Show what would be deleted without making changes |
| `-v, --verbose` | Show detailed output including individual operations |
| `-h, --help` | Show help message |

### Bash Script Options

| Option | Description |
|--------|-------------|
| `-y, --yes` | Auto-confirm deletions without prompting |
| `-h, --help` | Show help message |

## How It Works

1. **Connect to Firestore**: Uses your service account to authenticate with Firebase
2. **Fetch AI Settings**: Gets all existing AI bot IDs from the `aiSettings` collection
3. **Scan Users**: Iterates through all users in the `users` collection
4. **Check Favorites**: For each user, examines their `favorites` subcollection
5. **Identify Orphans**: Finds favorites that reference non-existent AI bots
6. **Confirm & Delete**: Shows what will be deleted and asks for confirmation (unless auto-confirm is enabled)

## Database Structure Expected

The tool expects your Firestore database to have this structure:

```
/
├── aiSettings/
│   ├── {botId1}
│   ├── {botId2}
│   └── ...
└── users/
    ├── {userId1}/
    │   └── favorites/
    │       ├── {botId1}    # Reference to AI bot
    │       ├── {botId2}    # Reference to AI bot
    │       └── ...
    ├── {userId2}/
    │   └── favorites/
    │       └── ...
    └── ...
```

## Sample Output

```
🔍 Starting cleanup of orphaned favorites...
Service Account: /path/to/serviceAccount.json
Auto-confirm deletions: false
Dry run: false

📋 Fetching existing AI settings...
✓ Found 18 existing AI settings

👥 Fetching users...
✓ Found 28 users

🔍 Checking user 1/28: 04vynw6cY7SkIo4pz1oaESsqnNs1
🔍 Checking user 2/28: 0AiBJIxWYZRUm9ISvjoxxOn3Xpk1
   ❌ Orphaned favorite found: deletedBotId123
🔍 Checking user 3/28: 1oyO836z5eU3OIpfXtqvQaBgHZ62
...

📊 Cleanup Summary:
Total users: 28
Users with favorites: 4
Total favorites: 8
Orphaned favorites found: 2

🗑️  Orphaned favorites to be deleted:
  1. users/cn1fJfbLCKOPh5mG0mzx8UBCL5j1/favorites/deletedBotId123
  2. users/AYXlDrleLlNXfE3m24LWbnmtQAI3/favorites/anotherDeletedBot

⚠️  This will permanently delete 2 orphaned favorite(s).
Do you want to proceed? (y/N): y

🗑️  Deleting orphaned favorites...
Deleting users/cn1fJfbLCKOPh5mG0mzx8UBCL5j1/favorites/deletedBotId123... ✓ Success
Deleting users/AYXlDrleLlNXfE3m24LWbnmtQAI3/favorites/anotherDeletedBot... ✓ Success

📊 Operation Summary:
✓ Successfully deleted: 2

🎉 Cleanup completed successfully!
```

## Service Account Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings → Service Accounts
4. Click "Generate New Private Key"
5. Save the JSON file securely
6. Ensure the service account has Firestore read/write permissions

## Safety Features

- **Confirmation Required**: By default, asks for user confirmation before deletion
- **Dry Run Mode**: Test what would be deleted without making changes
- **Detailed Logging**: Shows exactly what is being deleted
- **Error Handling**: Gracefully handles network issues and permission errors
- **Statistics**: Provides comprehensive statistics about the operation

## Troubleshooting

### Common Issues

**"firebase-admin package is required"**
```bash
npm install firebase-admin
```

**"Service account file not found"**
- Check the path to your service account JSON file
- Ensure the file exists and is readable

**"Permission denied"**
- Verify your service account has Firestore read/write permissions
- Check that you're using the correct project ID

**"No AI settings found"**
- Verify your database has an `aiSettings` collection with documents
- Check that the collection name matches exactly (case-sensitive)

### Debug Mode

For troubleshooting, use verbose mode:
```bash
node cleanup-favorites.js /path/to/serviceAccount.json --verbose --dry-run
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Run with `--verbose` flag for detailed output
3. Open an issue with your error message and setup details