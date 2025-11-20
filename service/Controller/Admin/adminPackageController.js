// Helper to generate a somewhat unique Package ID (replace with UUID in production if possible)
const generatePackageId = (productId = 'GEN') => {
    // Example: PK + last 3 chars of ProductID + 6 char timestamp hash
    const productPart = productId.slice(-3);
    const timePart = Date.now().toString(36).slice(-6).toUpperCase();
    return `PK${productPart}${timePart}`;
};

/**
 * Add a new package to a product.
 * @param {object} db - Database connection object.
 * @param {object} packageData - Data for the new package.
 * @param {string} packageData.productId - The Product_ID to associate with.
 * @param {string} packageData.packageName - The name of the package.
 * @param {number} packageData.packagePrice - The price of the package.
 * @param {string} [packageData.bonusDescription] - Optional bonus text.
 * @returns {Promise<object>} - A promise resolving to the newly created package object.
 */
export const addPackage = async (db, packageData) => {
    const { productId, packageName, packagePrice, bonusDescription } = packageData;

    // Basic Validation
    if (!productId || !packageName || packagePrice === undefined || packagePrice === null) {
        throw new Error("Missing required fields (productId, packageName, packagePrice) to add package.");
    }
    if (typeof packagePrice !== 'number' || packagePrice < 0) {
        throw new Error("Invalid packagePrice. Must be a non-negative number.");
    }

    const newPackageId = generatePackageId(productId); // Generate a new ID

    const query = `
        INSERT INTO Product_Package
            (Package_ID, Product_ID, Package_Name, Package_Price, Bonus_Description)
        VALUES (?, ?, ?, ?, ?);
    `;
    const params = [
        newPackageId,
        productId,
        packageName,
        packagePrice,
        bonusDescription || null // Ensure NULL is inserted if undefined/empty
    ];

    try {
        await db.promise().query(query, params);
        // Return the newly created package data
        return {
            packageId: newPackageId,
            productId,
            packageName,
            packagePrice,
            bonusDescription: bonusDescription || null
        };
    } catch (error) {
        console.error("Error adding new package:", error);
        // Handle potential duplicate Package_ID error if generation isn't unique enough
        if (error.code === 'ER_DUP_ENTRY') {
             throw new Error(`Failed to add package: Duplicate Package ID '${newPackageId}'. Please try again.`);
        }
        throw new Error("Failed to add new package due to a database error.");
    }
};

/**
 * Update an existing package.
 * @param {object} db - Database connection object.
 * @param {string} packageId - The ID of the package to update.
 * @param {object} packageData - Data to update. Can include packageName, packagePrice, bonusDescription.
 * @returns {Promise<object>} - A promise resolving to a success message and the updated package ID.
 */
export const updatePackage = async (db, packageId, packageData) => {
    if (!packageId) {
        throw new Error("Package ID is required for update.");
    }

    const { packageName, packagePrice, bonusDescription } = packageData;

    // Build SET clauses dynamically
    const setClauses = [];
    const params = [];

    if (packageName !== undefined) {
        setClauses.push("Package_Name = ?");
        params.push(packageName);
    }
    if (packagePrice !== undefined && packagePrice !== null) {
         if (typeof packagePrice !== 'number' || packagePrice < 0) {
             throw new Error("Invalid packagePrice. Must be a non-negative number.");
         }
        setClauses.push("Package_Price = ?");
        params.push(packagePrice);
    }
    // Allow setting bonusDescription to null or an empty string explicitly
    if (packageData.hasOwnProperty('bonusDescription')) {
        setClauses.push("Bonus_Description = ?");
        params.push(bonusDescription === '' ? null : bonusDescription); // Treat empty string as NULL in DB if desired
    }


    if (setClauses.length === 0) {
        throw new Error("No valid fields provided for update.");
    }

    params.push(packageId); // Add packageId for WHERE clause

    const query = `
        UPDATE Product_Package
        SET ${setClauses.join(', ')}
        WHERE Package_ID = ?;
    `;

    try {
        const [result] = await db.promise().query(query, params);

        if (result.affectedRows === 0) {
            throw new Error(`Package with ID ${packageId} not found for update.`);
        }

        return { message: "Package updated successfully.", packageId: packageId };
    } catch (error) {
        console.error(`Error updating package ${packageId}:`, error);
        if (error.message.includes("not found")) {
             throw error; // Re-throw specific not found error
        }
         if (error.message.includes("Invalid packagePrice")) {
             throw error; // Re-throw validation error
         }
        throw new Error(`Failed to update package ${packageId}.`);
    }
};

/**
 * Delete a package.
 * @param {object} db - Database connection object.
 * @param {string} packageId - The ID of the package to delete.
 * @returns {Promise<object>} - A promise resolving to a success message.
 */
export const deletePackage = async (db, packageId) => {
    if (!packageId) {
        throw new Error("Package ID is required for deletion.");
    }

    const query = `DELETE FROM Product_Package WHERE Package_ID = ?;`;

    try {
        const [result] = await db.promise().query(query, [packageId]);

        if (result.affectedRows === 0) {
            throw new Error(`Package with ID ${packageId} not found for deletion.`);
        }

        return { message: `Package ${packageId} deleted successfully.` };
    } catch (error) {
        console.error(`Error deleting package ${packageId}:`, error);
         if (error.message.includes("not found")) {
             throw error; // Re-throw specific not found error
        }
        throw new Error(`Failed to delete package ${packageId}.`);
    }
};