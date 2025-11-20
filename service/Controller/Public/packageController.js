// Controller/Admin/packageController.js (or Controller/Public/packageController.js if needed publicly)


// --- CRUD Functions for Product_Package ---

/**
 * Fetch all packages associated with a specific Product ID.
 * @param {object} db - Database connection object.
 * @param {string} productId - The ID of the product whose packages are needed.
 * @returns {Promise<Array>} - A promise resolving to an array of package objects.
 */
export const getPackagesByProductId = async (db, productId) => {
    if (!productId) {
        throw new Error("Product ID is required to fetch packages.");
    }

    const query = `
        SELECT
            Package_ID AS packageId,
            Product_ID AS productId,
            Package_Name AS packageName,
            Package_Price AS packagePrice,
            Bonus_Description AS bonusDescription
        FROM Product_Package
        WHERE Product_ID = ?
        ORDER BY Package_Price ASC;
    `; // Ordering by price is often useful

    try {
        const [packages] = await db.promise().query(query, [productId]);
        // Ensure price is returned as a number
        return packages.map(pkg => ({
            ...pkg,
            packagePrice: parseFloat(pkg.packagePrice)
        }));
    } catch (error) {
        console.error(`Error fetching packages for Product ID ${productId}:`, error);
        throw new Error(`Failed to fetch packages for product ${productId}.`);
    }
};

/**
 * Fetch a single package by its Package ID.
 * @param {object} db - Database connection object.
 * @param {string} packageId - The ID of the package to fetch.
 * @returns {Promise<object|null>} - A promise resolving to the package object or null if not found.
 */
export const getPackageById = async (db, packageId) => {
    if (!packageId) {
        throw new Error("Package ID is required.");
    }

    const query = `
        SELECT
            Package_ID AS packageId,
            Product_ID AS productId,
            Package_Name AS packageName,
            Package_Price AS packagePrice,
            Bonus_Description AS bonusDescription
        FROM Product_Package
        WHERE Package_ID = ?;
    `;

    try {
        const [results] = await db.promise().query(query, [packageId]);
        if (results.length === 0) {
            return null; // Not found
        }
        const pkg = results[0];
        // Ensure price is returned as a number
        return {
            ...pkg,
            packagePrice: parseFloat(pkg.packagePrice)
        };
    } catch (error) {
        console.error(`Error fetching package with ID ${packageId}:`, error);
        throw new Error(`Failed to fetch package ${packageId}.`);
    }
};