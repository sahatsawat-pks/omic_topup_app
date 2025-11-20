// Controller/Auth/LoginController.js
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';

/**
 * Handles user login authentication using bcrypt for password verification.
 * Issues only an access token.
 * @param {object} db - Database connection object.
 * @param {string} username - The username provided by the user.
 * @param {string} password - The plain text password provided by the user.
 * @returns {Promise<object>} - Promise resolving with user data and access token, or rejecting with an error object.
 */
export function handleLogin(db, username, password) {
    return new Promise((resolve, reject) => {
        if (!username || !password) {
            // Reject with an object for consistency, including a status hint
            return reject({ status: 400, message: "Username and password are required." });
        }

        const query_sql = `
            SELECT 
                ld.User_ID, 
                ld.username,
                ld.hashed_password,
                u.user_type, 
                u.Fname, 
                u.Lname,
                u.email,
                u.phone_num,
                DATE_FORMAT(u.DoB, '%Y-%m-%d') as DoB,
                u.photo_path
            FROM Login_Data ld 
            JOIN User u ON ld.User_ID = u.User_ID 
            WHERE ld.username = ?
        `;

        db.query(query_sql, [username], async (err, results) => {
            if (err) {
                console.error("Error querying login data:", err);
                // Reject with an object, hinting at server error
                return reject({ status: 500, message: "Database error during login." });
            }

            if (results.length === 0) {
                console.log(`Login attempt failed: Username not found - ${username}`);
                // Reject with an object, standard invalid credentials message
                return reject({ status: 401, message: "Invalid username or password." });
                // NOTE: Cannot log with User_ID here as it's unknown
            }

            const user = results[0];
            console.log("User found:", user.User_ID); // Log user ID found

            const hashedPasswordFromDB = user.hashed_password;
            if (!hashedPasswordFromDB) {
                console.error(`Login failed: No hashed password found for username - ${username}`);
                // Reject with an object, hinting internal data issue
                return reject({ status: 500, message: "Authentication error: User data incomplete.", userIdForLog: user.User_ID }); // Include User_ID for logging
            }

            let isMatch = false;
            try {
                isMatch = await bcrypt.compare(password, hashedPasswordFromDB);
                console.log(`Password comparison result for ${username}: ${isMatch}`);
            } catch (compareError) {
                console.error("Error comparing password hash:", compareError);
                // Reject with an object, hinting internal server error
                return reject({ status: 500, message: "Authentication error during password check.", userIdForLog: user.User_ID }); // Include User_ID for logging
            }

            if (!isMatch) {
                console.log(`Login attempt failed: Incorrect password for username - ${username}`);
                // *** MODIFICATION: Reject with an object containing userIdForLog ***
                return reject({
                    status: 401, // Unauthorized
                    message: "Invalid username or password.",
                    userIdForLog: user.User_ID // Pass User_ID for logging purposes
                });
            }

            // --- Password is correct, proceed to JWT generation ---
            console.log(`Login successful for username: ${username}`);

            // Create Payload for Access Token
            const accessTokenPayload = {
                userId: user.User_ID,
                userName: user.username,
                userType: user.user_type,
                firstName: user.Fname,
                email: user.email,
                dob: user.DoB,
                phoneNum: user.phone_num,
                avatar: user.photo_path,
                type: 'access' // Keep type differentiation, good practice
            };

            const accessSecret = process.env.JWT_SECRET;

            if (!accessSecret) {
                console.error("JWT_SECRET environment variable is not set!");
                return reject({ status: 500, message: "Server configuration error." });
            }

            try {
                // Sign the Access Token
                const accessToken = jwt.sign(
                    accessTokenPayload,
                    accessSecret,
                    { expiresIn: process.env.JWT_EXPIRES_IN || '1h' }
                );

                // Resolve with user data (excluding password hash) and access token
                resolve({
                    accessToken,
                    user: {
                        userId: user.User_ID,
                        userName: user.username,
                        userType: user.user_type,
                        firstName: user.Fname,
                        lastName: user.Lname,
                        email: user.email,
                        dob: user.DoB,
                        phoneNum: user.phone_num,
                        avatar: user.photo_path
                    }
                });

            } catch (signError) {
                console.error("Error signing JWT:", signError);
                return reject({ status: 500, message: "Error generating session token.", userIdForLog: user.User_ID }); // Include User_ID for logging if JWT fails after auth
            }
        });
    });
}

// Optional hashPassword function remains the same
export async function hashPassword(password) {
    const saltRounds = 10;
    try {
        const salt = await bcrypt.genSalt(saltRounds);
        const hash = await bcrypt.hash(password, salt);
        return hash;
    } catch (error) {
        console.error("Error hashing password:", error);
        throw new Error("Password hashing failed.");
    }
}