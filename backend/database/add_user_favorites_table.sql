-- Create user_favorites table for services and courses
-- Drop existing table if it has wrong schema (e.g. service_id/course_id instead of item_type/item_id)
DROP TABLE IF EXISTS user_favorites;

CREATE TABLE user_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_type VARCHAR(20) NOT NULL CHECK (item_type IN ('service', 'course')),
  item_id UUID NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, item_type, item_id)
);

CREATE INDEX idx_user_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_item ON user_favorites(item_type, item_id);
