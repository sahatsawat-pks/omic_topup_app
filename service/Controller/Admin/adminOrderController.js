
const getCurrentTimestamp = () => new Date().toISOString().slice(0, 19).replace('T', ' ');

export async function createOrder(db, orderData) {
    return new Promise(async (resolve, reject) => {
        const {
            productId,
            packageId,
            packagePrice, // Make sure this is a number if your DB expects it
            userId, // IMPORTANT: Get this securely, not from client payload directly if possible
            gameUID,
            gameServer,
            paymentMethod,
            paymentDetails, // Contains slipUrl or card info (last4)
            orderStatus = 'In Progress', // Default status
        } = orderData;

        // --- Basic Validation ---
        if (!productId || !packageId || !packagePrice || !userId || !paymentMethod) {
            return reject(new Error("Missing required order fields (productId, packageId, price, userId, paymentMethod)."));
        }
        // Add more validation as needed (e.g., check if product/package exists)

        const connection = db; // Assuming db is the connection pool or connection object

        try {
            // --- Start Transaction ---
            await connection.promise().beginTransaction();
            console.log("Transaction started for new order");

            // --- 1. Insert into Order_Record ---
            const orderId = `ORD-${uuidv4().substring(0, 8).toUpperCase()}`; // Generate a unique Order ID
            const orderRecordSql = `
                INSERT INTO Order_Record (Order_ID, User_ID, Game_UID, Game_Server, Purchase_Date, Order_status)
                VALUES (?, ?, ?, ?, ?, ?)
            `;
            const purchaseDate = getCurrentTimestamp();
            const orderRecordParams = [orderId, userId, gameUID, gameServer, purchaseDate, orderStatus];

            console.log("Executing Order_Record Insert:", orderRecordSql, orderRecordParams);
            const [orderResult] = await connection.promise().query(orderRecordSql, orderRecordParams);
            console.log("Order_Record inserted:", orderResult.affectedRows);
            if (orderResult.affectedRows !== 1) {
                throw new Error("Failed to create order record.");
            }

            // --- 2. Insert into Order_Item ---
            // Assuming one item per order for simplicity in this flow
            const orderItemSql = `
                INSERT INTO Order_Item (Order_ID, Product_ID, Package_ID, Quantity, Price_per_item, SubTotal)
                VALUES (?, ?, ?, ?, ?, ?)
            `;
             // Convert price string '฿295' to number 295
            const numericPrice = parseFloat(String(packagePrice).replace(/[^0-9.]/g, '')) || 0;
            const orderItemParams = [orderId, productId, packageId, 1, numericPrice, numericPrice]; // Assuming Quantity is 1

            console.log("Executing Order_Item Insert:", orderItemSql, orderItemParams);
            const [itemResult] = await connection.promise().query(orderItemSql, orderItemParams);
            console.log("Order_Item inserted:", itemResult.affectedRows);
             if (itemResult.affectedRows !== 1) {
                throw new Error("Failed to add order item.");
             }


            // --- 3. Insert into Payment_Record ---
             const paymentId = `PAY-${uuidv4().substring(0, 8).toUpperCase()}`;
             const paymentRecordSql = `
                 INSERT INTO Payment_Record (Payment_ID, Order_ID, Payment_Date, Payment_Method, Amount, Payment_Status, Payment_Details)
                 VALUES (?, ?, ?, ?, ?, ?, ?)
             `;
             // Use JSON stringify for details object
             const paymentDetailsString = JSON.stringify(paymentDetails || {});
             const paymentRecordParams = [paymentId, orderId, purchaseDate, paymentMethod, numericPrice, orderStatus, paymentDetailsString]; // Use order status as initial payment status

             console.log("Executing Payment_Record Insert:", paymentRecordSql, paymentRecordParams);
             const [paymentResult] = await connection.promise().query(paymentRecordSql, paymentRecordParams);
             console.log("Payment_Record inserted:", paymentResult.affectedRows);
             if (paymentResult.affectedRows !== 1) {
                 throw new Error("Failed to create payment record.");
             }

            // --- Commit Transaction ---
            await connection.promise().commit();
            console.log("Transaction committed successfully for Order ID:", orderId);

            resolve({
                message: "Order created successfully",
                orderId: orderId,
                paymentId: paymentId,
            });

        } catch (error) {
            console.error("Error during order creation transaction:", error);
            // --- Rollback Transaction ---
            await connection.promise().rollback();
            console.log("Transaction rolled back due to error.");
            reject(new Error(`Failed to create order: ${error.message}`));
        }
        // No finally block needed here unless releasing a dedicated connection
    });
}

export async function uploadPaymentSlip(req, res) {
    // This function now just handles the response after multer has done its work
    return new Promise((resolve, reject) => {
         if (!req.file) {
             console.error("Upload Error: No file received by controller.");
             return reject(new Error('No payment slip file uploaded.'));
         }

         console.log("File uploaded via Multer:", req.file);

         // Construct the accessible URL/path for the frontend
         // IMPORTANT: This depends on where multer saves the file and your static file setup
         // Example: If multer saves to 'public/uploads/slips' relative to frontend root
         const filePath = `/uploads/slips/${req.file.filename}`;

         resolve({
             message: "File uploaded successfully",
             filePath: filePath, // Send the path back to the client
             originalName: req.file.originalname,
             fileName: req.file.filename,
             size: req.file.size,
         });
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
            
            if (field === 'all') {
                query_sql += ` WHERE (Order_ID LIKE ? OR CONCAT(Fname, ' ', Lname) LIKE ? 
                          OR Game_UID LIKE ? OR Product_name LIKE ? OR Order_status LIKE ?)`;
                queryParams.push(searchTerm, searchTerm, searchTerm, searchTerm, searchTerm);
            } else {
                
                if (columnMap[field]) {
                    query_sql += ` WHERE ${columnMap[field]} LIKE ?`;
                    queryParams.push(searchTerm);
                }
            }

            // const sorting_column = columnMap[column] || "Order_ID";
            // const sorting_direction = direction.toUpperCase() === "DESC" ? "DESC" : "ASC";
            // query_sql += ` ORDER BY ${sorting_column} ${sorting_direction}`;
    query_sql += 'ORDER BY Order_ID';
        }

        db.query(query_sql, queryParams, (err, results) => {
            if(err) {
                console.error('Error querying order logs:', err);
                reject(err);
                return;
            }
                console.log('Order Log retrieved.');
            resolve(results);
        });
    });
};

export function updateOrderLogs(db, orderId, new_status) {
    return new Promise(async (resolve, reject) => {
        if (!orderId || !new_status) {
            const err = `Order ID or Status is required.`;
            return reject(new Error(err));
        }

        let update_sql = `
            UPDATE Order_Record
            SET Order_status = ?
            WHERE Order_ID = ?
        `;

        db.query(update_sql, [new_status, orderId], (err, results) => {
            if (err) {
                console.error('Error updating order logs:', err);
                reject(err);
                return;
            }
            if (results.affectedRows > 0) {
                console.log(`Order log with ID ${orderId} updated successfully.`);
                resolve({ message: `Order log with ID ${orderId} updated successfully.`, results });
            } else {
                console.log(`Order log with ID ${orderId} update failed.`);
                resolve({ message: `Order log with ID ${orderId} update failed.`, results });
            }
        });

    });
}