// Controller/Auth/registerController.js
import bcrypt from 'bcryptjs';

/**
 * Generates the next sequential User ID (e.g., CUS001, CUS002).
 * NOTE: This simple approach might have race conditions under high load.
 * Consider using database sequences or UUIDs for more robust generation.
 * @param {object} db - Database connection object with promise support.
 * @returns {Promise<string>} The next user ID.
 */
async function generateNewUserId(db) {
    const [rows] = await db.promise().query(
        "SELECT User_ID FROM User WHERE User_ID LIKE 'CUS%' ORDER BY CAST(SUBSTRING(User_ID, 4) AS UNSIGNED) DESC LIMIT 1"
    );

    let nextNumericId = 1;
    if (rows.length > 0) {
        const lastId = rows[0].User_ID;
        const lastNumericId = parseInt(lastId.substring(3), 10);
        if (!isNaN(lastNumericId)) {
            nextNumericId = lastNumericId + 1;
        }
    }
    // Format to CUSXXX (e.g., CUS001, CUS010, CUS100)
    return `CUS${String(nextNumericId).padStart(3, '0')}`;
}

/**
 * Validates password based on complexity rules.
 * @param {string} password
 * @returns {boolean} True if the password meets complexity requirements.
 */
function isPasswordComplex(password) {
    if (!password || password.length < 12) return false; // Minimum length 12 (Consider adjusting if frontend requirement is different)
    const hasUppercase = /[A-Z]/.test(password);
    const hasLowercase = /[a-z]/.test(password);
    const hasNumber = /[0-9]/.test(password);
    const hasSymbol = /[^a-zA-Z0-9]/.test(password);
    // Adjust complexity rule if needed to match frontend score requirement (e.g., maybe length 8 is acceptable if score > 45)
    // For now, keeping the strict server-side rule:
    return hasUppercase && hasLowercase && hasNumber && hasSymbol && password.length >= 12;
}


/**
 * Handles user registration.
 * @param {object} db - Database connection object with promise support.
 * @param {object} userData - User data from request body.
 * @param {string} userData.username
 * @param {string} userData.firstName
 * @param {string} [userData.lastName] - Optional
 * @param {string} userData.dob - Expected format 'YYYY-MM-DD'
 * @param {string} userData.email
 * @param {string} userData.phoneNumber // <-- Added
 * @param {string} userData.password
 * @returns {Promise<{success: boolean, message: string, userId?: string}>} Result object.
 */
export async function handleRegister(db, userData) {
    // --- Destructure userData, including phoneNumber ---
    const { username, firstName, lastName, dob, email, phoneNumber, password } = userData; // <-- Added phoneNumber

    // --- 1. Server-Side Validation ---
    // Added phoneNumber to the required fields check
    if (!username || !firstName || !email || !password || !dob || !phoneNumber) {
        throw new Error('Missing required fields.');
    }
    // Basic validation (can be more extensive)
    if (username.length < 3) {
        throw new Error('Username must be at least 3 characters long.');
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        throw new Error('Invalid email format.');
    }
     // Validate Phone Number (adjust regex as needed for specific formats)
    if (!/^\+?[0-9\s-()]{7,}$/.test(phoneNumber)) { // <-- Basic phone number validation
        throw new Error('Invalid phone number format.');
    }
    // Password complexity check (ensure this aligns with frontend expectations if possible)
    // The frontend checks for score >= 45, server checks for length 12 + all types.
    // You might want to relax the server rule slightly or ensure frontend enforces stricter rules.
    if (!isPasswordComplex(password)) {
        throw new Error('Password does not meet complexity requirements (min 12 chars, upper, lower, number, symbol).');
    }
    // Validate DOB format roughly (YYYY-MM-DD)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dob)) {
        throw new Error('Invalid Date of Birth format. Use YYYY-MM-DD.');
    }
    // Optional: Validate DOB is not in the future


    const connection = await db.promise(); // Use promise wrapper

    try {
        // --- 2. Check for Existing User/Email ---
        const [existingUser] = await connection.query(
            'SELECT User_ID FROM Login_Data WHERE Username = ?', // Corrected column name to User_Name
            [username]
        );
        if (existingUser.length > 0) {
            throw new Error('Username already exists.');
        }

        const [existingEmail] = await connection.query(
            'SELECT User_ID FROM User WHERE Email = ?',
            [email]
        );
        if (existingEmail.length > 0) {
            throw new Error('Email address is already registered.');
        }

        // --- 3. Hash Password ---
        const saltRounds = 12;
        const hashedPassword = await bcrypt.hash(password, saltRounds);

        // --- 4. Generate New User ID ---
        const newUserId = await generateNewUserId(db);

        // --- 5. Database Transaction ---
        await connection.beginTransaction();

        try {
            // --- Insert into User table (Updated query and parameters) ---
            const userInsertQuery = `
                INSERT INTO User (User_ID, FName, LName, Email, DOB, phone_num, User_Type, photo_path)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            `; // <-- Added placeholder for phone_num
            await connection.query(userInsertQuery, [
                newUserId,
                firstName,
                lastName || null, // Handle optional last name
                email,
                dob, // Assumes dob is 'YYYY-MM-DD' string
                phoneNumber,   // <-- Added phoneNumber value
                'Customer',    // Default user type
                null           // Default photo path
            ]);

            // --- Insert into Login_Data table ---
            const loginDataInsertQuery = `
                INSERT INTO Login_Data (User_ID, Username, hashed_password)
                VALUES (?, ?, ?)
            `; // Corrected column name to User_Name
            await connection.query(loginDataInsertQuery, [
                newUserId,
                username, // Use the provided username
                hashedPassword
            ]);

            // Commit transaction
            await connection.commit();

            console.log(`User registered successfully: ${newUserId} (${username})`);
            return {
                success: true,
                message: 'Registration successful!',
                userId: newUserId
             };

        } catch (dbError) {
            // Rollback transaction on error during inserts
            await connection.rollback();
            console.error('Database error during registration transaction:', dbError);
            // Check for specific errors if needed (e.g., constraint violations)
            throw new Error('Failed to save user data. Please try again.');
        }

    } catch (error) {
        // Log specific errors caught before or during transaction
        console.error('Registration process failed:', error.message);
        // Re-throw the original error so the route handler gets the specific message
        throw error;
    }
    // Note: No finally block needed to release connection if using a pool properly
}