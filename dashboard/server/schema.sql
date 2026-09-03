-- OhMyServer Dashboard MariaDB Schema
-- Idempotent: run on every startup, safe to re-execute

CREATE TABLE IF NOT EXISTS `operators` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(128) NOT NULL UNIQUE,
  `pass_hash` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `last_login` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `operator_sessions` (
  `id` VARCHAR(64) PRIMARY KEY,
  `operator_id` INT UNSIGNED NOT NULL,
  `token_hash` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NOT NULL,
  INDEX `idx_op_sessions_op` (`operator_id`),
  CONSTRAINT `fk_op_sessions_op` FOREIGN KEY (`operator_id`) REFERENCES `operators`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `todos` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `operator_id` INT UNSIGNED NOT NULL,
  `content` TEXT NOT NULL,
  `status` ENUM('pending','in_progress','completed','cancelled') DEFAULT 'pending',
  `priority` ENUM('high','medium','low') DEFAULT 'medium',
  `position` INT UNSIGNED DEFAULT 0,
  `time_created` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `time_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_todos_op` (`operator_id`),
  CONSTRAINT `fk_todos_op` FOREIGN KEY (`operator_id`) REFERENCES `operators`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `memory_entries` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `operator_id` INT UNSIGNED NOT NULL,
  `category` ENUM('episodic','semantic','procedural','preference') NOT NULL DEFAULT 'episodic',
  `content_preview` VARCHAR(255) NOT NULL DEFAULT '',
  `content_full` MEDIUMTEXT NOT NULL,
  `importance_score` FLOAT DEFAULT 0.5,
  `access_count` INT UNSIGNED DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FULLTEXT KEY `ft_memory_preview` (`content_preview`),
  FULLTEXT KEY `ft_memory_full` (`content_full`),
  FULLTEXT KEY `ft_memory_combo` (`content_preview`, `content_full`),
  INDEX `idx_memory_op` (`operator_id`),
  INDEX `idx_memory_importance` (`importance_score` DESC),
  CONSTRAINT `fk_memory_op` FOREIGN KEY (`operator_id`) REFERENCES `operators`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `secrets` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `operator_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(128) NOT NULL,
  `kind` ENUM('password','token','api_key','other') DEFAULT 'other',
  `cipher` VARBINARY(1024) NOT NULL COMMENT 'AES_ENCRYPT(content, master_key)',
  `note` TEXT,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_secret_op_name` (`operator_id`, `name`),
  CONSTRAINT `fk_secrets_op` FOREIGN KEY (`operator_id`) REFERENCES `operators`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
