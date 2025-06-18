const admin = require('firebase-admin');

class FavoritesCleanup {
    constructor(serviceAccountPath, autoConfirm = false) {
        this.serviceAccountPath = serviceAccountPath;
        this.autoConfirm = autoConfirm;
        this.db = null;
        
        // Initialize Firebase Admin
        const serviceAccount = require(serviceAccountPath);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        this.db = admin.firestore();
    }

    async getExistingAISettings() {
        console.log('📋 Fetching existing AI settings...');
        
        try {
            const snapshot = await this.db.collection('aiSettings').get();
            const settings = new Set();
            
            snapshot.forEach(doc => {
                settings.add(doc.id);
            });

            console.log(`✓ Found ${settings.size} existing AI settings`);
            return settings;
        } catch (error) {
            throw new Error(`Failed to fetch AI settings: ${error.message}`);
        }
    }

    async getAllUsers() {
        console.log('👥 Fetching users...');
        
        try {
            const snapshot = await this.db.collection('users').get();
            const users = [];
            
            snapshot.forEach(doc => {
                users.push(doc.id);
            });

            console.log(`✓ Found ${users.length} users`);
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
            });
            
            return favorites;
        } catch (error) {
            // User might not have favorites subcollection
            return [];
        }
    }

    async findOrphanedFavorites(existingSettings) {
        const users = await this.getAllUsers();
        const orphanedFavorites = [];
        let totalFavorites = 0;
        let usersWithFavorites = 0;

        for (let i = 0; i < users.length; i++) {
            const userId = users[i];
            process.stdout.write(`🔍 Checking user ${i + 1}/${users.length}: ${userId}\r`);
            
            const favorites = await this.getUserFavorites(userId);
            
            if (favorites.length === 0) {
                continue;
            }

            usersWithFavorites++;
            totalFavorites += favorites.length;
            
            for (const favoriteId of favorites) {
                if (!existingSettings.has(favoriteId)) {
                    console.log(`\n   ❌ Orphaned favorite found: ${favoriteId}`);
                    orphanedFavorites.push({
                        userId,
                        favoriteId
                    });
                }
            }
        }

        console.log(`\n\n📊 Statistics:`);
        console.log(`Total users: ${users.length}`);
        console.log(`Users with favorites: ${usersWithFavorites}`);
        console.log(`Total favorites: ${totalFavorites}`);
        console.log(`Orphaned favorites found: ${orphanedFavorites.length}`);

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
            return true;
        } catch (error) {
            return false;
        }
    }

    async run() {
        try {
            const existingSettings = await this.getExistingAISettings();
            const orphanedFavorites = await this.findOrphanedFavorites(existingSettings);

            if (orphanedFavorites.length === 0) {
                console.log('🎉 No orphaned favorites found! Database is clean.');
                return { success: true, deleted: 0, failed: 0 };
            }

            console.log('\n🗑️  Orphaned favorites to be deleted:');
            orphanedFavorites.forEach((orphaned, index) => {
                console.log(`  ${index + 1}. users/${orphaned.userId}/favorites/${orphaned.favoriteId}`);
            });

            if (!this.autoConfirm) {
                console.log(`\n⚠️  This will permanently delete ${orphanedFavorites.length} orphaned favorite(s).`);
                return { needsConfirmation: true, orphanedFavorites };
            }

            return await this.performDeletion(orphanedFavorites);
        } catch (error) {
            throw new Error(`Cleanup failed: ${error.message}`);
        }
    }

    async performDeletion(orphanedFavorites) {
        console.log('\n🗑️  Deleting orphaned favorites...');
        let deletedCount = 0;
        let failedCount = 0;

        for (const orphaned of orphanedFavorites) {
            process.stdout.write(`Deleting users/${orphaned.userId}/favorites/${orphaned.favoriteId}... `);
            
            const success = await this.deleteOrphanedFavorite(orphaned);
            if (success) {
                console.log('✓ Success');
                deletedCount++;
            } else {
                console.log('✗ Failed');
                failedCount++;
            }
        }

        console.log(`\n📊 Deletion Summary:`);
        console.log(`✓ Successfully deleted: ${deletedCount}`);
        if (failedCount > 0) {
            console.log(`✗ Failed to delete: ${failedCount}`);
        }

        if (deletedCount > 0) {
            console.log('🎉 Cleanup completed successfully!');
        } else {
            console.log('⚠️  No favorites were deleted');
        }

        return { success: true, deleted: deletedCount, failed: failedCount };
    }
}

// Main execution
async function main() {
    const serviceAccountPath = process.argv[2];
    const autoConfirm = process.argv[3] === 'true';

    if (!serviceAccountPath) {
        console.error('Error: Service account path is required');
        process.exit(1);
    }

    try {
        const cleanup = new FavoritesCleanup(serviceAccountPath, autoConfirm);
        const result = await cleanup.run();

        if (result.needsConfirmation) {
            // Output the orphaned favorites for the bash script to handle confirmation
            console.log('\n__NEEDS_CONFIRMATION__');
            console.log(JSON.stringify(result.orphanedFavorites));
        }

        process.exit(0);
    } catch (error) {
        console.error(`❌ Error: ${error.message}`);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}
