-- Add color column to collections table
-- This allows users to customize the color of their collection cards

ALTER TABLE collections 
ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '#FF6B6B';

-- Update existing collections to have different default colors for variety
-- We'll use a set of attractive, modern colors
UPDATE collections
SET color = CASE 
    WHEN MOD(EXTRACT(EPOCH FROM created_at)::INTEGER, 8) = 0 THEN '#FF6B6B'  -- Coral Red
    WHEN MOD(EXTRACT(EPOCH FROM created_at)::INTEGER, 8) = 1 THEN '#4ECDC4'  -- Turquoise
    WHEN MOD(EXTRACT(EPOCH FROM created_at)::INTEGER, 8) = 2 THEN '#45B7D1'  -- Sky Blue
    WHEN MOD(EXTRACT(EPOCH FROM created_at)::INTEGER, 8) = 3 THEN '#96CEB4'  -- Sage Green
    WHEN MOD(EXTRACT(EPOCH FROM created_at)::INTEGER, 8) = 4 THEN '#FFEAA7'  -- Soft Yellow
    WHEN MOD(EXTRACT(EPOCH FROM created_at)::INTEGER, 8) = 5 THEN '#DFE6E9'  -- Light Gray
    WHEN MOD(EXTRACT(EPOCH FROM created_at)::INTEGER, 8) = 6 THEN '#A29BFE'  -- Lavender
    ELSE '#FD79A8'  -- Pink
END
WHERE color IS NULL;

-- Add a comment to the column
COMMENT ON COLUMN collections.color IS 'Hex color code for the collection card (e.g., #FF6B6B)';

