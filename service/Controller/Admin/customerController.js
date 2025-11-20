export function getCustomerLogs(db, searchParams = null) {
    return new Promise((resolve, reject) => {
        let query_sql = `
            SELECT 
                User_ID AS id, username, CONCAT(Fname, ' ', Lname) AS name, 
                TIMESTAMPDIFF(YEAR, DoB, CURDATE()) AS age, email, 
                membership_tier AS membership, member_point AS points 
            FROM User
            JOIN Membership USING(User_ID) 
            JOIN Login_Data USING(User_ID) 
            WHERE user_type = "Customer"
        `;
        
        const queryParams = [];
        
        // Add search filters if provided
        if (searchParams && searchParams.term) {
            const { field, term } = searchParams;
            const searchTerm = `%${term}%`;
            
            if (field === 'all') {
                query_sql += ` AND (username LIKE ? OR CONCAT(Fname, ' ', Lname) LIKE ? 
                               OR email LIKE ? OR membership_tier LIKE ?)`;
                queryParams.push(searchTerm, searchTerm, searchTerm, searchTerm);
            } else if (field === 'name') {
                query_sql += ` AND CONCAT(Fname, ' ', Lname) LIKE ?`;
                queryParams.push(searchTerm);
            } else if (field === 'username' || field === 'email' || field === 'membership') {
                const columnMap = {
                    'username': 'username',
                    'email': 'email',
                    'membership': 'membership_tier'
                };
                query_sql += ` AND ${columnMap[field]} LIKE ?`;
                queryParams.push(searchTerm);
            }
        }

        db.query(query_sql, queryParams, (err, results) => {
            if(err) {
                console.error('Error querying customer logs:', err);
                reject(err);
                return;
            }
            console.log('Customer Log retrieved.');
            resolve(results);
        });
    });
}