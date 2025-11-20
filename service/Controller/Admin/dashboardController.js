import { format } from 'date-fns'; // For formatting date labels if needed

// Helper to format ISO string or Date object to 'YYYY-MM-DD HH:MM:SS' for SQL
const formatSqlDateTime = (dateInput) => {
    if (!dateInput) return null;
    try {
        const date = typeof dateInput === 'string' ? new Date(dateInput) : dateInput;
        // Ensure valid date object before formatting
        if (isNaN(date.getTime())) return null;
        return date.toISOString().slice(0, 19).replace('T', ' ');
    } catch (e) {
        console.error("Error formatting date for SQL:", dateInput, e);
        return null;
    }
};

// Helper function to map DB Order Status to Frontend Status
const mapOrderStatus = (dbStatus) => {
    switch (dbStatus) {
        case 'In progress': return 'Processing';
        case 'Success': return 'Success';
        case 'Cancel': return 'Failed';
        default: return 'Processing';
    }
};

// Helper function to get initials from name
const getInitials = (fname = '', lname = '') => {
    const firstInitial = fname ? fname[0] : '';
    const lastInitial = lname ? lname[0] : '';
    return `${firstInitial}${lastInitial}`.toUpperCase() || '??';
};


// --- Fetch Functions ---

// 1. Fetch Stats for the selected period
async function fetchStats(db, startDateISO, endDateISO) {
    try {
        const startDate = formatSqlDateTime(startDateISO);
        const endDate = formatSqlDateTime(endDateISO);

        // Base WHERE clauses for date filtering
        const revenueWhereClauses = ["Payment_status = 'Success'"];
        const ordersWhereClauses = ["order_status = 'Success'"];
        const params = [];

        if (startDate) {
            revenueWhereClauses.push("Payment_date >= ?");
            ordersWhereClauses.push("Purchase_Date >= ?");
            params.push(startDate);
        }
        if (endDate) {
            revenueWhereClauses.push("Payment_date <= ?");
            ordersWhereClauses.push("Purchase_Date <= ?");
            params.push(endDate);
        }

        const revenueWhereSql = revenueWhereClauses.length > 1 ? `WHERE ${revenueWhereClauses.join(' AND ')}` : `WHERE ${revenueWhereClauses[0]}`;
        const ordersWhereSql = ordersWhereClauses.length > 1 ? `WHERE ${ordersWhereClauses.join(' AND ')}` : `WHERE ${ordersWhereClauses[0]}`;

        const revenueParams = params.slice();
        const ordersParams = params.slice();

        // Total Revenue for the period
        const totalRevenueQuery = `SELECT SUM(Payment_amount) AS totalRevenue FROM Payment_Record ${revenueWhereSql}`;
        const [totalRevenueResult] = await db.promise().query(totalRevenueQuery, revenueParams);
        const periodTotalRevenue = totalRevenueResult[0]?.totalRevenue || 0;

        // Total Sales Count for the period
        const totalSalesQuery = `SELECT COUNT(Order_ID) AS salesCount FROM Order_Record ${ordersWhereSql}`;
        const [totalSalesResult] = await db.promise().query(totalSalesQuery, ordersParams);
        const periodSalesCount = totalSalesResult[0]?.salesCount || 0;

        // Calculate previous period
        // If we have startDate and endDate, we can calculate the date range span
        // and use it to determine the previous period of equal length
        let revenueGrowth = 0;
        let salesGrowth = 0;
        
        if (startDate && endDate) {
            const currentStart = new Date(startDateISO);
            const currentEnd = new Date(endDateISO);
            
            // Calculate the duration of the current period in milliseconds
            const periodDuration = currentEnd.getTime() - currentStart.getTime();
            
            // Calculate the previous period dates
            const previousEnd = new Date(currentStart.getTime() - 1); // 1ms before current start
            const previousStart = new Date(previousEnd.getTime() - periodDuration);
            
            // Format dates for SQL
            const prevStartDate = formatSqlDateTime(previousStart);
            const prevEndDate = formatSqlDateTime(previousEnd);
            
            // Fetch previous period revenue
            const prevRevenueQuery = `SELECT SUM(Payment_amount) AS totalRevenue FROM Payment_Record 
                                     WHERE Payment_status = 'Success' 
                                     AND Payment_date >= ? AND Payment_date <= ?`;
            const [prevRevenueResult] = await db.promise().query(prevRevenueQuery, [prevStartDate, prevEndDate]);
            const prevPeriodRevenue = prevRevenueResult[0]?.totalRevenue || 0;
            
            // Fetch previous period sales count
            const prevSalesQuery = `SELECT COUNT(Order_ID) AS salesCount FROM Order_Record 
                                   WHERE order_status = 'Success' 
                                   AND Purchase_Date >= ? AND Purchase_Date <= ?`;
            const [prevSalesResult] = await db.promise().query(prevSalesQuery, [prevStartDate, prevEndDate]);
            const prevPeriodSales = prevSalesResult[0]?.salesCount || 0;
            
            // Calculate growth percentages
            // Handle cases where previous period values are 0
            if (prevPeriodRevenue > 0) {
                revenueGrowth = ((periodTotalRevenue - prevPeriodRevenue) / prevPeriodRevenue) * 100;
            } else if (periodTotalRevenue > 0) {
                // If previous is 0 and current is positive, show 100% growth
                revenueGrowth = 100;
            } else {
                // Both periods have 0 revenue
                revenueGrowth = 0;
            }
            
            if (prevPeriodSales > 0) {
                salesGrowth = ((periodSalesCount - prevPeriodSales) / prevPeriodSales) * 100;
            } else if (periodSalesCount > 0) {
                // If previous is 0 and current is positive, show 100% growth
                salesGrowth = 100;
            } else {
                // Both periods have 0 sales
                salesGrowth = 0;
            }
        }

        return {
            totalRevenue: parseFloat(periodTotalRevenue),
            revenueGrowth: parseFloat(revenueGrowth.toFixed(1)),
            salesCount: parseInt(periodSalesCount, 10),
            salesGrowth: parseFloat(salesGrowth.toFixed(1)),
        };

    } catch (error) {
        console.error("Error fetching stats data for period:", error);
        return { totalRevenue: 0, revenueGrowth: 0, salesCount: 0, salesGrowth: 0 };
    }
}

// In Controller/Admin/dashboardController.js

// 2. Fetch Revenue Chart data for the selected period
async function fetchRevenueChart(db, startDateISO, endDateISO) {
    try {
        const startDate = formatSqlDateTime(startDateISO);
        const endDate = formatSqlDateTime(endDateISO);

        if (!startDate || !endDate) {
            console.log("Revenue Chart: Start or end date missing or invalid.");
            return [];
        }

        // SQL Query remains the same
        const query = `
            SELECT
                DATE(Payment_date) AS interval_start, /* SQL DATE type */
                SUM(Payment_amount) AS revenue
            FROM Payment_Record
            WHERE
                Payment_status = 'Success'
                AND Payment_date >= ?
                AND Payment_date <= ?
                AND Payment_date IS NOT NULL
            GROUP BY interval_start
            HAVING interval_start IS NOT NULL
            ORDER BY interval_start;
        `;
        const [results] = await db.promise().query(query, [startDate, endDate]);

        // --- CORRECTED MAPPING ---
        return results.map((r) => {
            let formattedDateLabel = 'Invalid Date'; // Default label

            // Check if interval_start is likely a valid Date object from the driver
            if (r.interval_start instanceof Date && !isNaN(r.interval_start.getTime())) {
                try {
                    // *** Pass the Date object directly to format ***
                    formattedDateLabel = format(r.interval_start, 'MMM d');
                } catch (formatError) {
                    console.error(`Error formatting date object from DB:`, r.interval_start, formatError);
                    // Keep 'Invalid Date' label
                }
            }
             // Optional Fallback: Check if it's a 'YYYY-MM-DD' string (less likely now)
             else if (typeof r.interval_start === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(r.interval_start)) {
                 const dateObj = new Date(r.interval_start + 'T00:00:00Z'); // Try UTC parsing
                 if (!isNaN(dateObj.getTime())) {
                    try {
                       formattedDateLabel = format(dateObj, 'MMM d');
                    } catch (formatError) {
                         console.error(`Error formatting parsed date string '${r.interval_start}':`, formatError);
                    }
                 } else {
                      console.warn(`Could not parse date string '${r.interval_start}' as date.`);
                 }
            }
            else {
                // Log if it's neither a valid Date object nor the expected string format
                console.warn(`Received unexpected or invalid type/value for interval_start:`, r.interval_start);
            }

            return {
                month: formattedDateLabel, // Use the potentially corrected label
                revenue: parseFloat(r.revenue || 0)
            };
        });
        // --- END CORRECTED MAPPING ---

    } catch (error) {
        console.error("Error fetching revenue chart data for period:", error);
        return [];
    }
}

// 3. Fetch Recent Orders for the selected period
async function fetchRecentOrders(db, startDateISO, endDateISO, limit = 8) {
    try {
        const startDate = formatSqlDateTime(startDateISO);
        const endDate = formatSqlDateTime(endDateISO);

        const baseQuery = `
            SELECT
                o.Order_ID AS id,
                CONCAT(u.Fname, ' ', u.Lname) AS customerName,
                u.photo_path AS customerAvatarBlob, -- Still need to handle BLOB vs URL
                p.product_name AS product,
                py.Payment_amount AS amount,
                o.order_status AS status,
                o.Purchase_Date AS orderDate
            FROM Order_Record o
            JOIN User u ON o.User_ID = u.User_ID
            JOIN Order_Item od ON o.order_ID = od.order_ID 
            JOIN Product p ON od.Product_ID = p.Product_ID
            LEFT JOIN Payment_Record py ON o.Order_ID = py.Order_ID
        `;
        const whereClauses = [];
        const params = [];

        if (startDate) {
            whereClauses.push("o.Purchase_Date >= ?");
            params.push(startDate);
        }
        if (endDate) {
            whereClauses.push("o.Purchase_Date <= ?");
            params.push(endDate);
        }

        const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';
        const query = `${baseQuery} ${whereSql} ORDER BY o.Purchase_Date DESC LIMIT ?`;
        params.push(limit);

        const [orders] = await db.promise().query(query, params);

        // Map results
        return orders.map(order => ({
            id: order.id,
            customerName: order.customerName,
            // Placeholder mapping for avatar - adjust as needed
            customerAvatar: `/avatars/${getInitials(order.customerName)}.png`,
            product: order.product,
            amount: order.amount ? parseFloat(order.amount) : 0,
            status: mapOrderStatus(order.status),
            orderDate: order.orderDate, // Keep as is (should be DATETIME from DB)
        }));
    } catch (error) {
        console.error("Error fetching recent orders for period:", error);
        throw new Error("Failed to fetch recent orders.");
    }
}

// 4. Fetch Popular Products for the selected period
async function fetchPopularProducts(db, startDateISO, endDateISO, limit = 5) {
    try {
        const startDate = formatSqlDateTime(startDateISO);
        const endDate = formatSqlDateTime(endDateISO);

        const querySelect = `
            SELECT
                pr.Product_ID AS id,
                pr.product_name AS name,
                pc.Category_name AS category,
                SUM(py.Payment_amount) AS earnings,
                pr.product_photo_path AS imageUrl -- Still need to handle BLOB vs URL
            FROM Product pr
            JOIN Product_Category pc ON pr.product_category_ID = pc.Category_ID
            JOIN Order_Item od ON pr.Product_ID = od.Product_ID
            JOIN Order_Record o ON od.Order_ID = o.Order_ID
            JOIN Payment_Record py ON o.Order_ID = py.Order_ID
        `;
        const whereClauses = ["py.Payment_status = 'Success'"];
        const params = [];

        if (startDate) {
            whereClauses.push("py.Payment_date >= ?");
            params.push(startDate);
        }
        if (endDate) {
            whereClauses.push("py.Payment_date <= ?");
            params.push(endDate);
        }

        const whereSql = `WHERE ${whereClauses.join(' AND ')}`;
        const queryGroupBy = `GROUP BY pr.Product_ID, pr.product_name, pc.Category_name, pr.product_photo_path`;
        const queryOrderBy = `ORDER BY earnings DESC`;
        const queryLimit = `LIMIT ?`;
        params.push(limit);

        const query = `${querySelect} ${whereSql} ${queryGroupBy} ${queryOrderBy} ${queryLimit}`;

        const [products] = await db.promise().query(query, params);

        // Map results
        return products.map(product => ({
            id: product.id, // Keep as string from DB
            name: product.name,
            category: product.category,
            earnings: parseFloat(product.earnings || 0),
             // Placeholder mapping for image - adjust as needed
            imageUrl: `/products/${product.id}.png`,
        }));
    } catch (error) {
        console.error("Error fetching popular products for period:", error);
        throw new Error("Failed to fetch popular products.");
    }
}


// --- Main Controller Function (Accepts dates) ---
export const getDashboardData = async (db, startDateISO, endDateISO) => { // Accept ISO strings
    try {
        // Dates are passed down directly to fetch functions which will handle formatting/null checks
        console.log("Controller received date range (ISO):", { startDateISO, endDateISO });

        const [statsData, revenueData, recentOrders, popularGames] = await Promise.all([
            fetchStats(db, startDateISO, endDateISO),
            fetchRevenueChart(db, startDateISO, endDateISO),
            fetchRecentOrders(db, startDateISO, endDateISO, 8), // Fetch 8 recent orders within range
            fetchPopularProducts(db, startDateISO, endDateISO, 5) // Fetch 5 popular products within range
        ]);

        return {
            statsData,
            revenueData,
            recentOrders,
            popularGames,
        };
    } catch (error) {
        console.error("Error aggregating dashboard data:", error);
        // Ensure the error message is propagated
        throw new Error(error.message || `Failed to load dashboard data`);
    }
};