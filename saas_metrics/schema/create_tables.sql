-- SaaSビジネスメトリクス分析 用スキーマ（MySQL想定）

CREATE TABLE saas_plans (
    plan_id    INT AUTO_INCREMENT PRIMARY KEY,
    plan_name  VARCHAR(50) NOT NULL,
    monthly_price DECIMAL(10,2) NOT NULL
);

CREATE TABLE saas_customers (
    customer_id   INT AUTO_INCREMENT PRIMARY KEY,
    company_name  VARCHAR(200) NOT NULL,
    plan_id       INT NOT NULL,
    signup_date   DATE NOT NULL,
    churned_date  DATE,
    is_active     TINYINT(1) NOT NULL DEFAULT 1,
    FOREIGN KEY (plan_id) REFERENCES saas_plans(plan_id),
    INDEX idx_saas_cust_active (is_active),
    INDEX idx_saas_cust_signup (signup_date)
);

CREATE TABLE saas_mrr_history (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   INT NOT NULL,
    month         DATE NOT NULL,
    mrr           DECIMAL(10,2) NOT NULL,
    change_type   ENUM('new','expansion','contraction','churn','reactivation') NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES saas_customers(customer_id),
    INDEX idx_mrr_month (month),
    INDEX idx_mrr_customer (customer_id)
);
