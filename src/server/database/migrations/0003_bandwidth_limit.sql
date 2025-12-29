-- Migration: Add bandwidth limiting columns to general_table
-- Date: 2025-12-29
-- Feature: Global bandwidth limiting for WireGuard interface

ALTER TABLE `general_table` ADD `bandwidth_enabled` integer DEFAULT 0 NOT NULL;
ALTER TABLE `general_table` ADD `download_limit_mbps` integer DEFAULT 0 NOT NULL;
ALTER TABLE `general_table` ADD `upload_limit_mbps` integer DEFAULT 0 NOT NULL;
