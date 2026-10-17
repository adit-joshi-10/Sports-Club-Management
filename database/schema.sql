-- =====================================================
-- SCMS: Sports Club Management System
-- File: database/schema.sql
-- WARNING: re-running this drops all tables = demo reset
-- =====================================================

CREATE DATABASE IF NOT EXISTS scms_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE scms_db;

-- Drop in reverse dependency order (children first)
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS training_schedules;
DROP TABLE IF EXISTS sport_registrations;
DROP TABLE IF EXISTS sports;
DROP TABLE IF EXISTS coaches;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS users;

-- D1 Users: login identity + role (admin/coach/member)
CREATE TABLE users (
  user_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  email         VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role          ENUM('admin','coach','member') NOT NULL,
  is_active     TINYINT(1)   NOT NULL DEFAULT 1,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                             ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

-- D2 Members: profile of a user with role 'member'
CREATE TABLE members (
  member_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       INT UNSIGNED NOT NULL,
  full_name     VARCHAR(120) NOT NULL,
  phone         VARCHAR(20)  NULL,
  date_of_birth DATE         NULL,
  joined_on     DATE         NOT NULL DEFAULT (CURRENT_DATE),
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                             ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (member_id),
  UNIQUE KEY uq_members_user (user_id),
  CONSTRAINT fk_members_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- D3 Coaches: profile of a user with role 'coach'
CREATE TABLE coaches (
  coach_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id        INT UNSIGNED NOT NULL,
  full_name      VARCHAR(120) NOT NULL,
  phone          VARCHAR(20)  NULL,
  specialization VARCHAR(100) NULL,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                              ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (coach_id),
  UNIQUE KEY uq_coaches_user (user_id),
  CONSTRAINT fk_coaches_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- D4 Sports
-- icon_key drives the themed UI icon (football, cricket, ...)
CREATE TABLE sports (
  sport_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name        VARCHAR(80)  NOT NULL,
  description VARCHAR(500) NULL,
  icon_key    VARCHAR(30)  NOT NULL DEFAULT 'generic',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                           ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (sport_id),
  UNIQUE KEY uq_sports_name (name)
) ENGINE=InnoDB;

-- D7 Sport_Registration: Member <-> Sport (many-to-many)
CREATE TABLE sport_registrations (
  registration_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  member_id       INT UNSIGNED NOT NULL,
  sport_id        INT UNSIGNED NOT NULL,
  registered_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (registration_id),
  UNIQUE KEY uq_registration_member_sport (member_id, sport_id),
  KEY idx_registration_sport (sport_id),
  CONSTRAINT fk_registration_member FOREIGN KEY (member_id)
    REFERENCES members (member_id) ON DELETE CASCADE,
  CONSTRAINT fk_registration_sport FOREIGN KEY (sport_id)
    REFERENCES sports (sport_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- D5 Training_Schedule: one session of a sport run by one coach
CREATE TABLE training_schedules (
  schedule_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  sport_id     INT UNSIGNED NOT NULL,
  coach_id     INT UNSIGNED NOT NULL,
  session_date DATE         NOT NULL,
  start_time   TIME         NOT NULL,
  end_time     TIME         NOT NULL,
  venue        VARCHAR(100) NOT NULL,
  notes        VARCHAR(500) NULL,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (schedule_id),
  KEY idx_schedule_date (session_date),
  KEY idx_schedule_coach (coach_id),
  KEY idx_schedule_sport (sport_id),
  CONSTRAINT chk_schedule_times CHECK (end_time > start_time),
  CONSTRAINT fk_schedule_sport FOREIGN KEY (sport_id)
    REFERENCES sports (sport_id) ON DELETE RESTRICT,
  CONSTRAINT fk_schedule_coach FOREIGN KEY (coach_id)
    REFERENCES coaches (coach_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- D6 Attendance: one row per member per session
CREATE TABLE attendance (
  attendance_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  schedule_id        INT UNSIGNED NOT NULL,
  member_id          INT UNSIGNED NOT NULL,
  status             ENUM('present','late','absent') NOT NULL,
  marked_by_user_id  INT UNSIGNED NULL,
  marked_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                              ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (attendance_id),
  UNIQUE KEY uq_attendance_session_member (schedule_id, member_id),
  KEY idx_attendance_member (member_id),
  CONSTRAINT fk_attendance_schedule FOREIGN KEY (schedule_id)
    REFERENCES training_schedules (schedule_id) ON DELETE CASCADE,
  CONSTRAINT fk_attendance_member FOREIGN KEY (member_id)
    REFERENCES members (member_id) ON DELETE CASCADE,
  CONSTRAINT fk_attendance_marker FOREIGN KEY (marked_by_user_id)
    REFERENCES users (user_id) ON DELETE SET NULL
) ENGINE=InnoDB;