// categoryController.js

/**
 * Generates the next Category ID based on the highest existing ID with the 'CATG' prefix.
 * Assumes ID format 'CATG' + 6 zero-padded digits (total 10 chars).
 * @param {object} db - Database connection object.
 * @returns {Promise<string>} Promise resolving with the next Category ID.
 */
function getNextCategoryId(db) {
    return new Promise((resolve, reject) => {
        // Query to find the highest numeric part of existing Category IDs starting with 'CATG'
        // Ensure the SUBSTRING index and CAST type are correct for your specific database version/setup.
        const query_sql = `
            SELECT MAX(CAST(SUBSTRING(Category_ID, 5) AS UNSIGNED)) as maxId 
            FROM Product_Category 
            WHERE Category_ID LIKE 'CATG%'`;

        db.query(query_sql, (err, results) => {
            if (err) {
                console.error("Error finding max category ID:", err);
                return reject(new Error("Could not generate new category ID."));
            }

            let nextNumericId = 1; // Default if no categories exist yet
            if (results.length > 0 && results[0].maxId !== null) {
                nextNumericId = results[0].maxId + 1;
            }

            // Format the new ID: 'CATG' followed by the number padded with leading zeros to fit CHAR(10)
            // 'CATG' is 4 chars, so pad the number to 6 digits.
            const newCategoryId = `CATG${nextNumericId.toString().padStart(6, "0")}`; 
            
            // Optional: Add a check if the generated ID exceeds the CHAR(10) limit, though unlikely with this padding.
            if (newCategoryId.length > 10) {
                 return reject(new Error("Generated Category ID exceeds maximum length."));
            }

            resolve(newCategoryId);
        });
    });
}


/**
 * Fetches all categories from the database.
 * @param {object} db - Database connection object.
 * @returns {Promise<Array>} Promise resolving with an array of categories { Category_ID, Category_name }.
 */
export function getAllCategories(db) {
    return new Promise((resolve, reject) => {
        // Use the exact column names from the DB schema
        const query_sql = "SELECT Category_ID, Category_name FROM Product_Category ORDER BY Category_name"; 

        db.query(query_sql, (err, results) => {
            if (err) {
                console.error("Error querying categories:", err);
                reject(err);
                return;
            }
            console.log("Categories retrieved successfully.");
            resolve(results); // results should already match the { Category_ID, Category_name } structure
        });
    });
}

/**
 * Adds a new category to the database.
 * Generates a new Category_ID automatically.
 * @param {object} db - Database connection object.
 * @param {object} categoryData - Object containing category data, expects { categoryName: string }.
 * @returns {Promise<object>} Promise resolving with the add result including the new Category_ID.
 */
export function addCategory(db, categoryData) {
    return new Promise(async (resolve, reject) => { // Added async for await
        // Basic validation
        if (!categoryData || !categoryData.categoryName || categoryData.categoryName.trim() === "") {
            return reject(new Error("Category name is required and cannot be empty."));
        }

        const categoryName = categoryData.categoryName.trim();

        try {
            // --- Generate New ID ---
            const newCategoryId = await getNextCategoryId(db); 

            // --- Insert into DB ---
            // Use the exact column names from the DB schema
            const insert_sql = `
                INSERT INTO Product_Category (Category_ID, Category_name) 
                VALUES (?, ?)
            `;
            const params = [newCategoryId, categoryName];

            db.query(insert_sql, params, (err, results) => {
                if (err) {
                    console.error("Error adding category:", err);
                    // Check for duplicate category name if you add a UNIQUE constraint to the DB
                    if (err.code === 'ER_DUP_ENTRY') { 
                        // Check err.message to confirm it's the name constraint
                         return reject(new Error(`A category with the name "${categoryName}" might already exist.`));
                    }
                    reject(err); // Handle other DB errors
                    return;
                }

                if (results.affectedRows > 0) {
                    console.log(`New category added with ID ${newCategoryId} and name "${categoryName}".`);
                    resolve({
                        message: `Category "${categoryName}" added successfully.`,
                        Category_ID: newCategoryId, // Return the generated ID
                        Category_name: categoryName, // Return the name
                        results,
                    });
                } else {
                     // Should not happen with INSERT unless something unexpected occurred
                     reject(new Error("Failed to add category, no rows affected."));
                }
            });

        } catch (idError) {
            // Handle errors from getNextCategoryId
            reject(idError);
        }
    });
}


/**
 * Updates an existing category in the database.
 * @param {object} db - Database connection object.
 * @param {string} categoryId - The ID of the category to update.
 * @param {object} categoryData - Object containing updated data, expects { categoryName: string }.
 * @returns {Promise<object>} Promise resolving with the update result.
 */
export function updateCategory(db, categoryId, categoryData) {
    return new Promise((resolve, reject) => {
        // Basic validation
        if (!categoryId) {
             return reject(new Error("Category ID is required for updating."));
        }
        if (!categoryData || !categoryData.categoryName || categoryData.categoryName.trim() === "") {
            return reject(new Error("Category name is required and cannot be empty."));
        }

        const categoryName = categoryData.categoryName.trim();
        
        // Use the exact column names from the DB schema
        const update_sql = `
            UPDATE Product_Category 
            SET Category_name = ? 
            WHERE Category_ID = ?
        `;
        const params = [categoryName, categoryId];

        db.query(update_sql, params, (err, results) => {
            if (err) {
                console.error(`Error updating category with ID ${categoryId}:`, err);
                 // Check for duplicate category name if you add a UNIQUE constraint
                 if (err.code === 'ER_DUP_ENTRY') {
                    return reject(new Error(`A category with the name "${categoryName}" might already exist.`));
                 }
                reject(err);
                return;
            }

            if (results.affectedRows > 0) {
                console.log(`Category with ID ${categoryId} updated successfully to name "${categoryName}".`);
                resolve({
                    message: `Category updated successfully.`,
                    Category_ID: categoryId,
                    Category_name: categoryName,
                    results,
                });
            } else {
                console.log(`Category with ID ${categoryId} not found or no changes made.`);
                // It's often better to signal 'not found' specifically
                reject(new Error(`Category with ID ${categoryId} not found.`)); 
            }
        });
    });
}


/**
 * Deletes a category from the database.
 * Checks for foreign key constraints before deleting.
 * @param {object} db - Database connection object.
 * @param {string} categoryId - The ID of the category to delete.
 * @returns {Promise<object>} Promise resolving with the deletion result.
 */
export function deleteCategory(db, categoryId) {
    return new Promise((resolve, reject) => {
        if (!categoryId) {
            return reject(new Error("Category ID is required for deletion."));
        }

        // Use the exact table and column names from the DB schema
        const delete_sql = "DELETE FROM Product_Category WHERE Category_ID = ?";

        db.query(delete_sql, [categoryId], (err, results) => {
            if (err) {
                console.error(`Error deleting category with ID ${categoryId}:`, err);
                // Check for foreign key constraint violation (MySQL specific code)
                // This error code indicates a row in another table references this category
                if (err.code === 'ER_ROW_IS_REFERENCED_2' || err.code === 'ER_ROW_IS_REFERENCED') {
                     console.warn(`Attempted to delete category ${categoryId} which is in use by products.`);
                     return reject(new Error(`Cannot delete category: It is currently assigned to one or more products.`));
                }
                // Handle other potential database errors
                reject(err);
                return;
            }

            if (results.affectedRows > 0) {
                console.log(`Category with ID ${categoryId} deleted successfully.`);
                resolve({ message: `Category with ID ${categoryId} deleted successfully.` });
            } else {
                console.log(`Category with ID ${categoryId} not found for deletion.`);
                 // Reject if the category didn't exist
                reject(new Error(`Category with ID ${categoryId} not found.`));
            }
        });
    });
}