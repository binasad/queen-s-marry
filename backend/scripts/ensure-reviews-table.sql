-- Ensure reviews table exists (run if you get 500 on /reviews/my)
-- Usage: psql -h HOST -U USER -d DB -f scripts/ensure-reviews-table.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    service_id UUID REFERENCES services(id) ON DELETE CASCADE,
    expert_id UUID REFERENCES experts(id) ON DELETE SET NULL,
    appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reviews_service ON reviews(service_id);
CREATE INDEX IF NOT EXISTS idx_reviews_expert ON reviews(expert_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews(user_id);
