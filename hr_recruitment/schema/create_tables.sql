-- 採用・求人データ分析 用スキーマ（MySQL想定）

CREATE TABLE candidates (
    candidate_id     INT AUTO_INCREMENT PRIMARY KEY,
    full_name        VARCHAR(100) NOT NULL,
    email            VARCHAR(255),
    phone            VARCHAR(50),
    gender           ENUM('male','female','other') NULL,
    age              INT,
    current_city     VARCHAR(100),
    current_role     VARCHAR(100),
    experience_years DECIMAL(4,1),
    created_at       DATETIME NOT NULL
);

CREATE TABLE jobs (
    job_id          INT AUTO_INCREMENT PRIMARY KEY,
    job_title       VARCHAR(150) NOT NULL,
    department      VARCHAR(100) NOT NULL,
    employment_type ENUM('fulltime','contract','parttime','intern') NOT NULL,
    location        VARCHAR(100),
    posted_date     DATE NOT NULL,
    closed_date     DATE,
    headcount       INT DEFAULT 1
);

CREATE TABLE sources (
    source_id    INT AUTO_INCREMENT PRIMARY KEY,
    source_name  VARCHAR(100) NOT NULL,
    source_type  ENUM('job_board','referral','agency','direct','other') NOT NULL
);

CREATE TABLE applications (
    application_id INT AUTO_INCREMENT PRIMARY KEY,
    candidate_id   INT NOT NULL,
    job_id         INT NOT NULL,
    source_id      INT,
    applied_at     DATETIME NOT NULL,
    current_status ENUM('applied','screening','interview','offer','hired','rejected')
                   NOT NULL DEFAULT 'applied',
    hired_flag     TINYINT(1) NOT NULL DEFAULT 0,
    hired_at       DATETIME,
    rejected_at    DATETIME,
    FOREIGN KEY (candidate_id) REFERENCES candidates(candidate_id),
    FOREIGN KEY (job_id)      REFERENCES jobs(job_id),
    FOREIGN KEY (source_id)   REFERENCES sources(source_id),
    INDEX idx_app_job (job_id),
    INDEX idx_app_source (source_id),
    INDEX idx_app_status (current_status)
);

CREATE TABLE application_stages (
    stage_id         INT AUTO_INCREMENT PRIMARY KEY,
    application_id   INT NOT NULL,
    stage_name       ENUM('applied','screening','interview','offer','hired','rejected') NOT NULL,
    stage_entered_at DATETIME NOT NULL,
    stage_left_at    DATETIME,
    result           ENUM('pass','fail','pending') DEFAULT 'pending',
    UNIQUE KEY uq_app_stage (application_id, stage_name),
    FOREIGN KEY (application_id) REFERENCES applications(application_id),
    INDEX idx_stage_name (stage_name)
);
