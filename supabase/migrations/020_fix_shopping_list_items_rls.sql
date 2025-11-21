-- Migration: Fix Shopping List Items RLS Policies
-- Ensures synced users can fully manage shopping list items

-- Drop all existing policies on shopping_list_items
DROP POLICY IF EXISTS shopping_list_items_select_policy ON shopping_list_items;
DROP POLICY IF EXISTS shopping_list_items_insert_policy ON shopping_list_items;
DROP POLICY IF EXISTS shopping_list_items_update_policy ON shopping_list_items;
DROP POLICY IF EXISTS shopping_list_items_delete_policy ON shopping_list_items;

-- Recreate SELECT policy with explicit table references
CREATE POLICY shopping_list_items_select_policy ON shopping_list_items
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 
            FROM shopping_lists sl
            WHERE sl.id = shopping_list_items.shopping_list_id
            AND (
                sl.user_id = auth.uid() 
                OR EXISTS (
                    SELECT 1 
                    FROM synced_shopping_lists ssl
                    WHERE ssl.shopping_list_id = sl.id
                    AND ssl.status = 'accepted'
                    AND (ssl.sender_id = auth.uid() OR ssl.recipient_id = auth.uid())
                )
            )
        )
    );

-- Recreate INSERT policy with explicit table references
CREATE POLICY shopping_list_items_insert_policy ON shopping_list_items
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM shopping_lists sl
            WHERE sl.id = shopping_list_items.shopping_list_id
            AND (
                sl.user_id = auth.uid() 
                OR EXISTS (
                    SELECT 1 
                    FROM synced_shopping_lists ssl
                    WHERE ssl.shopping_list_id = sl.id
                    AND ssl.status = 'accepted'
                    AND (ssl.sender_id = auth.uid() OR ssl.recipient_id = auth.uid())
                )
            )
        )
    );

-- Recreate UPDATE policy with explicit table references (both USING and WITH CHECK)
CREATE POLICY shopping_list_items_update_policy ON shopping_list_items
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 
            FROM shopping_lists sl
            WHERE sl.id = shopping_list_items.shopping_list_id
            AND (
                sl.user_id = auth.uid() 
                OR EXISTS (
                    SELECT 1 
                    FROM synced_shopping_lists ssl
                    WHERE ssl.shopping_list_id = sl.id
                    AND ssl.status = 'accepted'
                    AND (ssl.sender_id = auth.uid() OR ssl.recipient_id = auth.uid())
                )
            )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM shopping_lists sl
            WHERE sl.id = shopping_list_items.shopping_list_id
            AND (
                sl.user_id = auth.uid() 
                OR EXISTS (
                    SELECT 1 
                    FROM synced_shopping_lists ssl
                    WHERE ssl.shopping_list_id = sl.id
                    AND ssl.status = 'accepted'
                    AND (ssl.sender_id = auth.uid() OR ssl.recipient_id = auth.uid())
                )
            )
        )
    );

-- Recreate DELETE policy with explicit table references
CREATE POLICY shopping_list_items_delete_policy ON shopping_list_items
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 
            FROM shopping_lists sl
            WHERE sl.id = shopping_list_items.shopping_list_id
            AND (
                sl.user_id = auth.uid() 
                OR EXISTS (
                    SELECT 1 
                    FROM synced_shopping_lists ssl
                    WHERE ssl.shopping_list_id = sl.id
                    AND ssl.status = 'accepted'
                    AND (ssl.sender_id = auth.uid() OR ssl.recipient_id = auth.uid())
                )
            )
        )
    );

-- Ensure RLS is enabled
ALTER TABLE shopping_list_items ENABLE ROW LEVEL SECURITY;

