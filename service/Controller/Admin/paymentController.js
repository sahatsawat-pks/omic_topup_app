export function getPaymentLogs(db, searchParams = null) {
    return new Promise((resolve, reject) => {
        
        let query_sql = `
            SELECT Payment_ID AS paymentId, User_ID AS customerId, CONCAT(Fname, ' ', Lname) AS customerName, 
            Payment_method AS payment, Payment_amount AS amount,
            Purchase_Date AS paymentDate, Payment_status AS status 
            FROM Payment_Record
            JOIN Order_Record USING(Order_ID)
            JOIN User USING(User_ID)
        `;
        
        const queryParams = [];

        const columnMap = {
            paymentId: "Payment_ID",
            customerId: "User_ID",
            customerName: "CONCAT(Fname, ' ', Lname)",
            payment: "Payment_method",
            amount: "Payment_amount",
            paymentDate: "Purchase_Date",
            status: "Payment_status",
        };
        
        if (searchParams && searchParams.term) {
            const { field, term, direction, column } = searchParams;
            const searchTerm = `%${term}%`;
            
            if (field === 'all') {
                query_sql += ` WHERE (Payment_ID LIKE ? OR CONCAT(Fname, ' ', Lname) LIKE ? 
                          OR Payment_method LIKE ? OR Payment_status LIKE ?)`;
                queryParams.push(searchTerm, searchTerm, searchTerm, searchTerm);
            } else {
                
                if (columnMap[field]) {
                    query_sql += ` WHERE ${columnMap[field]} LIKE ?`;
                    queryParams.push(searchTerm);
                }
            }

            // const sorting_column = columnMap[column] || "Payment_ID";
            // const sorting_direction = direction.toUpperCase() === "DESC" ? "DESC" : "ASC";
            // query_sql += ` ORDER BY ${sorting_column} ${sorting_direction}`;
    query_sql += 'ORDER BY Payment_ID';
        }

        db.query(query_sql, queryParams, (err, results) => {
            if(err) {
                console.error('Error querying payment logs:', err);
                reject(err);
                return;
            }
            console.log('Payment Log retrieved.');
            resolve(results);
        });
    });
};

export function updatePaymentLogs(db, paymentId, new_status) {
    return new Promise(async (resolve, reject) => {
        if (!paymentId || !new_status) {
            const err = `Payment ID or Status is required.`;
            return reject(new Error(err));
        }

        let update_sql = `
            UPDATE Payment_Record
            SET Payment_status = ?
            WHERE Payment_ID = ?
        `;

        db.query(update_sql, [new_status, paymentId], (err, results) => {
            if (err) {
                console.error('Error updating payment logs:', err);
                reject(err);
                return;
            }
            if (results.affectedRows > 0) {
                console.log(`Payment log with ID ${paymentId} updated successfully.`);
                resolve({ message: `Payment log with ID ${paymentId} updated successfully.`, results });
            } else {
                console.log(`Payment log with ID ${paymentId} update failed.`);
                resolve({ message: `Payment log with ID ${paymentId} update failed.`, results });
            }
        });

    });
}