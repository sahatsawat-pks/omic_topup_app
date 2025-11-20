// adminProductController.js
import fs from 'fs';     // Import file system module
import path from 'path'; // Import path module
import { fileURLToPath } from 'url';

const UPLOAD_BASE_URL = '/img/products/'; // Relative URL path for frontend access
const UPLOADS_FOLDER = './img/products/'; // Relative file system path for backend access

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Adds a new product to the database, including handling photo upload.
 * @param {object} db - Database connection object.
 * @param {object} productData - Object containing new product text data.
 * @param {object|null} photoFile - Uploaded file object from Multer (req.file) or null.
 * @returns {Promise<object>} Promise resolving with the add result including new ID and photo path.
 */
export function addProduct(db, productData, photoFile) { // Added photoFile parameter
    return new Promise((resolve, reject) => {
        // Basic validation (same as before)
        if (!productData || !productData.name || productData.name.trim() === "") return reject(new Error("Product name is required."));
        if (!productData.categoryId) return reject(new Error("Product category ID is required."));
        if (productData.instockQuantity === undefined || productData.instockQuantity < 0) return reject(new Error("In Stock quantity must be a non-negative number."));
        if (productData.price === undefined || productData.price < 0) return reject(new Error("Price must be a non-negative number."));
        if (productData.rating === undefined || productData.rating < 0) return reject(new Error("Rating must be a non-negative number."));

        // Determine photo path
        // Store the relative URL path, not the full file system path
        const photoPath = photoFile ? path.join(UPLOAD_BASE_URL, photoFile.filename).replace(/\\/g, '/') : null;

        // --- ID Generation (Keep existing logic) ---
         db.query(
            "SELECT MAX(CAST(SUBSTRING(Product_ID, 5) AS UNSIGNED)) as maxId FROM Product WHERE Product_ID LIKE 'PROD%'",
            (err, results) => {
                if (err) {
                    console.error("Error finding max product ID:", err);
                    // If ID gen fails, delete uploaded file if it exists
                    if (photoFile) fs.unlink(photoFile.path, (e) => e && console.error("Error deleting file after ID gen error:", e));
                    return reject(err);
                }
                let nextNumericId = (results[0]?.maxId || 0) + 1;
                const newProductId = `PROD${nextNumericId.toString().padStart(6, "0")}`;
        // --- End ID Generation ---

                const insert_sql = `
                    INSERT INTO Product (
                        Product_ID, product_name, product_category_ID, product_detail,
                        product_instock_quantity, product_sold_quantity, product_price,
                        product_rating, product_expire_date, product_photo_path
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                `;

                let expireDateFormatted = null;
                if (productData.expireDate) {
                    try {
                        const date = new Date(productData.expireDate);
                        if (!isNaN(date.getTime())) expireDateFormatted = date.toISOString().slice(0, 10);
                        else console.warn("Invalid expireDate for new product, setting NULL:", productData.expireDate);
                    } catch (e) {
                         // If date parse fails, delete uploaded file if it exists
                        if (photoFile) fs.unlink(photoFile.path, (e) => e && console.error("Error deleting file after date parse error:", e));
                        return reject(new Error("Invalid date format for expiration date."));
                    }
                }

                const params = [
                    newProductId,
                    productData.name,
                    productData.categoryId,
                    productData.detail || null, // Use null if empty/undefined
                    parseInt(productData.instockQuantity, 10) || 0,
                    0, // soldQuantity starts at 0
                    parseFloat(productData.price) || 0, // Ensure number
                    parseFloat(productData.rating) || 0, // Ensure number
                    expireDateFormatted,
                    photoPath // Use the determined photo path (relative URL)
                ];

                db.query(insert_sql, params, (err, results) => {
                    if (err) {
                        console.error("Error adding product to DB:", err);
                         // If DB insert fails, delete uploaded file if it exists
                        if (photoFile) fs.unlink(photoFile.path, (e) => e && console.error("Error deleting file after DB insert error:", e));
                        if (err.code === 'ER_DUP_ENTRY') return reject(new Error(`Product with this name or ID might already exist.`));
                        return reject(err);
                    }

                    console.log(`New product added with ID ${newProductId}.`);
                    resolve({
                        message: `New product added with ID ${newProductId}.`,
                        productId: newProductId,
                        photoPath: photoPath, // Return the path
                        results,
                    });
                });
            }
        );
    });
}

/**
 * Updates an existing product, handling new photo upload and deleting old photo.
 * @param {object} db - Database connection object.
 * @param {string} productId - The ID of the product to update.
 * @param {object} productData - Object containing updated product text data.
 * @param {object|null} newPhotoFile - Newly uploaded file object from Multer (req.file) or null.
 * @returns {Promise<object>} Promise resolving with the update result.
 */
export function updateProduct(db, productId, productData, newPhotoFile) { // Added newPhotoFile parameter
    return new Promise(async (resolve, reject) => { // Make async for await
        if (!productData || !productId) return reject(new Error("Product ID and data are required for updating"));

         // --- Basic validation (same as before) ---
        if (!productData.name || productData.name.trim() === "") return reject(new Error("Product name cannot be empty."));
        if (!productData.categoryId) return reject(new Error("Product category ID is required."));
        if (productData.instockQuantity === undefined || productData.instockQuantity < 0) return reject(new Error("In Stock quantity must be a non-negative number."));
        if (productData.price === undefined || productData.price < 0) return reject(new Error("Price must be a non-negative number."));
        if (productData.rating === undefined || productData.rating < 0) return reject(new Error("Rating must be a non-negative number."));
         // --- End Validation ---

        let oldPhotoPath = null;
        let updatePhoto = false;
        let newPhotoPathRelativeUrl = null;

        // If a new photo was uploaded, determine its path and plan to update
        if (newPhotoFile) {
            updatePhoto = true;
            // Store the relative URL path
            newPhotoPathRelativeUrl = path.join(UPLOAD_BASE_URL, newPhotoFile.filename).replace(/\\/g, '/');
            console.log(`New photo uploaded for ${productId}: ${newPhotoPathRelativeUrl}`);

            // --- Get the OLD photo path to delete it later ---
            try {
                 const [oldProduct] = await db.promise().query("SELECT product_photo_path FROM Product WHERE Product_ID = ?", [productId]);
                 if (oldProduct.length > 0 && oldProduct[0].product_photo_path) {
                     // Convert stored relative URL path to file system path
                     oldPhotoPath = path.join('.', oldProduct[0].product_photo_path); // Assumes relative path starts from project root
                     console.log(`Found old photo path for deletion: ${oldPhotoPath}`);
                 }
             } catch (fetchErr) {
                 console.error("Error fetching old photo path:", fetchErr);
                 // Decide whether to proceed without deleting old photo or reject
                 // Let's proceed but log the error. We should still delete the NEW file if update fails.
             }
            // --- End Get OLD photo path ---
        } else {
            console.log(`No new photo uploaded for ${productId}. Path will not be updated.`);
        }

        // Build the SET part of the SQL query dynamically
        const setClauses = [];
        const params = [];

        setClauses.push("product_name = ?"); params.push(productData.name);
        setClauses.push("product_category_ID = ?"); params.push(productData.categoryId);
        setClauses.push("product_detail = ?"); params.push(productData.detail || null);
        setClauses.push("product_instock_quantity = ?"); params.push(parseInt(productData.instockQuantity, 10) || 0);
        setClauses.push("product_price = ?"); params.push(parseFloat(productData.price) || 0);
        setClauses.push("product_rating = ?"); params.push(parseFloat(productData.rating) || 0);

        // Only update photo path if a new file was uploaded
        if (updatePhoto) {
            setClauses.push("product_photo_path = ?"); params.push(newPhotoPathRelativeUrl);
        }

        // Format and add expire date
        let expireDateFormatted = null;
        if (productData.expireDate) {
            try {
                const date = new Date(productData.expireDate);
                if (!isNaN(date.getTime())) expireDateFormatted = date.toISOString().slice(0, 10);
                else console.warn("Invalid expireDate on update, setting NULL:", productData.expireDate);
            } catch (e) {
                // If date parse fails, delete newly uploaded file if it exists
                if (newPhotoFile) fs.unlink(newPhotoFile.path, (e) => e && console.error("Error deleting file after date parse error:", e));
                return reject(new Error("Invalid date format for expiration date."));
            }
        }
        setClauses.push("product_expire_date = ?"); params.push(expireDateFormatted);

        // Add the WHERE clause parameter
        params.push(productId);

        const update_sql = `UPDATE Product SET ${setClauses.join(", ")} WHERE Product_ID = ?`;

        db.query(update_sql, params, (err, results) => {
            if (err) {
                console.error("Error updating product in DB:", err);
                // If DB update fails, attempt to delete the NEWLY uploaded file
                if (newPhotoFile) {
                    fs.unlink(newPhotoFile.path, (unlinkErr) => {
                        if (unlinkErr) console.error("Error deleting NEW uploaded file after DB update error:", unlinkErr);
                        else console.log("NEW uploaded file deleted after DB update error:", newPhotoFile.path);
                    });
                }
                return reject(err);
            }

            if (results.affectedRows > 0) {
                console.log(`Product with ID ${productId} updated successfully.`);
                // If update was successful AND a new photo was uploaded AND an old photo path exists...
                if (updatePhoto && oldPhotoPath) {
                    // ...delete the OLD photo file (fire and forget, or handle errors)
                    fs.unlink(oldPhotoPath, (unlinkErr) => {
                        if (unlinkErr && unlinkErr.code !== 'ENOENT') { // Ignore 'file not found' errors
                            console.error(`Error deleting OLD photo file ${oldPhotoPath}:`, unlinkErr);
                        } else if (!unlinkErr) {
                            console.log(`Successfully deleted OLD photo file: ${oldPhotoPath}`);
                        }
                    });
                }
                resolve({
                    message: `Product with ID ${productId} updated successfully.`,
                    photoPath: updatePhoto ? newPhotoPathRelativeUrl : undefined, // Return new path if updated
                    results,
                });
            } else {
                 // If product not found, delete newly uploaded file if it exists
                if (newPhotoFile) {
                     fs.unlink(newPhotoFile.path, (unlinkErr) => {
                         if (unlinkErr) console.error("Error deleting NEW uploaded file after product not found:", unlinkErr);
                         else console.log("NEW uploaded file deleted after product not found:", newPhotoFile.path);
                     });
                }
                console.log(`Product with ID ${productId} not found for update.`);
                reject(new Error(`Product with ID ${productId} not found.`));
            }
        });
    });
}

const getFrontendPublicPath = () => {
    try {
        // Adjust the path resolution based on the actual structure
        // Goes up from Controller/Admin/ to ProjectRoot, then into the FE path
        return path.resolve(__dirname, '../../../sec02_gr01_fe_src/public');
    } catch (err) {
        console.error("Error resolving frontend public path:", err);
        // Return a default or handle the error appropriately
        // Returning '.' might be unsafe, adjust as needed or throw error
        return '.';
    }
};


/**
 * Deletes a product from the database and its associated photo file.
 * @param {object} db - Database connection object.
 * @param {string} productId - The ID of the product to delete.
 * @returns {Promise<object>} Promise resolving with the deletion result.
 */
export function deleteProduct(db, productId) {
    return new Promise(async (resolve, reject) => { // Make async
        if (!productId) return reject(new Error("Product ID is required for deletion."));

        let storedPhotoPath = null; // The path stored in the DB (e.g., /img/products/...)
        let fileSystemPathToDelete = null; // The absolute filesystem path

        // 1. Get the photo path from the DB *before* deleting the record
        try {
            const [product] = await db.promise().query("SELECT product_photo_path FROM Product WHERE Product_ID = ?", [productId]);
            if (product.length > 0 && product[0].product_photo_path) {
                storedPhotoPath = product[0].product_photo_path;
                console.log(`Found photo path stored in DB: ${storedPhotoPath}`);

                // 2. Calculate the absolute filesystem path
                //    Joins the base public dir (e.g., /abs/path/to/frontend/public)
                //    with the stored relative path (e.g., /img/products/xyz.png)
                //    path.join intelligently handles leading/trailing slashes.
                const frontendPublicDir = getFrontendPublicPath();
                fileSystemPathToDelete = path.join(frontendPublicDir, storedPhotoPath);

                console.log(`Calculated filesystem path for deletion: ${fileSystemPathToDelete}`);

            } else {
                console.log(`Product ${productId} not found or has no photo path.`);
            }
        } catch (fetchErr) {
            console.error("Error fetching photo path before delete:", fetchErr);
            // Decide if you want to proceed with DB delete even if fetching path failed
            // Let's proceed, but the file won't be deleted if path wasn't retrieved.
            // return reject(new Error("Could not verify photo path before deletion."));
        }


        // 3. Delete the database record
        const delete_sql = "DELETE FROM Product WHERE Product_ID = ?";
        db.query(delete_sql, [productId], (err, results) => {
            if (err) {
                console.error(`Error deleting product ${productId} from DB:`, err);
                return reject(err); // Don't proceed to file deletion if DB fails
            }

            if (results.affectedRows > 0) {
                console.log(`Product with ID ${productId} deleted successfully from DB.`);

                // 4. If DB delete succeeded AND we have a filesystem path, delete the file
                if (fileSystemPathToDelete) {
                    fs.unlink(fileSystemPathToDelete, (unlinkErr) => { // Use the calculated filesystem path
                        if (unlinkErr && unlinkErr.code !== 'ENOENT') { // Ignore 'file not found' errors
                            console.error(`Error deleting photo file ${fileSystemPathToDelete} after DB delete:`, unlinkErr);
                            // Resolve anyway, as DB record is gone, but include warning
                            resolve({ message: `Product ${productId} deleted from DB, but failed to delete photo file.` });
                        } else if (!unlinkErr) {
                            console.log(`Successfully deleted photo file: ${fileSystemPathToDelete}`);
                            resolve({ message: `Product ${productId} and associated photo deleted successfully.` });
                        } else { // File not found (ENOENT) - presumed already deleted, resolve successfully
                            console.log(`Photo file ${fileSystemPathToDelete} not found, presumed already deleted.`);
                            resolve({ message: `Product ${productId} deleted successfully (photo file not found).` });
                        }
                    });
                } else {
                    // No photo path associated with the product, resolve successfully after DB delete
                    resolve({ message: `Product ${productId} deleted successfully (no photo associated).` });
                }
            } else {
                // Product ID wasn't found in the database
                console.log(`Product with ID ${productId} not found for deletion in DB.`);
                reject(new Error(`Product with ID ${productId} not found.`));
            }
        });
    });
}