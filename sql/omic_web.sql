DROP DATABASE IF EXISTS omic_web;
CREATE DATABASE IF NOT EXISTS omic_web;
USE omic_web;

-- User Table (No changes needed here)
CREATE TABLE User (
    User_ID CHAR(10) PRIMARY KEY,
    user_type ENUM('Admin', 'Customer', 'Developer') NOT NULL,
    Fname NVARCHAR(255) NOT NULL,
    Lname NVARCHAR(255) NOT NULL,
    DoB DATE,
    phone_num NVARCHAR(10) NOT NULL,
    email NVARCHAR(100) NOT NULL,
    photo_path TEXT,
    create_date DATE
);

-- Login_Data Table
CREATE TABLE Login_Data (
    User_ID CHAR(10),
    username NVARCHAR(50) NOT NULL UNIQUE,
    hashed_password VARCHAR(60) NOT NULL,
    PRIMARY KEY (User_ID),
    -- If User is deleted, delete their Login_Data
    FOREIGN KEY (User_ID) REFERENCES User(User_ID) ON DELETE CASCADE
);

-- Login_Log Table
CREATE TABLE Login_Log (
    Log_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID CHAR(10) NOT NULL,
    Login_Timestamp DATETIME NOT NULL,
    IP_Address NVARCHAR(45) NOT NULL,
    Login_status ENUM('Success', 'Failure') NOT NULL,
    User_Agent TEXT,
    -- If User is deleted, delete their Login_Logs
    FOREIGN KEY (User_ID) REFERENCES User(User_ID) ON DELETE CASCADE
);

-- Membership Table
CREATE TABLE Membership (
    Membership_ID CHAR(10),
    membership_tier NVARCHAR(100) NOT NULL DEFAULT 'Bronze',
    member_point INT NOT NULL,
    User_ID CHAR(10),
    PRIMARY KEY (Membership_ID, User_ID),
    -- If User is deleted, delete their Membership record
    FOREIGN KEY (User_ID) REFERENCES User(User_ID) ON DELETE CASCADE
);

-- Product_Category Table (No FKs to modify)
CREATE TABLE Product_Category (
    Category_ID CHAR(10) PRIMARY KEY,
    Category_name NVARCHAR(255) NOT NULL
);

-- Server Table (No FKs to modify)
CREATE TABLE Server (
    Server_ID CHAR(10) PRIMARY KEY,
    Server_Name NVARCHAR(100) NOT NULL UNIQUE
);

-- Product Table
CREATE TABLE Product (
    Product_ID CHAR(10) PRIMARY KEY,
    product_name NVARCHAR(255) NOT NULL,
    product_category_ID CHAR(10) NOT NULL,
    product_detail TEXT,
    product_instock_quantity INT NOT NULL,
    product_sold_quantity INT NOT NULL DEFAULT 0,
    product_price DECIMAL(10,2) NOT NULL,
    product_rating DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    product_expire_date DATE,
    product_photo_path TEXT,
    -- Keep default behavior (RESTRICT/NO ACTION) for category deletion
    -- Deleting a category should probably not delete all its products automatically
    FOREIGN KEY (product_category_ID) REFERENCES Product_Category(Category_ID)
);

-- Product_Server Linking Table (Already has CASCADE)
CREATE TABLE Product_Server (
    Product_ID CHAR(10) NOT NULL,
    Server_ID CHAR(10) NOT NULL,
    PRIMARY KEY (Product_ID, Server_ID),
    FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID) ON DELETE CASCADE,
    FOREIGN KEY (Server_ID) REFERENCES Server(Server_ID) ON DELETE CASCADE
);

-- Discount Table (No FKs to modify)
CREATE TABLE Discount (
    Discount_ID CHAR(10) PRIMARY KEY,
    discount_code NVARCHAR(20) NOT NULL UNIQUE,
    discount_type ENUM('Percentage', 'Fixed') NOT NULL,
    discount_status ENUM('Active', 'Inactive', 'Expired') NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    discount_effective_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    discount_expire_date DATETIME,
    min_purchase_amount DECIMAL(10, 2) DEFAULT 0.00,
    usage_limit INT DEFAULT NULL,
    usage_count INT DEFAULT 0
);


-- Order_Record Table
CREATE TABLE Order_Record (
    Order_ID CHAR(10) PRIMARY KEY,
    User_ID CHAR(10) NOT NULL,
    Game_UID NVARCHAR(100) DEFAULT '-',
    Game_Username NVARCHAR(100),
    order_status ENUM('In progress', 'Success', 'Cancel') NOT NULL DEFAULT 'In progress',
    Game_server NVARCHAR(100) DEFAULT '-',
    Purchase_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    Total_Amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    Discount_Amount DECIMAL(10, 2) DEFAULT 0.00,
    Final_Amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    Selected_Server_ID CHAR(10) NULL,
    Discount_ID CHAR(10) NULL,
    -- If User is deleted, delete their Order_Records (consider implications)
    FOREIGN KEY (User_ID) REFERENCES User(User_ID) ON DELETE CASCADE,
    -- If Discount is deleted, set Discount_ID in Order_Record to NULL (preserve order history)
    FOREIGN KEY (Discount_ID) REFERENCES Discount(Discount_ID) ON DELETE SET NULL,
    -- If Server is deleted, set Selected_Server_ID in Order_Record to NULL (preserve order history)
    FOREIGN KEY (Selected_Server_ID) REFERENCES Server(Server_ID) ON DELETE SET NULL
);

-- Order_Item Table
CREATE TABLE Order_Item (
    Order_Item_ID INT AUTO_INCREMENT PRIMARY KEY,
    Order_ID CHAR(10) NOT NULL,
    Product_ID CHAR(10) NOT NULL,
    Package_ID VARCHAR(30) NOT NULL, -- Ensure this matches Product_Package.Package_ID type/length if needed
    Quantity INT NOT NULL DEFAULT 1,
    Price_Per_Item DECIMAL(10, 2) NOT NULL,
    Subtotal DECIMAL(10, 2) NOT NULL,
    -- If Order_Record is deleted, delete its Order_Items (already has CASCADE)
    FOREIGN KEY (Order_ID) REFERENCES Order_Record(Order_ID) ON DELETE CASCADE,
    -- Keep default (RESTRICT/NO ACTION) for Product deletion
    -- Deleting a Product should NOT automatically delete historical order items
    FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID) -- ON DELETE RESTRICT (Default)
);


-- Payment_Record Table
CREATE TABLE Payment_Record (
    Payment_ID CHAR(10) PRIMARY KEY,
    Order_ID CHAR(10) NOT NULL UNIQUE,
    customer_bank_account NVARCHAR(50),
    customer_true_wallet_number NVARCHAR(50),
    customer_promptpay_number NVARCHAR(50),
    customer_card_number NVARCHAR(50),
    Payment_amount DECIMAL(10, 2) NOT NULL,
    Payment_status ENUM('In progress', 'Success', 'Cancel') NOT NULL DEFAULT 'In progress',
    Payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    Payment_method ENUM('Credit/Debit Card', 'True Wallet', 'Bank Transfer', 'Promptpay', 'QR Payment') NOT NULL,
    Transaction_ID NVARCHAR(255) NULL,
    Payment_Proof_Path TEXT NULL,
    -- If Order_Record is deleted, delete its Payment_Record
    FOREIGN KEY (Order_ID) REFERENCES Order_Record(Order_ID) ON DELETE CASCADE
);

-- Review Table
CREATE TABLE Review (
    Review_ID INT AUTO_INCREMENT PRIMARY KEY,
    Product_ID CHAR(10) NOT NULL,
    User_ID CHAR(10) NOT NULL,
    Order_ID CHAR(10) NULL,
    review_rating DECIMAL(2, 1) NOT NULL CHECK (review_rating BETWEEN 0.0 AND 5.0),
    review_note TEXT,
    review_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (Product_ID, User_ID, Order_ID),
    -- If Product is deleted, delete its Reviews
    FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID) ON DELETE CASCADE,
    -- If User is deleted, delete their Reviews
    FOREIGN KEY (User_ID) REFERENCES User(User_ID) ON DELETE CASCADE,
    -- If Order_Record is deleted, set Order_ID in Review to NULL (keep review, unlink from specific order)
    FOREIGN KEY (Order_ID) REFERENCES Order_Record(Order_ID) ON DELETE SET NULL
);

-- Product_Package Table (Already has CASCADE)
CREATE TABLE Product_Package (
    Package_ID CHAR(10) PRIMARY KEY,
    Product_ID CHAR(10) NOT NULL,
    Package_Name NVARCHAR(255) NOT NULL,
    Package_Price DECIMAL(10, 2) NOT NULL,
    Bonus_Description NVARCHAR(100) NULL,
    FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID) ON DELETE CASCADE
);

-- --- MOCK DATA ---
-- (Your mock data inserts remain the same)

-- Mock data for 'user' table
INSERT INTO user (User_ID, user_type, Fname, Lname, DOB, phone_num, email, photo_path, create_date) VALUES
('ADM001', 'Admin', 'John', 'Doe', '1990-05-15', '1234567890', 'john.doe@admin.com', NULL, '2023-01-20'),
('CUS001', 'Customer', 'Alice', 'Smith', '1985-11-22', '9876543210', 'alice.smith@customer.com', NULL, '2023-02-10'),
('CUS002', 'Customer', 'Bob', 'Johnson', '2000-03-01', '5551234567', 'bob.johnson@customer.com', NULL, '2023-03-05'),
('ADM002', 'Admin', 'Charlie', 'Brown', '1995-07-10', '1112223333', 'charlie.brown@admin.com', NULL, '2023-04-15'),
('ADM003', 'Admin', 'Eve', 'Williams', '1988-12-28', '4445556666', 'eve.williams@admin.com', NULL, '2023-05-01'),
('CUS003', 'Customer', 'David', 'Jones', '1992-09-03', '7778889999', 'david.jones@customer.com', NULL, '2023-06-12'),
('CUS004', 'Customer', 'Sophia', 'Miller', '2001-06-18', '3334445555', 'sophia.miller@customer.com', NULL, '2023-07-25'),
('ADM004', 'Admin', 'Michael', 'Davis', '1980-04-25', '6667778888', 'michael.davis@admin.com', NULL, '2023-08-08'),
('CUS005', 'Customer', 'Olivia', 'Wilson', '1997-01-12', '2223334444', 'olivia.wilson@customer.com', NULL, '2023-09-19'),
('CUS006', 'Customer', 'James', 'Taylor', '1983-10-07', '8889990000', 'james.taylor@customer.com', NULL, '2023-10-30');

-- Mock data for 'membership' table
INSERT INTO membership (Membership_ID, membership_tier, member_point, User_ID) VALUES
('MEM001', 'Bronze', 50, 'CUS001'),
('MEM002', 'Silver', 180, 'CUS002'),
('MEM003', 'Bronze', 20, 'CUS003'),
('MEM004', 'Gold', 350, 'CUS004'),
('MEM005', 'Silver', 120, 'CUS005'),
('MEM006', 'Platinum', 500, 'CUS006');

-- Mock data for 'Login_Data' table
INSERT INTO Login_Data (User_ID, username, hashed_password) VALUES
('ADM001', 'admin1', '$2b$10$Qy7ftHsdJbQyoiXEGqJ3wer7hz2INsOnQOHE1nXa/lf1ilV2mpOc.'),
('CUS001', 'alice123', '$2b$10$S8.f37jLRAt38L0G6gUUgefCXMj/9MGYidcyh8lwpKxz1bBvz2V5m'),
('CUS002', 'bob_the_builder', '$2b$10$du2rSOzaYE6.lLk/IMvi8.VxRfogm2J8OLwEJcX.PoR3HJ.eOOmOW'),
('ADM002', 'charlie_admin', '$2b$10$rYG61y5DzKB8Xulo02/xNe2xq6TBGWhcr4uHLi9FHoLqZi89YMp0W'),
('ADM003', 'eve_the_admin', '$2b$10$OxSjZsIDwfnQoA.gDXbi4Om5z5UCgrlIvtMefzHYVvi1vE56TKIDO'),
('CUS003', 'david456', '$2b$10$fNEnKA.eHmQQ4hT9sRV2uedXe2Qx.VTvDBSBtRALOdgLKejTlSb1m'),
('CUS004', 'sophia_m', '$2b$10$rrmmF9NXlRihbBW7RIXVl.thxtjeTxqQhR4mo/QAuwdjTvU97LYlK'),
('ADM004', 'mike_admin', '$2b$10$TiYD40tToKTpUnJVbILBAOAvRr9MMUONEZu92Jrx7n17VVh.HrJxq'),
('CUS005', 'olivia_w', '$2b$10$svIeB.fDWt1aKZRHRvplc.TS.gPu7wKEycRc1Ij8mUtx9pABOLRxq'),
('CUS006', 'james_t', '$2b$10$ttTcE37yZRGCsTdf.buTX.zPjL22zawRA72ipN5czqthesmVvZeI6');

-- Mock data for 'login_log' table
INSERT INTO Login_Log (User_ID, Login_Timestamp, IP_Address, Login_status, User_Agent) VALUES
('CUS001', '2025-04-27 20:00:00', '192.168.1.100', 'Success', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36'),
('ADM001', '2025-04-27 20:05:30', '10.0.0.5', 'Success', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15'),
('CUS002', '2025-04-27 20:12:45', '192.168.1.105', 'Failure', 'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36'),
('CUS001', '2025-04-27 20:15:00', '192.168.1.100', 'Success', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36'),
('ADM002', '2025-04-27 20:21:10', '10.0.0.6', 'Success', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/112.0'),
('CUS003', '2025-04-27 20:28:22', '192.168.1.110', 'Success', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Mobile/15E148 Safari/604.1'),
('ADM001', '2025-04-27 20:33:58', '10.0.0.5', 'Failure', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15'),
('CUS004', '2025-04-27 20:40:15', '192.168.1.115', 'Success', 'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36'),
('ADM003', '2025-04-27 20:45:40', '10.0.0.7', 'Success', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:112.0) Gecko/20100101 Firefox/112.0'),
('CUS005', '2025-04-27 20:52:05', '192.168.1.120', 'Success', 'Mozilla/5.0 (iPad; CPU OS 16_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Mobile/15E148 Safari/604.1');

-- Mock data for 'product_category' table
INSERT INTO Product_Category (Category_ID, Category_name) VALUES
('CATG01', 'Game Top-up'),
('CATG02', 'Gift Cards'),
('CATG03', 'Mobile Recharge'),
('CATG04', 'Game Keys'),
('CATG05', 'In-Game Items');

-- Mock data for 'Server' table
INSERT INTO Server (Server_ID, Server_Name) VALUES
('SRV001', 'Global'),
('SRV002', 'Asia'),
('SRV003', 'Europe'),
('SRV004', 'North America'),
('SRV005', 'South America'),
('SRV006', 'SEA'),
('SRV007', 'LATAM'),
('SRV008', 'KRJP'),
('SRV009', 'TW/HK/MO'),
('SRV010', 'Thailand'),
('SRV011', 'APAC');

-- Mock data for 'product' table
INSERT INTO Product (Product_ID, product_name, product_category_ID, product_detail, product_instock_quantity, product_sold_quantity, product_price, product_rating, product_expire_date, product_photo_path) VALUES
('PRODFF001', 'Free Fire', 'CATG01', 'Top-up Garena Free Fire Diamonds. Requires Player ID.', 9999, 150, 100.00, 4.70, NULL, 'freefire.png'),
('PRODGI001', 'Genshin Impact', 'CATG01', 'Purchase Genesis Crystals for Genshin Impact. Requires UID and Server.', 9999, 210, 150.00, 4.85, NULL, 'genshin.png'),
('PRODLOL01', 'League of Legends', 'CATG01', 'Top-up Riot Points (RP) for League of Legends. Requires Riot ID/Username and Region.', 9999, 180, 100.00, 4.60, NULL, 'lol.png'),
('PRODPU001', 'Pokemon Unite', 'CATG01', 'Purchase Aeos Gems for Pokemon Unite. Requires Trainer ID.', 9999, 90, 120.00, 4.50, NULL, 'pokemonunite.png'),
('PRODPUBG1', 'PUBG', 'CATG01', 'Purchase Unknown Cash (UC) for PlayerUnknowns Battlegrounds (Steam). Requires Character ID.', 9999, 110, 150.00, 4.75, NULL, 'pubg.png'),
('PRODPBGM1', 'PUBG Mobile', 'CATG01', 'Purchase Unknown Cash (UC) for PUBG Mobile. Requires Player ID.', 9999, 350, 100.00, 4.80, NULL, 'pubgm.png'),
('PRODRBLX1', 'Roblox', 'CATG01', 'Top-up Robux for Roblox. Requires Username.', 9999, 420, 100.00, 4.90, NULL, 'roblox.png'),
('PRODROV01', 'RoV', 'CATG01', 'Top-up Vouchers for RoV (Arena of Valor). Requires OpenID/Player ID and Server.', 9999, 280, 100.00, 4.70, NULL, 'rov.png'),
('PRODSR001', 'Honkai: Star Rail', 'CATG01', 'Purchase Oneiric Shards for Honkai: Star Rail. Requires UID and Server.', 9999, 160, 150.00, 4.80, NULL, 'starrail.png'),
('PRODVL001', 'Valorant', 'CATG01', 'Top-up Valorant Points (VP). Requires Riot ID and Region Tag.', 9999, 310, 100.00, 4.95, NULL, 'valorant.png');

-- Mock data for 'Product_Server' table
INSERT INTO Product_Server (Product_ID, Server_ID) VALUES
('PRODFF001', 'SRV001'), ('PRODFF001', 'SRV006'), ('PRODFF001', 'SRV007'),
('PRODGI001', 'SRV002'), ('PRODGI001', 'SRV003'), ('PRODGI001', 'SRV004'), ('PRODGI001', 'SRV009'),
('PRODLOL01', 'SRV004'), ('PRODLOL01', 'SRV003'), ('PRODLOL01', 'SRV006'), ('PRODLOL01', 'SRV008'),
('PRODPU001', 'SRV001'),
('PRODPUBG1', 'SRV001'), ('PRODPUBG1', 'SRV002'), ('PRODPUBG1', 'SRV003'), ('PRODPUBG1', 'SRV004'), ('PRODPUBG1', 'SRV005'), ('PRODPUBG1', 'SRV006'), ('PRODPUBG1', 'SRV008'),
('PRODPBGM1', 'SRV001'), ('PRODPBGM1', 'SRV002'), ('PRODPBGM1', 'SRV003'), ('PRODPBGM1', 'SRV004'), ('PRODPBGM1', 'SRV005'), ('PRODPBGM1', 'SRV008'),
('PRODRBLX1', 'SRV001'),
('PRODROV01', 'SRV006'), ('PRODROV01', 'SRV010'), ('PRODROV01', 'SRV003'), ('PRODROV01', 'SRV004'), ('PRODROV01', 'SRV007'),
('PRODSR001', 'SRV002'), ('PRODSR001', 'SRV003'), ('PRODSR001', 'SRV004'), ('PRODSR001', 'SRV009'),
('PRODVL001', 'SRV011'), ('PRODVL001', 'SRV004'), ('PRODVL001', 'SRV003'), ('PRODVL001', 'SRV008');

-- Mock data for 'discount' table
INSERT INTO Discount (Discount_ID, discount_code, discount_status, discount_type, discount_value, discount_effective_date, discount_expire_date, min_purchase_amount, usage_limit) VALUES
('DISC001', 'SUMMER10', 'Active', 'Percentage', 10.00, '2025-04-20 00:00:00', '2025-05-31 23:59:59', 50.00, 1000),
('DISC002', 'WELCOME5', 'Active', 'Fixed', 50.00, '2025-04-15 00:00:00', '2025-06-15 23:59:59', 200.00, 1),
('DISC003', 'EXPIRED20', 'Expired', 'Percentage', 20.00, '2025-03-01 00:00:00', '2025-04-20 23:59:59', 100.00, NULL),
('DISC004', 'FLASH25', 'Active', 'Fixed', 25.00, '2025-04-28 12:00:00', '2025-04-28 23:59:59', 0.00, 500),
('DISC005', 'NEWGAME15', 'Inactive', 'Percentage', 15.00, '2025-05-01 00:00:00', '2025-05-15 23:59:59', 150.00, NULL);

-- Mock data for 'order_record' table
INSERT INTO Order_Record (Order_ID, User_ID, Game_UID, Game_Username, order_status, Game_server, Purchase_Date, Total_Amount, Discount_Amount, Final_Amount, Discount_ID, Selected_Server_ID) VALUES
('ORD001', 'CUS001', 'FF:987654321', 'AliceFF', 'Success', 'SEA', '2025-04-10 10:00:00', 100.00, 10.00, 90.00, 'DISC001', 'SRV006'),
('ORD002', 'CUS002', 'UID:800123456', 'BobImpact', 'Success', 'Asia', '2025-04-11 14:30:00', 150.00, 0.00, 150.00, NULL, 'SRV002'),
('ORD003', 'CUS001', 'PlayerID: 5123456789', 'AliceM', 'In progress', 'Global', '2025-04-15 18:45:00', 100.00, 0.00, 100.00, NULL, 'SRV001'), -- Corrected game_server based on product
('ORD004', 'CUS003', 'IGN:ValorantPlayer#EUW', 'DavidVal', 'Cancel', 'Europe', '2025-04-12 09:15:00', 100.00, 0.00, 100.00, NULL, 'SRV003'),
('ORD005', 'CUS004', 'TrainerID: ABCDE12345', 'SophiaPoke', 'Success', 'Global', '2025-04-13 21:00:00', 120.00, 0.00, 120.00, NULL, 'SRV001');

-- Mock data for 'Order_Item' table
INSERT INTO Order_Item (Order_ID, Product_ID, Package_ID, Quantity, Price_Per_Item, Subtotal) VALUES
('ORD001', 'PRODFF001', 'PKFF100D', 1, 100.00, 100.00), -- Made up Package_ID
('ORD002', 'PRODGI001', 'PKGI300C', 1, 150.00, 150.00), -- Made up Package_ID
('ORD003', 'PRODPBGM1', 'PKPM180UC', 1, 100.00, 100.00), -- Made up Package_ID
('ORD004', 'PRODVL001', 'PKVL1000VP', 1, 100.00, 100.00), -- Made up Package_ID
('ORD005', 'PRODPU001', 'PKPU500G', 1, 120.00, 120.00); -- Made up Package_ID

-- Mock data for 'payment_record' table
INSERT INTO Payment_Record (Payment_ID, Order_ID, customer_bank_account, customer_true_wallet_number, customer_promptpay_number, customer_card_number, Payment_amount, Payment_status, Payment_date, Payment_method, Transaction_ID, Payment_Proof_Path) VALUES
('PAY001', 'ORD001', NULL, '0812345678', NULL, NULL, 90.00, 'Success', '2025-04-10 10:05:00', 'True Wallet', 'TW20250410ABC1', NULL),
('PAY002', 'ORD002', NULL, NULL, NULL, '************7654', 150.00, 'Success', '2025-04-11 14:35:00', 'Credit/Debit Card', 'CC20250411DEF2', NULL),
('PAY003', 'ORD003', '1234567890', NULL, NULL, NULL, 100.00, 'In progress', '2025-04-15 18:50:00', 'Bank Transfer', NULL, '/proofs/slip003.jpg'), -- Added proof path example
('PAY004', 'ORD004', NULL, NULL, NULL, NULL, 100.00, 'Cancel', '2025-04-12 09:20:00', 'QR Payment', 'QR20250412GHI4', NULL),
('PAY005', 'ORD005', NULL, NULL, '0987654321', NULL, 120.00, 'Success', '2025-04-13 21:05:00', 'Promptpay', 'PP20250413JKL5', NULL);

-- Mock data for 'review' table
INSERT INTO Review (Product_ID, User_ID, Order_ID, review_rating, review_note, review_date) VALUES
('PRODFF001', 'CUS001', 'ORD001', 4.5, 'Instant delivery, works great!', '2025-04-11 11:00:00'),
('PRODGI001', 'CUS002', 'ORD002', 5.0, 'Fast code delivery, easy to redeem.', '2025-04-12 15:00:00'),
('PRODPU001', 'CUS004', 'ORD005', 4.0, 'Good price for gems.', '2025-04-14 10:00:00');

-- Mock data for 'Product_Package' table
INSERT INTO Product_Package (Package_ID, Product_ID, Package_Name, Package_Price, Bonus_Description) VALUES
('PKSR001', 'PRODSR001', '60 Oneiric Shards', 35.00, NULL),
('PKSR002', 'PRODSR001', '300 + 30 Oneiric Shards', 179.00, '+30 Bonus Shards'),
('PKSR003', 'PRODSR001', '980 + 110 Oneiric Shards', 529.00, '+110 Bonus Shards'),
('PKSR004', 'PRODSR001', '1980 + 260 Oneiric Shards', 1050.00, '+260 Bonus Shards'),
('PKSR005', 'PRODSR001', '3280 + 600 Oneiric Shards', 1750.00, '+600 Bonus Shards'),
('PKSR006', 'PRODSR001', '6480 + 1600 Oneiric Shards', 3500.00, '+1600 Bonus Shards'),
('PKSR007', 'PRODSR001', 'Express Supply Pass', 179.00, '30-Day Subscription'),
-- Added made-up package IDs used in Order_Item mock data for consistency
('PKFF100D', 'PRODFF001', '100 Diamonds', 100.00, NULL),
('PKGI300C', 'PRODGI001', '300 Genesis Crystals', 150.00, NULL),
('PKPM180UC', 'PRODPBGM1', '180 UC', 100.00, NULL),
('PKVL1000VP', 'PRODVL001', '1000 Valorant Points', 100.00, NULL),
('PKPU500G', 'PRODPU001', '500 Aeos Gems', 120.00, NULL);


-- Example SELECT to see products and their servers
SELECT
    p.Product_ID,
    p.product_name,
    p.product_price,
    s.Server_Name
FROM Product p
LEFT JOIN Product_Server ps ON p.Product_ID = ps.Product_ID
LEFT JOIN Server s ON ps.Server_ID = s.Server_ID
ORDER BY p.product_name, s.Server_Name;

SELECT * FROM Product;