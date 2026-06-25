-- Rebuild instead of ADD COLUMN so DBs that ran the fork's previous
-- bandwidth migration do not fail on duplicate columns during this sync.

PRAGMA foreign_keys=OFF;--> statement-breakpoint
CREATE TABLE `__new_general_table` (
  `id` integer PRIMARY KEY DEFAULT 1 NOT NULL,
  `setup_step` integer NOT NULL,
  `session_password` text NOT NULL,
  `session_timeout` integer NOT NULL,
  `metrics_prometheus` integer NOT NULL,
  `metrics_json` integer NOT NULL,
  `metrics_password` text,
  `bandwidth_enabled` integer DEFAULT false NOT NULL,
  `download_limit_mbps` integer DEFAULT 0 NOT NULL,
  `upload_limit_mbps` integer DEFAULT 0 NOT NULL,
  `created_at` text DEFAULT (CURRENT_TIMESTAMP) NOT NULL,
  `updated_at` text DEFAULT (CURRENT_TIMESTAMP) NOT NULL
);
--> statement-breakpoint
INSERT INTO `__new_general_table` (
  `id`,
  `setup_step`,
  `session_password`,
  `session_timeout`,
  `metrics_prometheus`,
  `metrics_json`,
  `metrics_password`,
  `bandwidth_enabled`,
  `download_limit_mbps`,
  `upload_limit_mbps`,
  `created_at`,
  `updated_at`
)
SELECT
  `id`,
  `setup_step`,
  `session_password`,
  `session_timeout`,
  `metrics_prometheus`,
  `metrics_json`,
  `metrics_password`,
  false,
  0,
  0,
  `created_at`,
  `updated_at`
FROM `general_table`;
--> statement-breakpoint
DROP TABLE `general_table`;--> statement-breakpoint
ALTER TABLE `__new_general_table` RENAME TO `general_table`;--> statement-breakpoint
PRAGMA foreign_keys=ON;
