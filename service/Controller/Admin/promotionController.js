function expirePromotions(db) {
  return new Promise((resolve, reject) => {
    const now = new Date(); // Use server's current time, ensure server timezone is appropriate or use UTC
    const expire_sql = `
        UPDATE discount 
        SET discount_status = 'Expired' 
        WHERE discount_status = 'Active' AND discount_expire_date < ?`; // Use correct columns/values

    db.query(expire_sql, [now], (err, results) => {
      if (err) {
        console.error("Error auto-expiring promotions:", err);
        reject(err);
      } else {
        if (results.affectedRows > 0) {
          console.log(`Auto-expired ${results.affectedRows} promotions.`);
        }
      }
      resolve();
    });
  });
}

export async function getPromotions(db, searchParams = null) {
  try {
    await expirePromotions(db);
  } catch (err) {
    console.error("Failed during promotion expiration check:", err);
  }

  return new Promise((resolve, reject) => {
    let query_sql = `
            SELECT Discount_ID as promoId, discount_code as code, discount_value as value, discount_value as maxUses, discount_status as status,
		    discount_type as type, discount_effective_date as effectiveFrom, discount_expire_date as effectiveUntil
            FROM discount
        `;

    const queryParams = [];

    const columnMap = {
      promoId: "Discount_ID",
      code: "discount_code",
      type: "discount_type",
      value: "discount_value",
      status: "discount_status",
      maxUses: "discount_value",
      effectiveFrom: "discount_effective_date",
      effectiveUntil: "discount_expire_date",
    };

    if (searchParams && searchParams.term) {
      const { field, term, direction, column } = searchParams;
      const searchTerm = `%${term}%`;

      if (field === "all") {
        query_sql += ` WHERE (discount_code LIKE ? OR discount_type LIKE ? 
                          OR discount_value LIKE ? OR discount_status LIKE ?)`;
        queryParams.push(searchTerm, searchTerm, searchTerm, searchTerm);
      } else {
        if (columnMap[field]) {
          query_sql += ` WHERE ${columnMap[field]} LIKE ?`;
          queryParams.push(searchTerm);
        }
      }

      //   const sorting_column = columnMap[column] || "Discount_ID";
      //   const sorting_direction =
      //     direction.toUpperCase() === "DESC" ? "DESC" : "ASC";
      //   query_sql += ` ORDER BY ${sorting_column} ${sorting_direction}`;
      query_sql += "ORDER BY Discount_ID";
    }

    db.query(query_sql, queryParams, (err, results) => {
      if (err) {
        console.error("Error querying promotions:", err);
        reject(err);
        return;
      }
      console.log("Promotions retrieved.");
      resolve(results);
    });
  });
}

export function updatePromotions(db, promotionId, promotionData) {
  return new Promise((resolve, reject) => {
    if (!promotionData || !promotionId) {
      return reject(
        new Error("Promotion ID and data is required for updating")
      );
    }

    // Convert percentage values from e.g. "25%" to "0.25" format for storage
    let value = promotionData.value;
    let type = "";

    const effectiveFromDate = new Date(promotionData.effectiveFrom);
    const effectiveFrom = effectiveFromDate
      .toISOString()
      .slice(0, 19)
      .replace("T", " ");

    const effectiveUntilDate = new Date(promotionData.effectiveUntil);
    const effectiveUntil = effectiveUntilDate
      .toISOString()
      .slice(0, 19)
      .replace("T", " ");

    if (typeof value === "string" && value.includes("%")) {
      // If value is a percentage string (e.g. "25%"), convert to decimal
      value = (parseFloat(value) / 100).toString();
      type = "Percentage";
    } else {
      type = "Fixed";
    }

    const update_sql = `
        UPDATE discount
        SET 
          discount_code = ?,
          discount_type = ?,
          discount_value = ?,
          discount_status = ?,
          discount_value = ?,
          discount_effective_date = ?,
          discount_expire_date = ?
        WHERE Discount_ID = ?
      `;

    const params = [
      promotionData.code,
      type,
      value,
      promotionData.status,
      promotionData.maxUses,
      effectiveFrom,
      effectiveUntil,
      promotionId,
    ];

    db.query(update_sql, params, (err, results) => {
      if (err) {
        console.error("Error updating promotion:", err);
        reject(err);
        return;
      }

      if (results.affectedRows > 0) {
        console.log(`Promotion with ID ${promotionId} updated successfully.`);
        resolve({
          message: `Promotion with ID ${promotionId} updated successfully.`,
          results,
        });
      } else {
        console.log(
          `Promotion with ID ${promotionId} not found or no changes made.`
        );
        resolve({
          message: `Promotion with ID ${promotionId} not found or no changes made.`,
          results,
        });
      }
    });
  });
}

export function addPromotions(db, promotionData) {
  return new Promise((resolve, reject) => {
    if (!promotionData || !promotionData.code) {
      return reject(
        new Error("Promotion code is required for adding new promotion")
      );
    }

    // Find the highest existing discount_ID
    db.query(
      "SELECT MAX(SUBSTRING(Discount_ID, 4)) as maxId FROM discount",
      (err, results) => {
        if (err) {
          console.error("Error finding max discount ID:", err);
          return reject(err);
        }

        let nextNumericId = 1;
        if (results.length > 0 && results[0].maxId) {
          nextNumericId = parseInt(results[0].maxId) + 1;
        }

        // Format the new ID with leading zeros (e.g. DIS001, DIS002)
        const newId = `DIS${nextNumericId.toString().padStart(3, "0")}`;

        console.log(results);

        // Set default status to 'inactive' if not specified
        if (!promotionData.status) {
          promotionData.status = "Inactive";
        }

        // Convert percentage values from e.g. "25%" to "0.25" format for storage
        let value = promotionData.value;
        if (
          value &&
          promotionData.type &&
          promotionData.type.toLowerCase() === "percentage"
        ) {
          // If value is a percentage string (e.g. "25%"), convert to decimal
          if (typeof value === "string" && value.includes("%")) {
            value = (parseFloat(value) / 100).toString();
          }
        }

        const insert_sql = `
        INSERT INTO discount (
          Discount_ID,
          discount_code, 
          discount_type, 
          discount_value, 
          discount_status, 
          discount_value, 
          discount_effective_date, 
          discount_expire_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `;

        const effectiveFromDate = new Date(promotionData.effectiveFrom);
        const effectiveFrom = effectiveFromDate
          .toISOString()
          .slice(0, 19)
          .replace("T", " ");

        const effectiveUntilDate = new Date(promotionData.effectiveUntil);
        const effectiveUntil = effectiveUntilDate
          .toISOString()
          .slice(0, 19)
          .replace("T", " ");

        var type = "";

        if (typeof value === "string" && value.includes("%")) {
          // If value is a percentage string (e.g. "25%"), convert to decimal
          value = (parseFloat(value) / 100).toString();
          type = "Percentage";
        } else {
          type = "Fixed";
        }

        const params = [
          newId,
          promotionData.code,
          type,
          value,
          promotionData.status,
          promotionData.maxUses || 0,
          effectiveFrom,
          effectiveUntil,
        ];

        db.query(insert_sql, params, (err, results) => {
          if (err) {
            console.error("Error adding promotion:", err);
            reject(err);
            return;
          }

          console.log(`New promotion added with ID ${newId}.`);
          resolve({
            message: `New promotion added with ID ${newId}.`,
            promoId: newId,
            results,
          });
        });
      }
    );
  });
}

export function deletePromotions(db, promoId) {
  return new Promise((resolve, reject) => {
    if (!promoId) {
      return reject(
        new Error("Promotion ID (Discount_ID) is required for deletion.")
      );
    }

    const delete_sql = "DELETE FROM discount WHERE Discount_ID = ?"; // Use correct table and column

    db.query(delete_sql, [promoId], (err, results) => {
      if (err) {
        console.error(
          `Error deleting promotion with Discount_ID ${promoId}:`,
          err
        );
        reject(err);
        return;
      }

      if (results.affectedRows > 0) {
        console.log(
          `Promotion with Discount_ID ${promoId} deleted successfully.`
        );
        resolve({
          message: `Promotion with Discount_ID ${promoId} deleted successfully.`,
        });
      } else {
        console.log(
          `Promotion with Discount_ID ${promoId} not found for deletion.`
        );
        reject(new Error(`Promotion with Discount_ID ${promoId} not found.`)); // Indicate not found
      }
    });
  });
}
