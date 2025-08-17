-- Initialize payment gateway database
CREATE DATABASE IF NOT EXISTS payment_gateway;
USE payment_gateway;

-- Updated table schema to match Payment model fields
CREATE TABLE IF NOT EXISTS payments (
                                        id VARCHAR(36) PRIMARY KEY,
    merchant_id VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(50) NOT NULL,
    payment_method VARCHAR(50) NOT NULL DEFAULT 'card',
    card_number VARCHAR(255) NOT NULL,
    card_holder_name VARCHAR(255) NOT NULL,
    expiry_month INT NOT NULL,
    expiry_year INT NOT NULL,
    cvv VARCHAR(4) NOT NULL,
    description TEXT,
    callback_url VARCHAR(500),
    transaction_id VARCHAR(255),
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL,

    INDEX idx_merchant_id (merchant_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_transaction_id (transaction_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Updated sample data to use correct field names
INSERT INTO payments (
    id, merchant_id, amount, currency, status, payment_method, card_number, card_holder_name,
    expiry_month, expiry_year, cvv, transaction_id
) VALUES
    (
        'sample-payment-1', 'merchant-123', 99.99, 'USD', 'success', 'card',
        '4111111111111111', 'John Doe', 12, 2025, '123', 'txn-sample-1'
    );
