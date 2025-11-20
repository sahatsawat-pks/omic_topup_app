// productController.js

/**
 * Fetches products, potentially filtered by search parameters.
 * Provides comprehensive details suitable for admin lists or general use.
 * Joins with Product_Category to get category name.
 * @param {object} db - Database connection object.
 * @param {object|null} searchParams - Optional search parameters { field, term }.
 * @returns {Promise<Array<object>>} Promise resolving with an array of product objects.
 */
export const getProduct = async (db, searchTerm = null, filters = {}) => {
  let query = `
    SELECT
        p.Product_ID AS productId,
        p.product_name AS name,
        p.product_category_ID AS categoryId,
        pc.Category_name AS categoryName,
        p.product_detail AS detail,
        p.product_instock_quantity AS instockQuantity,
        p.product_sold_quantity AS soldQuantity,
        p.product_price AS price,
        p.product_rating AS rating,
        p.product_expire_date AS expireDate,
        p.product_photo_path AS photoPath
    FROM Product p
    JOIN Product_Category pc ON p.product_category_ID = pc.Category_ID
    -- JOIN other tables if needed for filters (e.g., promotions, genres)
`;
  const queryParams = [];
  const whereClauses = [];

  // 1. Handle Simple Search Term (if provided) - across multiple fields
  if (searchTerm) {
    const searchPattern = `%${searchTerm}%`;
    // Assuming search across name and potentially details or category name
    whereClauses.push(
      `(p.product_name LIKE ? OR p.product_detail LIKE ? OR pc.Category_name LIKE ?)`
    );
    queryParams.push(searchPattern, searchPattern, searchPattern);
  }

  // 2. Handle Advanced Filters (add conditions with AND)
  if (filters.gameName) {
    whereClauses.push(`p.product_name LIKE ?`);
    queryParams.push(`%${filters.gameName}%`);
  }
  if (filters.category) {
    // Assuming filters.category is the Category_ID
    whereClauses.push(`p.product_category_ID = ?`);
    queryParams.push(filters.category);
  }
  // if (filters.genres) { // Requires Genre table/logic
  //     // Example: JOIN Product_Genre pg ON p.Product_ID = pg.Product_ID JOIN Genre g ON pg.Genre_ID = g.Genre_ID
  //     whereClauses.push(`g.genre_id = ?`); // Or g.genre_name = ?
  //     queryParams.push(filters.genres);
  // }
  if (filters.priceMin) {
    const minPrice = parseFloat(filters.priceMin);
    if (!isNaN(minPrice)) {
      whereClauses.push(`p.product_price >= ?`);
      queryParams.push(minPrice);
    }
  }
  if (filters.priceMax) {
    const maxPrice = parseFloat(filters.priceMax);
    if (!isNaN(maxPrice)) {
      whereClauses.push(`p.product_price <= ?`);
      queryParams.push(maxPrice);
    }
  }
  // if (filters.promotions) { // Requires logic - e.g., JOIN Discount or a flag on Product
  //     // Example: JOIN Product_Discount pd ON p.Product_ID = pd.Product_ID JOIN Discount d ON pd.Discount_ID = d.Discount_ID
  //     whereClauses.push(`d.discount_status = 'Active' AND d.discount_expire_date > NOW()`);
  //     // OR if you have a simple boolean flag on Product table:
  //     // whereClauses.push(`p.is_on_promotion = TRUE`);
  // }
  if (filters.available) {
    whereClauses.push(`p.product_instock_quantity > 0`);
  }

  // Combine WHERE clauses
  if (whereClauses.length > 0) {
    query += " WHERE " + whereClauses.join(" AND ");
  }

  // Add ORDER BY, LIMIT, OFFSET if needed for pagination
  query += " ORDER BY p.product_name ASC"; // Example ordering

  console.log("Executing DB Query:", query);
  console.log("Query Params:", queryParams);

  try {
    const [rows] = await db.promise().query(query, queryParams);

    // Map rows to match the frontend Product interface accurately
    return rows.map((row) => ({
      productId: row.productId,
      name: row.name,
      categoryId: row.categoryId, // Include if frontend needs it (e.g., for edits)
      categoryName: row.categoryName || null, // Handle potential null
      detail: row.detail || null, // Handle potential null
      instockQuantity:
        row.instockQuantity !== null ? Number(row.instockQuantity) : 0, // Convert to number, default 0
      soldQuantity: row.soldQuantity !== null ? Number(row.soldQuantity) : 0, // Convert to number, default 0
      price: row.price !== null ? parseFloat(row.price) : 0, // Convert to number, default 0
      rating: row.rating !== null ? parseFloat(row.rating) : 0, // Convert to number, default 0
      expireDate: row.expireDate || null, // Keep as string or null
      photoPath: row.photoPath || null, // Handle potential null path
    }));
  } catch (dbError) {
    console.error("Database error in getProduct:", dbError);
    throw new Error("Database query failed while fetching products."); // Throw a generic error
  }
};

/**
 * Fetches a single product by its Product_ID, including its associated servers.
 * Joins with Product_Category to get category name.
 * Fetches server details from Server and Product_Server tables.
 * @param {object} db - Database connection object.
 * @param {string} productId - The Product_ID to fetch.
 * @returns {Promise<object|null>} Promise resolving with the detailed product object (including availableServers array) or null if not found.
 */
export function getProductById(db, productId) {
  // --- This function remains unchanged from the previous correction ---
  // --- It correctly fetches detailed product info + server list ---
  return new Promise(async (resolve, reject) => {
    if (!productId) {
      return reject(new Error("Product ID is required."));
    }

    const product_query_sql = `
            SELECT
                p.Product_ID as productId,
                p.product_name as name,
                p.product_category_ID as categoryId,
                pc.Category_name as categoryName,
                p.product_detail as detail,
                p.product_instock_quantity as instockQuantity,
                p.product_sold_quantity as soldQuantity,
                p.product_price as price,
                p.product_rating as rating,
                p.product_expire_date as expireDate,
                p.product_photo_path as photoPath
            FROM Product p
            JOIN Product_Category pc ON p.product_category_ID = pc.Category_ID
            WHERE p.Product_ID = ?
            LIMIT 1;
        `;

    console.log(
      "Executing SQL (getProductById - Product Details):",
      product_query_sql
    );
    console.log("With Params:", [productId]);

    try {
      const [productResults] = await db
        .promise()
        .query(product_query_sql, [productId]);

      if (productResults.length === 0) {
        console.log(`Product with ID ${productId} not found.`);
        resolve(null);
        return;
      }

      let product = productResults[0];
      console.log(`Product ${productId} details retrieved successfully.`);

      // Convert price/rating back to numbers if they come as strings from DB
      product = {
        ...product,
        price: product.price !== null ? parseFloat(product.price) : null,
        rating: product.rating !== null ? parseFloat(product.rating) : null,
      };

      const server_query_sql = `
                SELECT
                    s.Server_ID as serverId,
                    s.Server_Name as serverName
                FROM Server s
                JOIN Product_Server ps ON s.Server_ID = ps.Server_ID
                WHERE ps.Product_ID = ?
                ORDER BY s.Server_Name;
            `;

      console.log(
        "Executing SQL (getProductById - Servers):",
        server_query_sql
      );
      console.log("With Params:", [productId]);

      const [serverResults] = await db
        .promise()
        .query(server_query_sql, [productId]);

      product.availableServers = serverResults; // Assign the array of server objects

      console.log(
        `Servers for product ${productId} retrieved. Count: ${serverResults.length}`
      );
      resolve(product);
    } catch (err) {
      console.error(
        `Error querying details or servers for product ID ${productId}:`,
        err
      );
      reject(new Error("Database error fetching product details or servers."));
    }
  });
}
