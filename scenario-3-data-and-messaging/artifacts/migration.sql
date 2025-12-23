-- Migration: Add user preferences and recommendation tracking
-- Author: developer@plooral.com
-- Date: 2024-01-14
-- Ticket: PLOOR-4521
-- 
-- REVIEWER NOTES:
-- This migration was written by a developer without DBA review.
-- NOTE: This script has NOT been approved for production execution.

-- ============================================================================
-- PART 1: Modify users table (2.5 million rows)
-- ============================================================================

-- Add new columns for user preferences
ALTER TABLE users 
ADD COLUMN preference_json JSONB DEFAULT '{}',
ADD COLUMN last_recommendation_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN recommendation_score DECIMAL(5,2) DEFAULT 0.00,
ADD COLUMN is_premium BOOLEAN DEFAULT FALSE NOT NULL;

-- Add constraint for recommendation_score
ALTER TABLE users
ADD CONSTRAINT chk_recommendation_score 
CHECK (recommendation_score >= 0 AND recommendation_score <= 100);

-- ============================================================================
-- PART 2: Create new indexes
-- ============================================================================

-- Index for finding users by premium status
CREATE INDEX idx_users_premium ON users(is_premium) WHERE is_premium = TRUE;

-- Index for recommendation scoring
CREATE INDEX idx_users_recommendation_score ON users(recommendation_score DESC);

-- Composite index for recommendation queries
CREATE INDEX idx_users_recommendations 
ON users(last_recommendation_at DESC, recommendation_score DESC) 
WHERE recommendation_score > 50;

-- ============================================================================
-- PART 3: Create new tables
-- ============================================================================

-- User recommendations history table
CREATE TABLE user_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    score DECIMAL(5,2) NOT NULL,
    reason TEXT,
    shown_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    clicked_at TIMESTAMP WITH TIME ZONE,
    applied_at TIMESTAMP WITH TIME ZONE,
    dismissed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for the new table
CREATE INDEX idx_user_recommendations_user_id ON user_recommendations(user_id);
CREATE INDEX idx_user_recommendations_job_id ON user_recommendations(job_id);
CREATE INDEX idx_user_recommendations_shown_at ON user_recommendations(shown_at DESC);

-- ============================================================================
-- PART 4: Data migration
-- ============================================================================

-- Backfill premium status from subscriptions table
UPDATE users u
SET is_premium = TRUE
FROM subscriptions s
WHERE s.user_id = u.id 
  AND s.status = 'active'
  AND s.plan_type IN ('premium', 'enterprise');

-- Backfill recommendation scores from existing data
UPDATE users u
SET recommendation_score = (
    SELECT COALESCE(AVG(m.score), 0)
    FROM user_job_matches m
    WHERE m.user_id = u.id
);

-- ============================================================================
-- PART 5: Modify existing constraints
-- ============================================================================

-- Drop old constraint
ALTER TABLE job_applications DROP CONSTRAINT IF EXISTS fk_job_applications_user;

-- Add new constraint with different ON DELETE behavior
ALTER TABLE job_applications
ADD CONSTRAINT fk_job_applications_user 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

-- ============================================================================
-- ROLLBACK SCRIPT
-- ============================================================================
-- 
-- To rollback, run:
-- 
-- DROP TABLE IF EXISTS user_recommendations;
-- ALTER TABLE users DROP COLUMN IF EXISTS preference_json;
-- ALTER TABLE users DROP COLUMN IF EXISTS last_recommendation_at;
-- ALTER TABLE users DROP COLUMN IF EXISTS recommendation_score;
-- ALTER TABLE users DROP COLUMN IF EXISTS is_premium;
