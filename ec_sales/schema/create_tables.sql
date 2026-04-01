-- EC売上・顧客分析 用スキーマ（MySQL想定）

CREATE TABLE customers (
    customer_id      INT AUTO_INCREMENT PRIMARY KEY,
    customer_name    VARCHAR(100) NOT NULL,
    email            VARCHAR(255),
    gender           ENUM('male','female','other') NULL,
    signup_date      DATE NOT NULL,
    city             VARCHAR(100),
    age              INT
);

CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

CREATE TABLE products (
    product_id    INT AUTO_INCREMENT PRIMARY KEY,
    product_name  VARCHAR(200) NOT NULL,
    category_id   INT NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    is_active     TINYINT(1) NOT NULL DEFAULT 1,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE orders (
    order_id       INT AUTO_INCREMENT PRIMARY KEY,
    customer_id    INT NOT NULL,
    order_date     DATETIME NOT NULL,
    status         ENUM('pending','paid','shipped','cancelled') NOT NULL,
    payment_method ENUM('card','bank','cod','other') NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_orders_date (order_date),
    INDEX idx_orders_customer (customer_id)
);

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id      INT NOT NULL,
    product_id    INT NOT NULL,
    quantity      INT NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_items_order (order_id),
    INDEX idx_items_product (product_id)
);
