CREATE TABLE IF NOT EXISTS jazzcash_transactions (
  id SERIAL PRIMARY KEY,
  txn_ref_no VARCHAR(50) UNIQUE NOT NULL,
  user_id INTEGER NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  metadata JSONB,
  status VARCHAR(20) DEFAULT 'pending',
  response_code VARCHAR(10),
  response_message TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_jazzcash_txn_ref ON jazzcash_transactions(txn_ref_no);
CREATE INDEX IF NOT EXISTS idx_jazzcash_user_id ON jazzcash_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_jazzcash_status ON jazzcash_transactions(status);
