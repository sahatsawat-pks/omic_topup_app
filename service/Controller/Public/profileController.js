// Controller/User/ProfileController.js
import fs from 'fs/promises'; // Use promises for async file operations
import path from 'path';
import bcrypt from 'bcryptjs';

// --- Calculate Paths ---
// Go up two directories from Controller/User/ to the root, then to the frontend public dir
const AVATAR_WEB_PATH_PREFIX = '/img/avatars/';

// --- Helper to delete old avatar ---
const deleteOldAvatar = async (oldPhotoPath) => {
    if (!oldPhotoPath || !oldPhotoPath.startsWith(AVATAR_WEB_PATH_PREFIX)) {
        console.log('[ProfileController] No valid old avatar path provided or path is not an avatar path.');
        return;
    }
    try {
        // Construct the absolute file system path from the web path
        const filename = path.basename(oldPhotoPath);
        const absoluteOldPath = path.join(AVATAR_STORAGE_DIR_ABSOLUTE, filename);

        await fs.unlink(absoluteOldPath);
        console.log(`[ProfileController] Successfully deleted old avatar: ${absoluteOldPath}`);
    } catch (err) {
        // Log error but don't fail the update if deletion fails (e.g., file already gone)
        if (err.code === 'ENOENT') {
            console.warn(`[ProfileController] Old avatar not found for deletion (may already be deleted): ${oldPhotoPath}`);
        } else {
            console.error(`[ProfileController] Failed to delete old avatar file (${oldPhotoPath}):`, err);
        }
    }
};

// --- Function to update user profile ---
export const updateUserProfile = async (db_connection, userId, updateData, photoFile) => {
    if (!userId) {
        throw new Error("User ID is required for profile update.");
    }

    // --- Extract ALL relevant fields from updateData ---
    const { firstName, lastName, email, dob, phoneNum } = updateData; // <<< ADD email, dob, phoneNum

    // --- Basic Input Validation (Add more as needed) ---
    if (email !== undefined && email !== null && typeof email !== 'string') { // Basic type check
         throw new Error("Invalid format for email.");
    }
    // Example using validator library (install with: npm install validator)
    // if (email && !validator.isEmail(email)) {
    //     throw new Error("Invalid email format.");
    // }
    if (dob !== undefined && dob !== null && dob !== '' && !/^\d{4}-\d{2}-\d{2}$/.test(dob)) { // Check YYYY-MM-DD format if not empty
         throw new Error("Invalid Date of Birth format. Please use YYYY-MM-DD.");
    }
    // Add phone number validation if needed

    // --- Prepare update ---
    const updateFields = [];
    const updateValues = [];
    let oldPhotoPath = null;

    // 1. Fetch current user data (photo_path and potentially email for comparison)
    try {
        const [currentUser] = await db_connection.promise().query(
            "SELECT photo_path, email FROM User WHERE User_ID = ?", // Fetch current email too
            [userId]
        );
        if (!currentUser || currentUser.length === 0) {
            throw new Error(`User with ID ${userId} not found.`);
        }
        oldPhotoPath = currentUser[0].photo_path;
        const currentEmail = currentUser[0].email;

        // Optional: Prevent updating to an email already used by *another* user
        if (email && email !== currentEmail) {
            const [existingEmailUser] = await db_connection.promise().query(
                "SELECT User_ID FROM User WHERE email = ? AND User_ID != ?",
                [email, userId]
            );
            if (existingEmailUser && existingEmailUser.length > 0) {
                throw new Error(`Email address '${email}' is already in use.`);
            }
        }

    } catch (err) {
        console.error(`[ProfileController] Error during pre-update checks for ${userId}:`, err);
        // Re-throw specific validation errors, otherwise throw generic
        if (err.message.includes('already in use')) throw err;
        throw new Error("Database error during pre-update checks.");
    }


    // 2. Add text fields to update query if provided and valid
    // Use provided value if it's defined, otherwise don't add it to the update
    if (firstName !== undefined) { // Allow empty string if user wants to clear it (if DB allows NULL)
        updateFields.push("Fname = ?");
        updateValues.push(firstName); // Send null if empty string? Depends on DB schema. Assuming send as is.
    }
    if (lastName !== undefined) {
        updateFields.push("Lname = ?");
        updateValues.push(lastName);
    }
     // <<< ADDED: Handle email update >>>
    if (email !== undefined) {
        updateFields.push("email = ?");
        updateValues.push(email);
    }
     // <<< ADDED: Handle dob update >>>
    if (dob !== undefined) { // Handle empty string, it might mean clearing the date
        updateFields.push("DoB = ?");
         // If dob is an empty string, send NULL to the database, otherwise send the YYYY-MM-DD string
        updateValues.push(dob === '' ? null : dob);
    }
     // <<< ADDED: Handle phoneNum update >>>
    if (phoneNum !== undefined) {
        updateFields.push("phone_num = ?"); // Assuming DB column name is 'phone_num'
        updateValues.push(phoneNum);
    }

    // 3. Handle new photo upload
    let newPhotoWebPath = null;
    if (photoFile) {
        newPhotoWebPath = `${AVATAR_WEB_PATH_PREFIX}${photoFile.filename}`;
        updateFields.push("photo_path = ?");
        updateValues.push(newPhotoWebPath);
        console.log(`[ProfileController] New photo path to be saved: ${newPhotoWebPath}`);
    }

    // 4. Check if there's anything to update
    if (updateFields.length === 0) {
       // No data fields and no photo file = nothing to update.
       // Frontend should ideally prevent this, but we handle it defensively.
       console.warn(`[ProfileController] Update requested for User ID ${userId} with no changes.`);
       // You might want to return the current user data instead of throwing error
       // throw new Error("No update data provided.");
       // Let's fetch and return current data if no changes were sent
        try {
             const [currentUserData] = await db_connection.promise().query(
                "SELECT u.user_id as userId, ld.username as userName, u.user_type as userType, " +
                "u.Fname as firstName, u.Lname as lastName, u.email, " +
                "DATE_FORMAT(u.DoB, '%Y-%m-%d') as dob, " + // Format DoB
                "u.phone_num as phoneNum, u.photo_path as avatar " +
                "FROM User u JOIN Login_Data ld ON u.User_ID = ld.User_ID " +
                "WHERE u.User_ID = ?",
                [userId]
            );
             if (!currentUserData || currentUserData.length === 0) {
                 throw new Error(`User ${userId} not found when checking for no changes.`);
             }
             currentUserData[0].dob = currentUserData[0].dob || ''; // Handle null dob
             currentUserData[0].phoneNum = currentUserData[0].phoneNum || ''; // Handle null phoneNum
             return { message: "No changes detected.", user: currentUserData[0] };
        } catch (fetchErr) {
             console.error(`[ProfileController] Error fetching user data when no changes were sent for ${userId}:`, fetchErr);
             throw new Error("Failed to process update request.");
        }
    }

    // 5. Construct and Execute the SQL Query
    const sql = `UPDATE User SET ${updateFields.join(', ')} WHERE User_ID = ?`;
    updateValues.push(userId);

    console.log(`[ProfileController] Executing SQL: ${sql} with values:`, updateValues);

    try {
        const [result] = await db_connection.promise().query(sql, updateValues);

        if (result.affectedRows === 0 && updateFields.length > 0) {
             // This case means the WHERE clause (User_ID) didn't match,
             // which contradicts our initial check. Should be rare.
            throw new Error(`User with ID ${userId} not found during update execution.`);
        }

        console.log(`[ProfileController] Successfully updated profile for User ID: ${userId}`);

        // 6. Delete old photo *after* successful DB update if a new one was uploaded
        if (photoFile && oldPhotoPath) {
            await deleteOldAvatar(oldPhotoPath); // Ensure deleteOldAvatar uses correct absolute path
        }

        // 7. Fetch and return the *complete* updated user data
        const [updatedUser] = await db_connection.promise().query(
            "SELECT u.user_id as userId, ld.username as userName, u.user_type as userType, " +
            "u.Fname as firstName, u.Lname as lastName, u.email, " +
            "DATE_FORMAT(u.DoB, '%Y-%m-%d') as dob, " + // <<< ADDED dob (formatted)
            "u.phone_num as phoneNum, " +                 // <<< ADDED phoneNum
            "u.photo_path as avatar " +
            "FROM User u JOIN Login_Data ld ON u.User_ID = ld.User_ID " +
            "WHERE u.User_ID = ?",
            [userId]
        );

        if (!updatedUser || updatedUser.length === 0) {
            throw new Error("Failed to fetch updated user data after update.");
        }

        // Ensure dob and phoneNum are returned as empty strings if NULL in DB
        const userToSend = updatedUser[0];
        userToSend.dob = userToSend.dob || '';
        userToSend.phoneNum = userToSend.phoneNum || '';

        console.log("[ProfileController] Returning updated user data:", userToSend);
        return { message: "Profile updated successfully.", user: userToSend };

    } catch (error) {
        console.error(`[ProfileController] Error updating profile SQL execution for User ID ${userId}:`, error);

        // If DB update failed, attempt to delete the newly uploaded file
        if (photoFile) {
            console.warn(`[ProfileController] Database update failed. Attempting delete of: ${photoFile.path}`);
            try {
                // Ensure photoFile.path is the absolute path where multer saved the file
                await fs.unlink(photoFile.path);
                console.log(`[ProfileController] Deleted uploaded file after DB error: ${photoFile.path}`);
            } catch (unlinkErr) {
                console.error(`[ProfileController] CRITICAL: Failed to delete ${photoFile.path} after DB error:`, unlinkErr);
            }
        }
        // Re-throw specific validation errors or a generic one
        if (error.message.includes('already in use') || error.message.includes('Invalid')) {
            throw error;
        }
        throw new Error("Failed to update profile due to a server error.");
    }
};

// --- *** NEW: Function to update user password *** ---
export const updateUserPassword = async (db_connection, userId, currentPassword, newPassword) => {
    if (!userId || !currentPassword || !newPassword) {
        throw new Error("User ID, current password, and new password are required.");
    }

    if (currentPassword === newPassword) {
        throw new Error("New password cannot be the same as the current password.");
    }

    // Add complexity checks for newPassword if desired
    if (newPassword.length < 6) { // Example: Minimum length
        throw new Error("New password must be at least 6 characters long.");
    }

    const saltRounds = 10; // Standard practice for bcrypt salt rounds

    try {
        // 1. Fetch current password hash from Login_Data
        const [loginData] = await db_connection.promise().query(
            "SELECT hashed_password FROM Login_Data WHERE User_ID = ?", // Match DB column name
            [userId]
        );

        if (!loginData || loginData.length === 0 || !loginData[0].hashed_password) {
            console.error(`[ProfileController] No login data or password hash found for User ID: ${userId}`);
            // Avoid exposing specific reasons for failure
            throw new Error("Password update failed. User details not found.");
        }

        const storedHash = loginData[0].hashed_password;

        // 2. Verify current password
        const isMatch = await bcrypt.compare(currentPassword, storedHash);
        if (!isMatch) {
            console.warn(`[ProfileController] Incorrect current password attempt for User ID: ${userId}`);
            throw new Error("Incorrect current password provided."); // Keep error message somewhat generic
        }

        // 3. Hash the new password
        const newHashedPassword = await bcrypt.hash(newPassword, saltRounds);

        // 4. Update the password hash in the database
        const [updateResult] = await db_connection.promise().query(
            "UPDATE Login_Data SET hashed_password = ? WHERE User_ID = ?",
            [newHashedPassword, userId]
        );

        if (updateResult.affectedRows === 0) {
             // Should not happen if the user was found earlier, but handle defensively
             console.error(`[ProfileController] Failed to update password hash for User ID: ${userId} (affectedRows = 0)`);
             throw new Error("Password update failed during database operation.");
        }

        console.log(`[ProfileController] Successfully updated password for User ID: ${userId}`);
        return { message: "Password updated successfully." };

    } catch (error) {
        console.error(`[ProfileController] Error updating password for User ID ${userId}:`, error);
        // Don't expose internal error details directly unless it's a validation error (like length)
        if (error.message.includes("Incorrect current password") || error.message.includes("length") || error.message.includes("same as the current")) {
             throw error; // Re-throw validation errors
        }
        // Otherwise, throw a generic error
        throw new Error("An error occurred while updating the password. Please try again.");
    }
};