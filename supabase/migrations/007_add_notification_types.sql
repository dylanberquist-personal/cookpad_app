-- Add recipe_image_added notification type
ALTER TABLE notifications
DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE notifications
ADD CONSTRAINT notifications_type_check 
CHECK (type IN ('new_follower', 'recipe_favorited', 'recipe_rated', 'comment', 'remix', 'recipe_image_added'));

