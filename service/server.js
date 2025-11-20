import express, { Router, json, urlencoded } from "express";
import { config } from "dotenv";
import { createConnection } from "mysql2";
import path from 'path';
import fs from 'fs';
import cors from "cors";
import jwt from "jsonwebtoken";
import { fileURLToPath } from 'url';
import multer from 'multer';

import { getCustomerLogs } from "./Controller/Admin/customerController.js";
import { getOrderLogs, updateOrderLogs } from "./Controller/Admin/adminOrderController.js";
import { getPaymentLogs, updatePaymentLogs } from "./Controller/Admin/paymentController.js";
import { getPromotions, updatePromotions, addPromotions, deletePromotions } from "./Controller/Admin/promotionController.js";
import { updateProduct, addProduct, deleteProduct } from "./Controller/Admin/adminProductController.js";
import { getProduct, getProductById } from "./Controller/Public/productController.js";
import { getAllCategories, updateCategory, addCategory, deleteCategory} from "./Controller/Admin/categoryController.js";
import { getDashboardData } from "./Controller/Admin/dashboardController.js";
import { handleLogin } from "./Controller/Auth/loginController.js";
import { createOrder, getLatestOrderIdForUser } from './Controller/Public/orderController.js';
import { getPackageById, getPackagesByProductId } from "./Controller/Public/packageController.js";
import { updateUserProfile, updateUserPassword } from './Controller/Public/profileController.js';
import { handleRegister } from "./Controller/Auth/registerController.js";

const app = express();
const router = Router();

config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FRONTEND_PUBLIC_IMG_PRODUCTS = path.resolve(__dirname, '../assets/images/products');
const AVATAR_STORAGE_DIR = path.resolve(__dirname, '../assets/images/avatars/'); // For multer destination

console.log(`[Multer Config - Avatars] Attempting to use upload directory: ${AVATAR_STORAGE_DIR}`);
console.log(`[Multer Config] Attempting to use upload directory: ${FRONTEND_PUBLIC_IMG_PRODUCTS}`);

// Ensure the target frontend directory exists (might fail due to permissions)
try {
    if (!fs.existsSync(FRONTEND_PUBLIC_IMG_PRODUCTS)) {
        fs.mkdirSync(FRONTEND_PUBLIC_IMG_PRODUCTS, { recursive: true });
        console.log(`[Multer Config] Created directory: ${FRONTEND_PUBLIC_IMG_PRODUCTS}`);
    }
} catch (err) {
    console.error(`[Multer Config] ERROR: Failed to create directory ${FRONTEND_PUBLIC_IMG_PRODUCTS}. Check permissions and path.`, err);
    // Decide if you want the server to crash or continue without upload capability
    // process.exit(1); // Example: Exit if directory can't be created/accessed
}

// Helper function to sanitize filename (basic example)
function sanitizeFilename(filename) {
  // Remove potentially problematic characters, replace spaces with underscores
  // This is a very basic example, consider a more robust library if needed.
  const name = path.parse(filename).name; // Get name without extension
  const ext = path.parse(filename).ext;   // Get extension
  const cleanedName = name.replace(/[^a-zA-Z0-9_\-\.]/g, '_').replace(/\s+/g, '_');
  return cleanedName + ext;
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Use the calculated path to the FRONTEND public directory
    cb(null, FRONTEND_PUBLIC_IMG_PRODUCTS);
  },
  filename: function (req, file, cb) {
    // Keep the unique filename generation
    const sanitized = sanitizeFilename(file.originalname);
    cb(null, sanitized); // Changed prefix slightly
  }
});

const storageAvatars = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, AVATAR_STORAGE_DIR); // Use the absolute path for avatars
  },
  filename: function (req, file, cb) {
    const sanitized = sanitizeFilename(file.originalname);
    cb(null, sanitized); // Use sanitized filename
  }
});

const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true); // Accept file
  } else {
    cb(new Error('Not an image! Please upload only images.'), false); // Reject file
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
      fileSize: 1024 * 1024 * 5 // 5MB file size limit (adjust as needed)
  }
});

const uploadAvatar = multer({
  storage: storageAvatars,
  fileFilter: fileFilter,
  limits: {
      fileSize: 1024 * 1024 * 2 // 2MB limit for avatars (adjust as needed)
  }
});

// Middleware
app.use(
  cors({
    origin: "http://localhost:3000",
    credentials: true,
  })
);

app.use("/", router);
router.use(json());
router.use(urlencoded({ extended: true }));

// Database Connection
let db_connection = createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
});

db_connection.connect((err) => {
  if (err) throw err;
  console.log(`Connect DB: ${process.env.DB_NAME}`);
});

async function logLoginAttempt(db, userId, ipAddress, userAgent, status) {
  // Ensure userId is provided, as Login_Log.User_ID is NOT NULL
  if (!userId) {
      console.warn("Skipping login log: User_ID is missing.");
      return;
  }

  const logSql = `
      INSERT INTO Login_Log 
      (User_ID, Login_Timestamp, IP_Address, Login_status, User_Agent) 
      VALUES (?, NOW(), ?, ?, ?)
  `;
  // Ensure userAgent is not excessively long if the DB field has a limit (TEXT is usually fine)
  const safeUserAgent = userAgent ? userAgent.substring(0, 1024) : null; // Example limit

  try {
      await db.promise().query(logSql, [userId, ipAddress, status, safeUserAgent]);
      console.log(`Logged login attempt for User_ID ${userId}: ${status}`);
  } catch (logError) {
      console.error(`Failed to insert login log for User_ID ${userId}:`, logError);
      // Decide if this failure should affect the user response (usually not)
  }
}

router.post("/api/auth/register", async (req, res) => {
  try {
      // Ensure required data is present in the body (basic check - added phoneNumber)
      const { username, firstName, email, password, dob, phoneNumber } = req.body; // <-- Added phoneNumber
      if (!username || !firstName || !email || !password || !dob || !phoneNumber) { // <-- Added phoneNumber
          return res.status(400).json({ message: "Missing required registration fields." });
      }

      // Call the controller function (which now expects phoneNumber)
      const result = await handleRegister(db_connection, req.body);

      // Send success response (201 Created)
      res.status(201).json(result);

  } catch (error) {
      console.error("API Register Error:", error.message);

      // Determine status code based on error message
      let statusCode = 500; // Default to Internal Server Error
      const errorMessage = error.message || "An unknown error occurred during registration.";

      if (errorMessage.includes("Missing required fields") ||
          errorMessage.includes("Invalid email format") ||
          errorMessage.includes("must be at least") || // Username length
          errorMessage.includes("Password does not meet complexity") ||
          errorMessage.includes("Invalid Date of Birth format") ||
          errorMessage.includes("Invalid phone number format")) { // <-- Added phone number format check
          statusCode = 400; // Bad Request (Validation Failed)
      } else if (errorMessage.includes("already exists") || // Username
                 errorMessage.includes("is already registered")) { // Email
          statusCode = 409; // Conflict (Username/Email exists)
      } else if (errorMessage.includes("Failed to save user data")) {
          statusCode = 500; // Specific DB Error during transaction
      }
      // Add more specific checks if needed

      res.status(statusCode).json({ message: errorMessage });
  }
});

// Authentication Routes
router.post("/api/auth/login", async (req, res) => {
  const { username, password } = req.body;
  // --- Get IP and User Agent ---
  // req.ip depends on 'trust proxy' setting if behind a reverse proxy
  const ipAddress = req.ip || req.connection?.remoteAddress || req.socket?.remoteAddress || 'Unknown IP';
  const userAgent = req.headers['user-agent'] || 'Unknown User Agent';
  // ---

  let logUserId = null; // Variable to hold User_ID for logging, even on failure
  let responseStatusCode = 500; // Default error status
  let responseMessage = "An unexpected error occurred during login."; // Default error message

  try {
      const result = await handleLogin(db_connection, username, password);
      // Login successful

      logUserId = result.user.userId; // Get User_ID for logging
      responseStatusCode = 200;
      responseMessage = "Login successful";

      // Log success *before* sending response (or can be done after, but async)
      await logLoginAttempt(db_connection, logUserId, ipAddress, userAgent, 'Success');

      // Send back user data (excluding password and token)
      res.status(responseStatusCode).json({
          message: responseMessage,
          accessToken: result.accessToken, // Send access token here
          user: result.user,
      });

  } catch (error) {
      console.error("Login API error:", error.message || error);

      // --- Determine status code and message from the error object ---
      responseStatusCode = error.status || 500; // Use status from error object if present
      responseMessage = error.message || "An error occurred during login.";
      logUserId = error.userIdForLog || null; // Get User_ID from error object if present

      // Log failure attempt *if* we have a User_ID (i.e., user was found but password/other check failed)
      if (logUserId) {
           await logLoginAttempt(db_connection, logUserId, ipAddress, userAgent, 'Failure');
      } else {
          // Optional: Log failure for unknown username (without User_ID) if desired,
          // but current logLoginAttempt skips if userId is null.
           console.log(`Login failed for username "${username}" before User_ID could be determined. Status: ${responseStatusCode}`);
      }

      // --- Send appropriate error response ---
      res.status(responseStatusCode).json({ message: responseMessage });
  }
});

router.post("/api/auth/logout", (req, res) => {
  console.log("Logout request received");
  res.status(200).json({ message: "Logout successful" });
});

// --- Authentication Middleware (Modified) ---
// General purpose middleware to check ACCESS token from header
const requireAuth = (requiredRole = null) => {
  return (req, res, next) => {
    const authHeader = req.headers.authorization;
    const token =
      authHeader && authHeader.startsWith("Bearer ")
        ? authHeader.split(" ")[1]
        : null;

    if (!token) {
      return res
        .status(401)
        .json({ message: "Authentication required. No token provided." });
    }

    try {
      // Verify ACCESS token using the standard JWT_SECRET
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Check token type (ensure it's an access token)
      if (decoded.type !== "access") {
        return res
          .status(401)
          .json({ message: "Invalid token type used for access." });
      }

      // Optional Role Check
      if (requiredRole && decoded.userType !== requiredRole) {
        return res
          .status(403)
          .json({ message: `Forbidden: ${requiredRole} access required.` });
      }

      req.user = decoded; // Attach user info (from access token) to request
      next();
    } catch (err) {
      console.error("Auth middleware error:", err.message);
      if (err.name === "TokenExpiredError") {
        // Specific status code for expired *access* token, client should attempt refresh
        return res
          .status(401)
          .json({ message: "Access token expired.", code: "TOKEN_EXPIRED" });
      }
      return res.status(401).json({ message: "Invalid access token." }); // Other JWT errors
    }
  };
};

const requireAdminAuth = requireAuth("Admin");

// GET route to fetch profile (already exists, but ensure it uses requireAuth)
router.get("/api/user/profile", async (req, res) => { // Added requireAuth() middleware
  const userId = req.user?.userId; // Get userId from token added by requireAuth

  if (!userId) {
      // This should ideally not be reached if requireAuth works correctly
      return res.status(401).json({ message: "Authentication required (User ID missing from token)." });
  }

  try {
    // Fetch user data including new fields
    const [userData] = await db_connection.promise().query(
         "SELECT u.user_id as userId, ld.username as userName, u.user_type as userType, " +
         "u.Fname as firstName, u.Lname as lastName, u.email, " +
         "DATE_FORMAT(u.DoB, '%Y-%m-%d') as dob, " + // <<< Format DoB as YYYY-MM-DD
         "u.phone_num as phoneNum, " +              // <<< Fetch phone_num, alias to phoneNumber
         "u.photo_path as avatar " +
         "FROM User u " +
         "JOIN Login_Data ld ON u.User_ID = ld.User_ID " +
         "WHERE u.User_ID = ?",
         [userId]
     );

    if (!userData || userData.length === 0) {
        return res.status(404).json({ message: "User not found" });
    }

     // Ensure dob and phoneNumber are correctly formatted or handled if null
    const user = userData[0];
    user.dob = user.dob || ''; // Send empty string if null
    user.phoneNum = user.phoneNum || ''; // Send empty string if null


    res.status(200).json({ user }); // Send the user object directly

} catch (err) {
    console.error(`Error fetching user profile for ${userId}:`, err);
    if (err.name === "TokenExpiredError") { // Check specific JWT errors if necessary
        return res.status(401).json({ message: "Access token expired.", code: "TOKEN_EXPIRED" });
    }
    return res.status(500).json({ message: "Server error fetching profile." });
}
});

// *** NEW: PUT route to update profile ***
router.put(
  "/api/user/profile",
  requireAuth(),                  // 1. Ensure user is logged in
  uploadAvatar.single('avatarFile'), // 2. Handle optional avatar upload
  async (req, res) => {
      // Multer error handling
      if (req.fileValidationError) {
          return res.status(400).json({ message: req.fileValidationError });
      }
      // --- Multer specific error for file size ---
      // Need to handle potential multer errors passed via next(err) if not caught by fileValidationError
      // This requires adding an error handling middleware or checking err in this handler
      // Example simple check (add error middleware for better structure):
      // if (err instanceof multer.MulterError) {
      //     if (err.code === 'LIMIT_FILE_SIZE') {
      //          return res.status(400).json({ message: `File too large. Max size is 2MB.` });
      //      }
      //      // Handle other multer errors if needed
      //      return res.status(400).json({ message: `File upload error: ${err.message}` });
      // }


      const userId = req.user?.userId; // Get userId from token payload
      const updateData = req.body; // Contains firstName, lastName, email, dob, phoneNumber
      const photoFile = req.file;  // File info from multer (or undefined)

      console.log("--- UPDATE PROFILE REQUEST ---");
      console.log("User ID:", userId);
      console.log("Update Data (body):", updateData);
      console.log("Photo File:", photoFile ? { filename: photoFile.filename, path: photoFile.path, size: photoFile.size } : "No file uploaded");

      if (!userId) {
          return res.status(401).json({ message: "Authentication invalid (User ID missing)." });
      }

      // Check if *any* data is sent (either body fields or a file)
      const hasBodyData = Object.keys(updateData).some(key => updateData[key] !== undefined && updateData[key] !== null && updateData[key] !== '');
      if (!hasBodyData && !photoFile) {
         return res.status(400).json({ message: "No update data or avatar file provided." });
      }

      try {
          // Pass all relevant data to the controller
          const result = await updateUserProfile(db_connection, userId, updateData, photoFile);
          res.status(200).json(result); // result = { message: "...", user: {...} }
      } catch (error) {
          console.error(`API Error updating profile for user ${userId}:`, error);
          let statusCode = 500; // Default
          // Check error messages from the controller for specific status codes
          if (error.message.includes("required") || error.message.includes("No update data") || error.message.includes("Invalid") || error.message.includes("format")) {
               statusCode = 400; // Bad Request
           } else if (error.message.includes("not found")) {
               statusCode = 404; // Not Found
           } // Add more specific checks if needed

          res.status(statusCode).json({ message: error.message || "Failed to update profile." });
      }
  }
);

router.put(
  "/api/user/password",
  requireAuth(), // Ensure user is logged in
  async (req, res) => {
      const userId = req.user?.userId;
      const { currentPassword, newPassword } = req.body; // Get passwords from JSON body

      console.log(`--- CHANGE PASSWORD REQUEST for User ID: ${userId} ---`);

      if (!userId) {
           return res.status(401).json({ message: "Authentication invalid (User ID missing)." });
      }

      // Basic validation
      if (!currentPassword || !newPassword) {
          return res.status(400).json({ message: "Current password and new password are required." });
      }

      try {
          // Call the dedicated controller function
          const result = await updateUserPassword(db_connection, userId, currentPassword, newPassword);
          res.status(200).json(result); // { message: "Password updated successfully." }

      } catch (error) {
          console.error(`API Error updating password for user ${userId}:`, error);
          let statusCode = 500; // Default
          // Check specific error messages from the controller
          if (error.message.includes("required") || error.message.includes("length") || error.message.includes("same as the current")) {
              statusCode = 400; // Bad Request (validation error)
          } else if (error.message.includes("Incorrect current password")) {
              statusCode = 401; // Unauthorized (or 400 Bad Request depending on preference)
          } else if (error.message.includes("not found")) {
               statusCode = 404; // Should be rare if requireAuth worked
          } // Add more specific checks if needed

          res.status(statusCode).json({ message: error.message || "Failed to update password." });
      }
  }
);


router.get("/api/customer-logs", async (req, res) => {
  try {
    const searchParams = req.query.term
      ? {
          field: req.query.field || "all",
          term: req.query.term,
        }
      : null;
    setTimeout(async () => {
      const logs = await getCustomerLogs(db_connection, searchParams);
      res.json(logs);
    }, 1000);
  } catch (error) {
    console.error("Failed to query customer logs: ", error);
    res.status(500).json({ error: "Failed to query customer logs" });
  }
});

router.get("/api/order-logs", async (req, res) => {
  try {
    const searchParams = req.query.term
      ? {
          field: req.query.field || "all",
          term: req.query.term,
        }
      : null;
    setTimeout(async () => {
      const logs = await getOrderLogs(db_connection, searchParams);
      res.json(logs);
    }, 1000);
  } catch (error) {
    console.error("Failed to query order logs: ", error);
    res.status(500).json({ error: "Failed to query order logs" });
  }
});

// *** NEW: GET Route to fetch the latest Order ID for the authenticated user ***
// Apply authentication middleware here!
router.get('/api/orders/latest', async (req, res) => {
  try {
    // requireAuth() should attach user info to req.user
    // const userId = req.user?.userId; // Get userId from the authenticated token payload
    const userId = "CUS001";

    if (!userId) {
      // This should ideally be caught by requireAuth, but double-check
      return res.status(401).json({ message: "Authentication required." });
    }

    console.log(`API /api/orders/latest: Fetching latest order for user ${userId}`);
    const latestOrderId = await getLatestOrderIdForUser(db_connection, userId);

    if (latestOrderId) {
      res.status(200).json({ orderId: latestOrderId });
    } else {
      // It's not an error if the user has no orders, return 404 Not Found
      res.status(404).json({ message: "No orders found for this user." });
    }

  } catch (error) {
    console.error("API Error /api/orders/latest:", error);
    // Don't expose detailed internal errors
    res.status(500).json({ message: error.message || "Failed to fetch latest order ID." });
  }
});

router.post("/api/orders", async (req, res) => {
  try {
      const clientOrderData = req.body;
      const authenticatedUserId = "CUS001"; // Get user ID from verified token

      // Basic validation of data received from client
      const {
          productId,
          packageId,
          packagePrice, // Price sent from client - backend SHOULD re-verify this!
          gameUID,       // Optional
          gameServer,    // Optional
          paymentMethod,
          // Payment specific fields sent directly from frontend:
          paymentDetails,
          // paymentGatewayToken // You might receive this from frontend if using a gateway
      } = clientOrderData;

      // --- Input Validation ---
      if (!productId || !packageId || !packagePrice || !paymentMethod) {
          // Use 400 for Bad Request due to missing essential data
          return res.status(400).json({ message: "Missing required order fields (productId, packageId, price, paymentMethod)." });
      }
      // Add more specific validation here if needed (e.g., check format of price, IDs etc.)

      // --- Construct Payment Details Object ---
      // This object will be stored as JSON in the Payment_Record table

      // --- Prepare Data for Controller ---
      // Structure the data exactly as the createOrder function expects it
      const controllerPayload = {
          productId,
          packageId,
          packagePrice,       // CRITICAL: Your createOrder function should ideally ignore this
                              // client-sent price and fetch the correct price from DB based on packageId.
          userId: authenticatedUserId, // Use the ID from the secure token
          gameUID: gameUID || null,  // Use null if empty/undefined
          gameServer: gameServer || null, // Use null if empty/undefined
          paymentMethod,
          paymentDetails,     // Pass the structured details object
          orderStatus: 'In Progress', // Set initial order status
      };

      console.log("API /api/orders: Calling createOrder with payload:", controllerPayload);

      // --- Call the Controller ---
      // createOrder handles the database transaction (insert into Order_Record, Order_Item, Payment_Record)
      const result = await createOrder(db_connection, controllerPayload);

      // --- Send Success Response ---
      // Use 201 Created status code for successful resource creation
      res.status(201).json(result); // Send back { message, orderId, paymentId }

  } catch (error) {
      console.error("API Error /api/orders:", error);

      // Determine appropriate status code based on error from controller or validation
      let statusCode = 500; // Default to Internal Server Error
      if (error.message.includes("Missing required") || error.message.includes("required for bank transfer")) {
          statusCode = 400; // Bad Request
      } else if (error.message.includes("Failed to create") || error.message.includes("Failed to add")) {
          statusCode = 500; // Internal Server Error (likely DB issue)
      }
      // Add more specific error handling if your controller throws different error types

      res.status(statusCode).json({ message: error.message || "Failed to create order." });
  }
});

router.put("/api/order-logs/:orderId", async (req, res) => {
  const orderId = req.params.orderId;
  const updateData = req.body.status;

  try {
    setTimeout(async () => {
      const result = await updateOrderLogs(db_connection, orderId, updateData);
      res.status(200).json(result);
    }, 1000);
  } catch (err) {
    console.error("Error updating order: ", err);
    res.status(500).json({ error: "Failed to update order." });
  }
});

router.get("/api/payment-logs", async (req, res) => {
  try {
    const searchParams = req.query.term
      ? {
          field: req.query.field || "all",
          term: req.query.term,
        }
      : null;
    setTimeout(async () => {
      const logs = await getPaymentLogs(db_connection, searchParams);
      res.json(logs);
    }, 1000);
  } catch (error) {
    console.error("Failed to query payment logs: ", error);
    res.status(500).json({ error: "Failed to query payment logs" });
  }
});

router.put(
  "/api/payment-logs/:paymentId",
  async (req, res) => {
    const paymentId = req.params.paymentId;
    const updateData = req.body.status;

    try {
      setTimeout(async () => {
        const result = await updatePaymentLogs(
          db_connection,
          paymentId,
          updateData
        );
        res.status(200).json(result);
      }, 1000);
    } catch (err) {
      console.error("Error updating payment: ", err);
      res.status(500).json({ error: "Failed to update payment." });
    }
  }
);

router.get("/api/promotions", async (req, res) => {
  try {
    const searchParams = req.query.term
      ? {
          field: req.query.field || "all",
          term: req.query.term,
        }
      : null;
    setTimeout(async () => {
      const logs = await getPromotions(db_connection, searchParams);
      res.json(logs);
    }, 1000);
  } catch (error) {
    console.error("Failed to query promotions: ", error);
    res.status(500).json({ error: "Failed to query promotions" });
  }
});

router.put(
  "/api/promotions/:promotionId",
  async (req, res) => {
    const promotionId = req.params.promotionId;
    const updateData = req.body;

    try {
      setTimeout(async () => {
        const result = await updatePromotions(
          db_connection,
          promotionId,
          updateData
        );
        res.status(200).json(result);
      }, 1000);
    } catch (err) {
      console.error("Error updating promotion: ", err);
      if (err.message.includes("not found")) {
        res.status(404).json({ error: "Not Found." });
      } else if (err.message.includes("Invalid")) {
        res.status(400).json({ error: "Bad Request." });
      } else {
        res.status(500).json({ error: "Failed to update promotion" });
      }
    }
  }
);

router.post("/api/promotions", async (req, res) => {
  const promotionData = req.body;

  try {
    setTimeout(async () => {
      const result = await addPromotions(db_connection, promotionData);
      res.status(200).json(result);
    }, 1000);
  } catch (err) {
    console.error("Error adding promotion: ", err);
    if (err.message.includes("already exists")) {
      res.status(409).json({ error: "Data Conflict: already exists." }); // 409 Conflict
    } else if (
      err.message.includes("Invalid") ||
      err.message.includes("must be after")
    ) {
      res.status(400).json({ error: "Bad Request." }); // 400 Bad Request
    } else {
      res.status(500).json({ error: "Failed to add promotion." });
    }
  }
});

router.delete(
  "/api/promotions/:promoId",
  async (req, res) => {
    const promotionId = req.params.promoId;

    console.log(promotionId);

    try {
      setTimeout(async () => {
        const result = await deletePromotions(db_connection, promotionId);
        res.status(200).json(result);
      }, 1000);
    } catch (err) {
      console.error("Error deleting promotion: ", err);
      if (err.message.includes("not found")) {
        res.status(404).json({ error: "Not Found." });
      } else {
        res.status(500).json({ error: "Failed to delete promotion." });
      }
    }
  }
);

router.get("/api/user/profile", async (req, res) => {
  // Require auth middleware should be applied to this route
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.startsWith("Bearer ") 
    ? authHeader.split(" ")[1] 
    : null;

  if (!token) {
    return res.status(401).json({ message: "Authentication required." });
  }

  try {
    // Verify the token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Fetch user data from the database
    const [user] = await db_connection.promise().query(
      "SELECT user_id as userId, user_name as userName, user_type as userType, " +
      "fname as firstName, lname as lastName, email " +
      "FROM User WHERE user_id = ?",
      [decoded.userId]
    );
    
    if (!user || user.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }
    
    // Return the user data (excluding sensitive information)
    res.status(200).json({ 
      user: user[0]
    });
  } catch (err) {
    console.error("Error fetching user profile:", err);
    if (err.name === "TokenExpiredError") {
      return res.status(401).json({ 
        message: "Access token expired.", 
        code: "TOKEN_EXPIRED" 
      });
    }
    return res.status(401).json({ message: "Invalid access token." });
  }
});

// GET /api/products - Fetch all products or search
router.get("/api/products", async (req, res) => {
  try {
    // Extract simple search term (if any)
    const simpleSearchTerm = req.query.term?.trim() || null;

    // Extract advanced filters
    const advancedFilters = {
      gameName: req.query.gameName?.trim() || null,
      category: req.query.category?.trim() || null,     // Expecting Category_ID
      genres: req.query.genres?.trim() || null,         // Expecting Genre ID/name
      priceMin: req.query.priceMin?.trim() || null,
      priceMax: req.query.priceMax?.trim() || null,
      promotions: req.query.promotions === 'true' || false, // Convert 'true' string to boolean
      available: req.query.available === 'true' || false,   // Convert 'true' string to boolean
    };

    console.log("API /api/products received query params:", req.query);
    console.log("API /api/products parsed filters:", { simpleSearchTerm, advancedFilters });

    // NO DELAY NEEDED for production or filtered results
    // Remove the setTimeout for fetching products directly
    // setTimeout(async () => { ... }, 500); // REMOVE THIS DELAY WRAPPER

    // Call the controller function, passing both simple term and advanced filters
    // *** IMPORTANT: Assumes getProduct is updated to handle these parameters ***
    const products = await getProduct(db_connection, simpleSearchTerm, advancedFilters);
    res.json(products);

  } catch (error) {
    // Catch errors from the controller or parameter processing
    console.error("API Error /api/products: ", error);
    res.status(500).json({
        error: "Failed to query products",
        message: error.message || "An internal server error occurred."
    });
  }
});


// *** NEW: GET /api/products/:productId - Fetch a single product by ID ***
router.get("/api/products/:productId", async (req, res) => {
  const { productId } = req.params;
  try {
      // No artificial delay needed for fetching a single item
      const product = await getProductById(db_connection, productId);

      if (!product) {
          // If controller returns null, it means product not found
          return res.status(404).json({ message: `Product with ID ${productId} not found.` });
      }

      // Product found, send it back
      res.status(200).json(product);

  } catch (error) {
      // Catch errors from the controller (e.g., database errors, missing ID)
      console.error(`API Error fetching product ${productId}: `, error);
      // Avoid sending detailed DB errors to the client
      if (error.message.includes("required")) {
           res.status(400).json({ message: error.message }); // Bad request if ID missing internally
      } else {
           res.status(500).json({ message: "Failed to query product details." });
      }
  }
});

// POST /api/products - Add a new product
router.post("/api/products", upload.single('photoFile'), async (req, res) => {
  // Multer error handling (optional but recommended)
  if (req.fileValidationError) {
    return res.status(400).json({ message: req.fileValidationError });
}

  const productData = req.body;
  const photoFile = req.file;

  try {
    const result = await addProduct(db_connection, productData, photoFile);
    res.status(201).json(result); // 201 Created
  } catch (err) {
    console.error("Error adding product: ", err);
    if (photoFile) {
      fs.unlink(photoFile.path, (unlinkErr) => {
        if (unlinkErr) console.error("Error deleting uploaded file after DB error:", unlinkErr);
        else console.log("Uploaded file deleted after DB error:", photoFile.path);
      });
    }
    let statusCode = 500;
    if (err.message.includes("already exists")) statusCode = 409; // Conflict
    else if (
      err.message.includes("required") ||
      err.message.includes("Invalid")
    )
      statusCode = 400; // Bad Request
    res
      .status(statusCode)
      .json({ error: "Failed to add product.", message: err.message });
  }
});

// PUT /api/products/:productId - Update an existing product
router.put("/api/products/:productId", upload.single('photoFile'), async (req, res) => {
  const productId = req.params.productId;
  const productData = req.body;
  const photoFile = req.file;

   // Multer error handling
   if (req.fileValidationError) {
    return res.status(400).json({ message: req.fileValidationError });
}

  try {
    const result = await updateProduct(db_connection, productId, productData, photoFile);
    res.status(200).json(result);
  } catch (err) {
    console.error("Error updating product: ", err);
    if (photoFile) {
      fs.unlink(photoFile.path, (unlinkErr) => {
        if (unlinkErr) console.error("Error deleting NEW uploaded file after DB error:", unlinkErr);
        else console.log("NEW uploaded file deleted after DB error:", photoFile.path);
      });
    }
    
    let statusCode = 500;
    if (err.message.includes("not found")) statusCode = 404;
    else if (
      err.message.includes("required") ||
      err.message.includes("Invalid")
    )
      statusCode = 400;
    res
      .status(statusCode)
      .json({ error: "Failed to update product", message: err.message });
  }
});

// DELETE /api/products/:productId - Delete a product
router.delete(
  "/api/products/:productId",
  async (req, res) => {
    const productId = req.params.productId;
    try {
      const result = await deleteProduct(db_connection, productId);
      res.status(200).json(result); // Or 204 No Content
    } catch (err) {
      console.error("Error deleting product: ", err);
      const statusCode = err.message.includes("not found") ? 404 : 500;
      res
        .status(statusCode)
        .json({ error: "Failed to delete product.", message: err.message });
    }
  }
);

// GET /api/categories
router.get("/api/categories", async (req, res) => {
  try {
    const categories = await getAllCategories(db_connection);
    res.json(categories);
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error fetching categories", error: error.message });
  }
});

// POST /api/categories
router.post("/api/categories", async (req, res) => {
  try {
    const newCategoryData = req.body;
    const result = await addCategory(db_connection, newCategoryData);
    // Send back the newly created category object (including ID)
    res.status(201).json(result);
  } catch (error) {
    // Send specific status codes based on error type
    if (
      error.message.includes("required") ||
      error.message.includes("already exist")
    ) {
      res
        .status(400)
        .json({ message: "Failed to add category", error: error.message });
    } else if (error.message.includes("generate")) {
      res
        .status(500)
        .json({
          message: "Failed to add category",
          error: "Internal ID generation error.",
        });
    } else {
      res
        .status(500)
        .json({ message: "Failed to add category", error: error.message });
    }
  }
});

// PUT /api/categories/:id
router.put("/api/categories/:id", async (req, res) => {
  try {
    const categoryId = req.params.id;
    const categoryData = req.body; // Expects { categoryName: "..." }
    const result = await updateCategory(
      db_connection,
      categoryId,
      categoryData
    );
    res.json(result); // Send back updated category info
  } catch (error) {
    if (error.message.includes("not found")) {
      res.status(404).json({ message: "Update failed", error: error.message });
    } else if (
      error.message.includes("required") ||
      error.message.includes("already exist")
    ) {
      res.status(400).json({ message: "Update failed", error: error.message });
    } else {
      res.status(500).json({ message: "Update failed", error: error.message });
    }
  }
});

// DELETE /api/categories/:id
router.delete("/api/categories/:id", async (req, res) => {
  try {
    const categoryId = req.params.id;
    const result = await deleteCategory(db_connection, categoryId);
    res.json(result); // { message: "..." }
  } catch (error) {
    if (error.message.includes("not found")) {
      res
        .status(404)
        .json({ message: "Deletion failed", error: error.message });
    } else if (error.message.includes("assigned to one or more products")) {
      // Conflict error because it's in use
      res
        .status(409)
        .json({ message: "Deletion failed", error: error.message });
    } else {
      res
        .status(500)
        .json({ message: "Deletion failed", error: error.message });
    }
  }
});

// GET /api/dashboard-data - Fetch all data for the main dashboard
router.get("/api/dashboard-data", async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    console.log("API /api/dashboard-data received range:", {
      startDate,
      endDate,
    });
    const dashboardData = await getDashboardData(
      db_connection,
      startDate ? String(startDate) : undefined,
      endDate ? String(endDate) : undefined
    );
    res.json(dashboardData);
  } catch (error) {
    console.error("API Error fetching dashboard data: ", error);
    res
      .status(500)
      .json({ message: error.message || "Failed to query dashboard data" });
  }
});

// *** NEW: Route for creating an order ***
// Note: Add authentication middleware (requireAuth()) here
router.post("/api/orders", async (req, res) => {
 try {
     const orderData = req.body;
      // ** SECURITY NOTE: Add logged-in user ID from session/token, not from req.body **
      // Example if using JWT middleware that adds req.user:
      // if (!req.user || !req.user.userId) {
      //     return res.status(401).json({ message: "Authentication required to place order." });
      // }
      // orderData.userId = req.user.userId;
      orderData.userId = "TEMP_USER_ID_123"; // <-- REPLACE with actual logged-in user ID

     const result = await createOrder(db_connection, orderData);
     res.status(201).json(result); // 201 Created
 } catch (error) {
     console.error("API Error creating order:", error);
     // Determine appropriate status code based on error type
     let statusCode = 500;
     if (error.message.includes("Missing required")) {
         statusCode = 400; // Bad Request
     } else if (error.message.includes("Failed to create") || error.message.includes("Failed to add")) {
          statusCode = 500; // Internal Server Error (database issue)
     }
     // Add more specific error handling (e.g., 404 if product not found)
     res.status(statusCode).json({ message: error.message || "Failed to create order." });
 }
});

// GET /api/products/:productId/packages - Fetch all packages for a specific product (Public or requires basic auth)
router.get('/api/products/:productId/packages', async (req, res) => {
  const { productId } = req.params;
  try {
      const packages = await getPackagesByProductId(db_connection, productId);
      // No packages found is not an error, just an empty array
      res.status(200).json(packages);
  } catch (error) {
      console.error(`API Error fetching packages for product ${productId}: `, error);
      // Differentiate between client error (bad ID format?) and server error
      if (error.message.includes("required")) {
           res.status(400).json({ message: error.message });
      } else {
           res.status(500).json({ message: "Failed to query product packages." });
      }
  }
});

// GET /api/packages/:packageId - Fetch a single package by its ID (Public or requires basic auth)
router.get('/api/packages/:packageId', async (req, res) => {
  const { packageId } = req.params;
  try {
      const pkg = await getPackageById(db_connection, packageId);
      if (!pkg) {
          return res.status(404).json({ message: `Package with ID ${packageId} not found.` });
      }
      res.status(200).json(pkg);
  } catch (error) {
      console.error(`API Error fetching package ${packageId}: `, error);
       if (error.message.includes("required")) {
           res.status(400).json({ message: error.message });
      } else {
          res.status(500).json({ message: "Failed to query package details." });
      }
  }
});

app.listen(process.env.PORT, () => {
  console.log(`Server listening on port ${process.env.PORT}`);
});
