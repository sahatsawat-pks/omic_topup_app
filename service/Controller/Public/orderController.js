const getCurrentTimestamp = () =>
  new Date().toISOString().slice(0, 19).replace("T", " ");

const mapPaymentMethodToEnum = (frontendMethodId) => {
  const mapping = {
    creditcard: "Credit/Debit Card",
    banktransfer: "Bank Transfer",
    promptpay: "Promptpay",
    truewallet: "True Wallet",
  };
  return mapping[frontendMethodId] || frontendMethodId; // Return mapped value or original if not found (handle error?)
};

export async function createOrder(db, orderData) {
  return new Promise(async (resolve, reject) => {
    const {
      productId,
      packageId,
      packagePrice, // Client-sent price, backend should re-verify
      userId,
      gameUID,
      gameServer,
      paymentMethod,
      paymentDetails = {},
    } = orderData;

    // --- Basic Validation ---
    if (
      !productId ||
      !packageId ||
      !packagePrice ||
      !userId ||
      !paymentMethod
    ) {
      return reject(
        new Error(
          "Missing required order fields (productId, packageId, price, userId, paymentMethod)."
        )
      );
    }

    const connection = db;
    let generatedOrderId = null; // Define variables outside try block if needed in catch/finally
    let generatedPaymentId = null;

    try {
      await connection.promise().beginTransaction();
      console.log("Transaction started for new order");

      // --- Generate Sequential Order ID --- (Keep warning about race conditions)
      const getMaxOrderIdSql = `SELECT MAX(CAST(SUBSTRING(Order_ID, 4) AS UNSIGNED)) AS maxNum FROM Order_Record WHERE Order_ID LIKE 'ORD%' FOR UPDATE`; // Added FOR UPDATE for better locking
      const [maxOrderIdResult] = await connection
        .promise()
        .query(getMaxOrderIdSql);
      const maxOrderNum = maxOrderIdResult[0]?.maxNum;
      let nextOrderNum =
        maxOrderNum === null || isNaN(maxOrderNum) ? 1 : maxOrderNum + 1;
      const paddedOrderNum = String(nextOrderNum).padStart(3, "0");
      generatedOrderId = `ORD${paddedOrderNum}`;
      console.log("Generated next Order ID:", generatedOrderId);

      // --- Generate Sequential Payment ID --- (Keep warning about race conditions)
      const getMaxPaymentIdSql = `SELECT MAX(CAST(SUBSTRING(Payment_ID, 4) AS UNSIGNED)) AS maxNum FROM Payment_Record WHERE Payment_ID LIKE 'PAY%' FOR UPDATE`; // Added FOR UPDATE
      const [maxPaymentIdResult] = await connection
        .promise()
        .query(getMaxPaymentIdSql);
      const maxPaymentNum = maxPaymentIdResult[0]?.maxNum;
      let nextPaymentNum =
        maxPaymentNum === null || isNaN(maxPaymentNum) ? 1 : maxPaymentNum + 1;
      const paddedPaymentNum = String(nextPaymentNum).padStart(3, "0");
      generatedPaymentId = `PAY${paddedPaymentNum}`;
      console.log("Generated next Payment ID:", generatedPaymentId);

      // --- Verify Price (CRITICAL - Example: Fetch from DB) ---
      // This is PSEUDOCODE - replace with your actual database query
      let verifiedPrice = 0;
      try {
        const [packageResults] = await connection.promise().query(
          "SELECT Package_Price FROM Product_Package WHERE Package_ID = ? AND Product_ID = ?", // Adjust table/column names
          [packageId, productId]
        );
        if (packageResults.length === 0) {
          throw new Error(
            `Package ID ${packageId} not found for Product ID ${productId}.`
          );
        }
        verifiedPrice = parseFloat(packageResults[0].Package_Price);
        if (isNaN(verifiedPrice)) {
          throw new Error(`Invalid price found for Package ID ${packageId}.`);
        }
        console.log(
          `Price Verified: Frontend sent ${packagePrice}, Verified DB Price: ${verifiedPrice}`
        );
        // Optional: Check if client price matches verified price within a tolerance, log discrepancies heavily.
        // if (Math.abs(parseFloat(String(packagePrice).replace(/[^0-9.]/g, '')) - verifiedPrice) > 0.01) {
        //    console.warn(`PRICE MISMATCH for Order ${generatedOrderId}: Frontend=${packagePrice}, Backend=${verifiedPrice}`);
        //    // Decide whether to reject or proceed with verified price
        // }
      } catch (priceError) {
        console.error("Error verifying package price:", priceError);
        // Reject the transaction if price verification fails critically
        throw new Error(
          `Failed to verify package price: ${priceError.message}`
        );
      }
      // Use the VERIFIED price from now on
      const numericPrice = verifiedPrice;

      // --- 1. Insert into Order_Record ---
      const orderRecordSql = `
                INSERT INTO Order_Record (Order_ID, User_ID, Game_UID, Game_Server, Purchase_Date, Order_status)
                VALUES (?, ?, ?, ?, ?, ?)
            `;
      const purchaseDate = getCurrentTimestamp();
      // Use a valid status from your Order_Record status enum/type, e.g., 'Pending' or 'Processing'
      const initialOrderStatus = "In Progress"; // Or map from frontend if needed
      const orderRecordParams = [
        generatedOrderId,
        userId,
        gameUID,
        gameServer,
        purchaseDate,
        initialOrderStatus,
      ];

      console.log(
        "Executing Order_Record Insert:",
        orderRecordSql,
        orderRecordParams
      );
      const [orderResult] = await connection
        .promise()
        .query(orderRecordSql, orderRecordParams);
      console.log("Order_Record inserted:", orderResult.affectedRows);
      if (orderResult.affectedRows !== 1) {
        throw new Error("Failed to create order record.");
      }

      // --- 2. Insert into Order_Item ---
      const quantity = 1; // Assuming quantity is always 1 based on the flow
      const orderItemSql = `
                INSERT INTO Order_Item (Order_ID, Product_ID, Package_ID, Quantity, Price_per_item, SubTotal)
                VALUES (?, ?, ?, ?, ?, ?)
            `;
      // Use the VERIFIED numericPrice
      const orderItemParams = [
        generatedOrderId,
        productId,
        packageId,
        quantity,
        numericPrice,
        numericPrice * quantity,
      ];

      console.log(
        "Executing Order_Item Insert:",
        orderItemSql,
        orderItemParams
      );
      const [itemResult] = await connection
        .promise()
        .query(orderItemSql, orderItemParams);
      console.log("Order_Item inserted:", itemResult.affectedRows);
      if (itemResult.affectedRows !== 1) {
        throw new Error("Failed to add order item.");
      }

      // --- 3. Insert into Payment_Record ---
      // **MODIFIED SQL and PARAMS**
      const paymentRecordSql = `
                INSERT INTO Payment_Record (
                    Payment_ID, Order_ID, customer_bank_account, customer_true_wallet_number,
                    customer_promptpay_number, customer_card_number, Payment_amount,
                    Payment_status, Payment_date, Payment_method,
                    Transaction_ID, Payment_Proof_Path
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `;

      // Map frontend identifier to the DB ENUM value
      const paymentMethodEnum = mapPaymentMethodToEnum(paymentMethod);
      if (!paymentMethodEnum) {
        // Handle case where mapping fails - maybe reject order or use a default?
        console.error(
          `Invalid or unmapped paymentMethod received: ${paymentMethod}`
        );
        throw new Error(`Invalid payment method: ${paymentMethod}`);
      }

      // Extract specific details using conditional logic
      const customerBankAccount =
        paymentMethod === "banktransfer" // <<< CORRECTED LOGIC
          ? paymentDetails.customerBankAccountNumber
          : null;
      const customerTrueWalletNumber =
        paymentMethod === "truewallet"
          ? paymentDetails.customerPromptpayNumber // Assuming same number field used
          : null;
      const customerPromptpayNumber =
        paymentMethod === "promptpay"
          ? paymentDetails.customerPromptpayNumber
          : null;
      // **IMPORTANT:** Ensure your DB column `customer_card_number` is intended to store ONLY the last 4 digits.
      // If it needs the full number (NOT RECOMMENDED for security unless PCI compliant),
      // you would need to send the full number from the frontend (again, not recommended).
      const customerCardNumber =
        paymentMethod === "creditcard" // Renamed for clarity if storing only last 4
          ? paymentDetails.customerCardNumber
          : null;
      // Payment proof path handling (remains null based on frontend logic)
      const paymentProofPath =
        paymentMethod === "banktransfer"
          ? paymentDetails.paymentProofPath // Will be null based on frontend code
          : null;
      // Use the DB default 'In progress' for Payment_status instead of frontend 'Pending'
      const initialPaymentStatus = "In progress"; // Matches ENUM and default

      // Use the VERIFIED numericPrice
      const paymentRecordParams = [
        generatedPaymentId,
        generatedOrderId,
        customerBankAccount, // customer_bank_account
        customerTrueWalletNumber, // customer_true_wallet_number
        customerPromptpayNumber, // customer_promptpay_number
        customerCardNumber, // customer_card_number
        numericPrice, // Payment_amount (VERIFIED price)
        initialPaymentStatus, // Payment_status ('In progress' default)
        purchaseDate, // Payment_date
        paymentMethodEnum, // Payment_method (Mapped ENUM value)
        null, // Transaction_ID (null initially)
        paymentProofPath, // Payment_Proof_Path (null if not provided/uploaded yet)
      ];

      console.log(
        "Executing Payment_Record Insert:",
        paymentRecordSql,
        paymentRecordParams
      );
      const [paymentResult] = await connection
        .promise()
        .query(paymentRecordSql, paymentRecordParams);
      console.log("Payment_Record inserted:", paymentResult.affectedRows);
      if (paymentResult.affectedRows !== 1) {
        throw new Error("Failed to create payment record.");
      }

      // --- Commit Transaction ---
      await connection.promise().commit();
      console.log(
        "Transaction committed successfully for Order ID:",
        generatedOrderId
      );

      resolve({
        message: "Order created successfully",
        orderId: generatedOrderId,
        paymentId: generatedPaymentId,
        // Maybe return QR code data or redirect URL if applicable for certain payment methods
      });
    } catch (error) {
      console.error("Error during order creation transaction:", error);

      // --- Rollback Transaction ---
      // Simplified rollback: Attempt rollback if an error occurred after beginTransaction
      // No need for complex state checks; rollback() handles it.
      try {
        // Ensure connection object exists before attempting rollback
        if (connection) {
          await connection.promise().rollback();
          console.log("Transaction rolled back due to error.");
        } else {
          console.log("Rollback skipped: Connection object was not available.");
        }
      } catch (rollbackError) {
        // Log any error that occurs *during* the rollback itself
        console.error("Error during transaction rollback:", rollbackError);
        // Still reject with the original error that caused the rollback attempt
      }

      // Reject the promise with the original error details
      if (error.code === "ER_DUP_ENTRY") {
        const field = error.message.includes(generatedOrderId)
          ? "Order ID"
          : error.message.includes(generatedPaymentId)
          ? "Payment ID"
          : "ID";
        reject(
          new Error(
            `Failed to create order: Duplicate ${field} detected. This might be due to concurrent requests. Please try again.`
          )
        );
      } else if (error.code === "ER_DATA_TOO_LONG") {
        reject(
          new Error(
            `Failed to create order: Data too long for a field. Please check input lengths. Details: ${error.message}`
          )
        );
      } else if (error.message.includes("Failed to verify package price")) {
        reject(error); // Pass specific error messages
      } else {
        reject(new Error(`Failed to create order: ${error.message}`));
      }
    }
    // **Note:** Removed the finally block as connection pool management is usually handled elsewhere.
    // If you were getting a dedicated connection from a pool, you'd release it here.
  });
}

export function getOrderLogs(db, searchParams = null) {
  return new Promise((resolve, reject) => {
    let query_sql = `
            SELECT Order_ID AS orderId, User_ID AS customerId, CONCAT(Fname, ' ', Lname) AS customerName, 
            Game_UID AS gameUid, Product_ID AS productId, Product_name AS productName, 
            Purchase_Date AS datePurchased, order_status AS status 
            FROM Order_Record
            JOIN User USING(User_ID)
            JOIN Order_Item USING(Order_ID)
            JOIN Product USING(Product_ID)
        `;

    const queryParams = [];

    const columnMap = {
      orderId: "Order_ID",
      customerId: "User_ID",
      customerName: "CONCAT(Fname, ' ', Lname)",
      gameUid: "Game_UID",
      productId: "Product_ID",
      productName: "Product_name",
      datePurchased: "Purchase_Date",
      status: "order_status",
    };

    if (searchParams && searchParams.term) {
      const { field, term, direction, column } = searchParams;
      const searchTerm = `%${term}%`;

      if (field === "all") {
        query_sql += ` WHERE (Order_ID LIKE ? OR CONCAT(Fname, ' ', Lname) LIKE ? 
                          OR Game_UID LIKE ? OR Product_name LIKE ? OR Order_status LIKE ?)`;
        queryParams.push(
          searchTerm,
          searchTerm,
          searchTerm,
          searchTerm,
          searchTerm
        );
      } else {
        if (columnMap[field]) {
          query_sql += ` WHERE ${columnMap[field]} LIKE ?`;
          queryParams.push(searchTerm);
        }
      }

      // const sorting_column = columnMap[column] || "Order_ID";
      // const sorting_direction = direction.toUpperCase() === "DESC" ? "DESC" : "ASC";
      // query_sql += ` ORDER BY ${sorting_column} ${sorting_direction}`;
      query_sql += "ORDER BY Order_ID";
    }

    db.query(query_sql, queryParams, (err, results) => {
      if (err) {
        console.error("Error querying order logs:", err);
        reject(err);
        return;
      }
      console.log("Order Log retrieved.");
      resolve(results);
    });
  });
}

/**
 * Fetches the latest Order_ID for a given User_ID.
 * @param {object} db - Database connection object.
 * @param {string} userId - The ID of the user whose latest order is needed.
 * @returns {Promise<string|null>} - Resolves with the latest Order_ID or null if no orders found.
 */
export function getLatestOrderIdForUser(db, userId) {
  return new Promise((resolve, reject) => {
    if (!userId) {
      return reject(
        new Error("User ID is required to fetch the latest order.")
      );
    }

    const query_sql = `
        SELECT Order_ID
        FROM Order_Record
        WHERE User_ID = ?
        ORDER BY Purchase_Date DESC, Order_ID DESC -- Order by date first, then ID as tie-breaker
        LIMIT 1;
      `;

    db.query(query_sql, [userId], (err, results) => {
      if (err) {
        console.error(
          `Error fetching latest order ID for user ${userId}:`,
          err
        );
        return reject(new Error("Database error fetching latest order."));
      }

      if (results.length > 0) {
        console.log(
          `Latest Order ID found for user ${userId}: ${results[0].Order_ID}`
        );
        resolve(results[0].Order_ID); // Return only the Order_ID string
      } else {
        console.log(`No orders found for user ${userId}.`);
        resolve(null); // No orders found for this user
      }
    });
  });
}

