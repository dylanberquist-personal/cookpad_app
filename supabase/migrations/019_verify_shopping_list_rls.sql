-- Migration: Verify and Fix Shopping List RLS Policies
-- This ensures shopping lists can be accessed and modified by synced users

-- First, let's drop and recreate the shopping_lists select policy to ensure it's correct
DROP POLICY IF EXISTS shopping_lists_select_policy ON shopping_lists;

-- Recreate the policy with better debugging
CREATE POLICY shopping_lists_select_policy ON shopping_lists
    FOR SELECT
    USING (
        user_id = auth.uid() OR
        -- Can see shopping lists that are synced with them (accepted status)
        EXISTS (
            SELECT 1 FROM synced_shopping_lists
            WHERE synced_shopping_lists.shopping_list_id = shopping_lists.id
            AND synced_shopping_lists.status = 'accepted'
            AND (synced_shopping_lists.sender_id = auth.uid() OR synced_shopping_lists.recipient_id = auth.uid())
        )
    );

-- Update policy to allow synced users to update shopping lists (for updated_at timestamp)
DROP POLICY IF EXISTS shopping_lists_update_policy ON shopping_lists;

CREATE POLICY shopping_lists_update_policy ON shopping_lists
    FOR UPDATE
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM synced_shopping_lists
            WHERE synced_shopping_lists.shopping_list_id = shopping_lists.id
            AND synced_shopping_lists.status = 'accepted'
            AND (synced_shopping_lists.sender_id = auth.uid() OR synced_shopping_lists.recipient_id = auth.uid())
        )
    );

-- Also ensure RLS is enabled
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Fix Shopping List Items RLS Policies
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS shopping_list_items_select_policy ON shopping_list_items;
DROP POLICY IF EXISTS shopping_list_items_insert_policy ON shopping_list_items;
DROP POLICY IF EXISTS shopping_list_items_update_policy ON shopping_list_items;
DROP POLICY IF EXISTS shopping_list_items_delete_policy ON shopping_list_items;

-- Recreate with explicit table references

-- Policy: Users can view items from their own lists or synced lists
CREATE POLICY shopping_list_items_select_policy ON shopping_list_items
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM shopping_lists
            WHERE shopping_lists.id = shopping_list_items.shopping_list_id
            AND (
                shopping_lists.user_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM synced_shopping_lists
                    WHERE synced_shopping_lists.shopping_list_id = shopping_lists.id
                    AND synced_shopping_lists.status = 'accepted'
                    AND (synced_shopping_lists.sender_id = auth.uid() OR synced_shopping_lists.recipient_id = auth.uid())
                )
            )
        )
    );

-- Policy: Users can insert items into their own lists or synced lists
CREATE POLICY shopping_list_items_insert_policy ON shopping_list_items
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM shopping_lists
            WHERE shopping_lists.id = shopping_list_items.shopping_list_id
            AND (
                shopping_lists.user_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM synced_shopping_lists
                    WHERE synced_shopping_lists.shopping_list_id = shopping_lists.id
                    AND synced_shopping_lists.status = 'accepted'
                    AND (synced_shopping_lists.sender_id = auth.uid() OR synced_shopping_lists.recipient_id = auth.uid())
                )
            )
        )
    );

-- Policy: Users can update items in their own lists or synced lists
CREATE POLICY shopping_list_items_update_policy ON shopping_list_items
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM shopping_lists
            WHERE shopping_lists.id = shopping_list_items.shopping_list_id
            AND (
                shopping_lists.user_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM synced_shopping_lists
                    WHERE synced_shopping_lists.shopping_list_id = shopping_lists.id
                    AND synced_shopping_lists.status = 'accepted'
                    AND (synced_shopping_lists.sender_id = auth.uid() OR synced_shopping_lists.recipient_id = auth.uid())
                )
            )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM shopping_lists
            WHERE shopping_lists.id = shopping_list_items.shopping_list_id
            AND (
                shopping_lists.user_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM synced_shopping_lists
                    WHERE synced_shopping_lists.shopping_list_id = shopping_lists.id
                    AND synced_shopping_lists.status = 'accepted'
                    AND (synced_shopping_lists.sender_id = auth.uid() OR synced_shopping_lists.recipient_id = auth.uid())
                )
            )
        )
    );

-- Policy: Users can delete items from their own lists or synced lists
CREATE POLICY shopping_list_items_delete_policy ON shopping_list_items
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM shopping_lists
            WHERE shopping_lists.id = shopping_list_items.shopping_list_id
            AND (
                shopping_lists.user_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM synced_shopping_lists
                    WHERE synced_shopping_lists.shopping_list_id = shopping_lists.id
                    AND synced_shopping_lists.status = 'accepted'
                    AND (synced_shopping_lists.sender_id = auth.uid() OR synced_shopping_lists.recipient_id = auth.uid())
                )
            )
        )
    );

