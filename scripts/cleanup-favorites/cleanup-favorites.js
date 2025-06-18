#!/usr/bin/env node

/**
 * cleanup-favorites.js - Remove orphaned favorites that reference deleted AI bots
 * Usage: node cleanup-favorites.js <serviceAccount.json> [--yes] [--dry-run] [--verbose]
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// ANSI color codes
const colors = {
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    reset: '\x1b[0m',
    bold: '\x1b[1m'
};

class FavoritesCleanup {
    constructor(options = {}) {
        this.serviceAccount = options.serviceAccount;
        this.autoConfirm = options.autoConfirm || false;
        this.dryRun = options.dryRun || false;
        this.verbose = options.verbose || false;
        this.db = null;
        
        // Statistics
        this.stats = {
            totalUsers: 0,
            usersWithFavorites: 0,
            totalFavorites: 0,
            orphanedFavorites: 0,
            deletedFavorites: 0,
            failedDeletions: 0
        };
    }

    log(message, color = 'reset') {
        console.log(`${colors[color]}${message}${colors.reset}`);
    }

    logVerbose(message, color = 'reset') {
        if (this.verbose) {
            console.log(`${colors[color]}  ${message}${colors.reset}`);
        }
    }

    async initializeFirebase() {
        try {
            // Check if service account file exists
            if (!fs.existsSync(this.serviceAccount)) {
                throw new Error(`Service account file not found: ${this.serviceAccount}`);
            }

            // Read and validate service account file
            const serviceAccount = JSON.parse(fs.readFileSync(this.serviceAccount, 'utf8'));
            
            // Validate required fields
            const requiredFields = ['type', 'project_id', 'private_key_id', 'private_key', 'client_email'];
            for (const field of requiredFields) {
                if (!serviceAccount[field]) {
                    throw new Error(`Invalid service account file: missing field '${field}'`);
                }
            }

            // Initialize Firebase Admin
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });

            this.db = admin.firestore();
            this.logVerbose('Firebase initialized successfully', 'green');

        } catch (error) {
            if (error.code === 'ENOENT') {
                throw new Error(`Service account file not found: ${this.serviceAccount}`);
            } else if (error instanceof SyntaxError) {
                throw new Error(`Invalid JSON in service account file: ${this.serviceAccount}`);
            } else {
                throw new Error(`Failed to initialize Firebase: ${error.message}`);
            }
        }
    }

    async getExistingAISettings() {
        this.log('📋 Fetching existing AI settings...', 'blue');
        
        try {
            const snapshot = await this.db.collection('aiSettings').get();
            const settings = new Set();
            
            snapshot.forEach(doc => {
                settings.add(doc.id);
                this.logVerbose(`Found AI setting: ${doc.id}`, 'cyan');
            });

            if (settings.size === 0) {
                throw new Error('No AI settings found in the database');
            }

            this.log(`✓ Found ${settings.size} existing AI settings`, 'green');
            return settings;
        } catch (error) {
            throw new Error(`Failed to fetch AI settings: ${error.message}`);
        }
    }

    async getAllUsers() {
        this.log('👥 Fetching users...', 'blue');
        
        try {
            const snapshot = await this.db.collection('users').get();
            const users = [];
            
            snapshot.forEach(doc => {
                users.push(doc.id);
                this.logVerbose(`Found user: ${doc.id}`, 'cyan');
            });

            this.stats.totalUsers = users.length;
            this.log(`✓ Found ${users.length} users`, 'green');
            return users;
        } catch (error) {
            throw new Error(`Failed to fetch users: ${error.message}`);
        }
    }

    async getUserFavorites(userId) {
        try {
            const snapshot = await this.db
                .collection('users')
                .doc(userId)
                .collection('favorites')
                .get();
            
            const favorites = [];
            snapshot.forEach(doc => {
                favorites.push(doc.id);
                this.logVerbose(`Found favorite for ${userId}: ${doc.id}`, 'cyan');
            });
            
            return favorites;
        } catch (error) {
            this.logVerbose(`Error fetching favorites for ${userId}: ${error.message}`, 'yellow');
            return [];
        }
    }

    async findOrphanedFavorites(existingSettings) {
        const users = await this.getAllUsers();
        const orphanedFavorites = [];

        for (let i = 0; i < users.length; i++) {
            const userId = users[i];
            this.log(`🔍 Checking user ${i + 1}/${users.length}: ${userId}`, 'blue');
            
            const favorites = await this.getUserFavorites(userId);
            
            if (favorites.length === 0) {
                this.logVerbose('No favorites found');
                continue;
            }

            this.stats.usersWithFavorites++;
            this.stats.totalFavorites += favorites.length;
            this.logVerbose(`Found ${favorites.length} favorites`);
            
            for (const favoriteId of favorites) {
                if (!existingSettings.has(favoriteId)) {
                    this.log(`   ❌ Orphaned favorite found: ${favoriteId}`, 'red');
                    orphanedFavorites.push({
                        userId,
                        favoriteId,
                        path: `users/${userId}/favorites/${favoriteId}`
                    });
                    this.stats.orphanedFavorites++;
                } else {
                    this.logVerbose(`✓ Valid favorite: ${favoriteId}`, 'green');
                }
            }
        }

        return orphanedFavorites;
    }

    async deleteOrphanedFavorite(orphaned) {
        try {
            await this.db
                .collection('users')
                .doc(orphaned.userId)
                .collection('favorites')
                .doc(orphaned.favoriteId)
                .delete();
            
            this.logVerbose(`Successfully deleted: ${orphaned.path}`, 'green');
            return true;
        } catch (error) {
            this.logVerbose(`Failed to delete ${orphaned.path}: ${error.message}`, 'red');
            return false;
        }
    }

    async confirmDeletion(orphanedFavorites) {
        if (this.autoConfirm) {
            return true;
        }

        console.log();
        this.log(`⚠️  This will permanently delete ${orphanedFavorites.length} orphaned favorite(s).`, 'yellow');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });

        return new Promise((resolve) => {
            rl.question('Do you want to proceed? (y/N): ', (answer) => {
                rl.close();
                resolve(answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes');
            });
        });
    }

    printSummary(orphanedFavorites) {
        console.log();
        this.log('📊 Cleanup Summary:', 'blue');
        console.log(`Total users: ${this.stats.totalUsers}`);
        console.log(`Users with favorites: ${this.stats.usersWithFavorites}`);
        console.log(`Total favorites: ${this.stats.totalFavorites}`);
        console.log(`Orphaned favorites found: ${this.stats.orphanedFavorites}`);

        if (orphanedFavorites.length > 0) {
            console.log();
            this.log('🗑️  Orphaned favorites to be deleted:', 'yellow');
            orphanedFavorites.forEach((orphaned, index) => {
                console.log(`  ${index + 1}. ${orphaned.path}`);
            });
        }
    }

    printFinalStats() {
        console.log();
        this.log('📊 Operation Summary:', 'blue');
        if (this.dryRun) {
            this.log('✓ Dry run completed - no changes made', 'green');
        } else {
            console.log(`✓ Successfully deleted: ${this.stats.deletedFavorites}`);
            if (this.stats.failedDeletions > 0) {
                this.log(`✗ Failed to delete: ${this.stats.failedDeletions}`, 'red');
            }
        }
    }

    async run() {
        try {
            this.log('🔍 Starting cleanup of orphaned favorites...', 'blue');
            console.log(`Service Account: ${this.serviceAccount}`);
            console.log(`Auto-confirm deletions: ${this.autoConfirm}`);
            console.log(`Dry run: ${this.dryRun}`);
            console.log(`Verbose: ${this.verbose}`);
            console.log();

            await this.initializeFirebase();

            const existingSettings = await this.getExistingAISettings();
            const orphanedFavorites = await this.findOrphanedFavorites(existingSettings);

            this.printSummary(orphanedFavorites);

            if (orphanedFavorites.length === 0) {
                this.log('🎉 No orphaned favorites found! Database is clean.', 'green');
                return;
            }

            if (this.dryRun) {
                this.log('🔍 Dry run completed - no changes made', 'cyan');
                return;
            }

            const confirmed = await this.confirmDeletion(orphanedFavorites);
            if (!confirmed) {
                this.log('ℹ️  Cleanup cancelled by user', 'blue');
                return;
            }

            // Delete orphaned favorites
            console.log();
            this.log('🗑️  Deleting orphaned favorites...', 'blue');

            for (const orphaned of orphanedFavorites) {
                process.stdout.write(`Deleting ${orphaned.path}... `);
                
                const success = await this.deleteOrphanedFavorite(orphaned);
                if (success) {
                    this.log('✓ Success', 'green');
                    this.stats.deletedFavorites++;
                } else {
                    this.log('✗ Failed', 'red');
                    this.stats.failedDeletions++;
                }
            }

            this.printFinalStats();

            if (this.stats.deletedFavorites > 0) {
                this.log('🎉 Cleanup completed successfully!', 'green');
            } else {
                this.log('⚠️  No favorites were deleted', 'yellow');
            }

        } catch (error) {
            this.log(`❌ Error: ${error.message}`, 'red');
            process.exit(1);
        }
    }
}

// Parse command line arguments
function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        autoConfirm: false,
        dryRun: false,
        verbose: false,
        serviceAccount: null
    };

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        
        switch (arg) {
            case '-y':
            case '--yes':
                options.autoConfirm = true;
                break;
            case '--dry-run':
                options.dryRun = true;
                break;
            case '-v':
            case '--verbose':
                options.verbose = true;
                break;
            case '-h':
            case '--help':
                console.log('Usage: node cleanup-favorites.js <serviceAccount.json> [options]');
                console.log('');
                console.log('Remove orphaned favorites that reference deleted AI bots');
                console.log('');
                console.log('Arguments:');
                console.log('  serviceAccount.json    Path to Firebase service account JSON file');
                console.log('');
                console.log('Options:');
                console.log('  -y, --yes              Auto-confirm deletions without prompting');
                console.log('  --dry-run              Show what would be deleted without making changes');
                console.log('  -v, --verbose          Show verbose output');
                console.log('  -h, --help             Show this help message');
                console.log('');
                console.log('Examples:');
                console.log('  node cleanup-favorites.js ./serviceAccount.json');
                console.log('  node cleanup-favorites.js ./serviceAccount.json --dry-run');
                console.log('  node cleanup-favorites.js ./serviceAccount.json --yes --verbose');
                process.exit(0);
                break;
            default:
                if (arg.startsWith('-')) {
                    console.error(`Error: Unknown option: ${arg}`);
                    console.error('Use --help for usage information');
                    process.exit(1);
                } else if (!options.serviceAccount) {
                    options.serviceAccount = arg;
                } else {
                    console.error('Error: Too many arguments');
                    console.error('Use --help for usage information');
                    process.exit(1);
                }
        }
    }

    if (!options.serviceAccount) {
        console.error('Error: Service account file is required');
        console.error('Usage: node cleanup-favorites.js <serviceAccount.json> [options]');
        console.error('Use --help for more information');
        process.exit(1);
    }

    return options;
}

// Check if firebase-admin is available
function checkDependencies() {
    try {
        require('firebase-admin');
    } catch (error) {
        console.error('Error: firebase-admin package is required');
        console.error('Please install it by running: npm install firebase-admin');
        console.error('');
        console.error('If you want to install it globally: npm install -g firebase-admin');
        process.exit(1);
    }
}

// Main execution
if (require.main === module) {
    checkDependencies();
    const options = parseArgs();
    const cleanup = new FavoritesCleanup(options);
    cleanup.run();
}