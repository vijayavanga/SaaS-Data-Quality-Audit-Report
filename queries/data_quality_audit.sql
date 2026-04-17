-- ===========================
-- 1. accounts Table
-- ===========================
CREATE TABLE accounts (
    account_id TEXT PRIMARY KEY,
    account_name TEXT,
    industry TEXT,
    country TEXT,
    signup_date DATE,
    referral_source TEXT,
    plan_tier TEXT,
    seats INT,
    is_trial BOOLEAN,
    churn_flag BOOLEAN
);

-- ===========================
-- 2.  subscriptions Table
-- ===========================
CREATE TABLE subscriptions (
    subscription_id TEXT PRIMARY KEY,
    account_id TEXT REFERENCES accounts(account_id),
    start_date DATE NOT NULL,
    end_date DATE,
    plan_tier TEXT,
    seats INT,
    mrr_amount NUMERIC(12,2),   
    arr_amount NUMERIC(12,2),   
    is_trial BOOLEAN,
    upgrade_flag BOOLEAN,
    downgrade_flag BOOLEAN,
    churn_flag BOOLEAN,
    billing_frequency TEXT,     
    auto_renew_flag BOOLEAN
);

-- ===========================
-- 3. feature_usage Table
-- ===========================
CREATE TABLE feature_usage (
    usage_id TEXT PRIMARY KEY,
    subscription_id TEXT REFERENCES subscriptions(subscription_id),
    usage_date DATE NOT NULL,
    feature_name TEXT,
    usage_count INT,
    usage_duration_secs INT,
    error_count INT,
    is_beta_feature BOOLEAN
);

-- ===========================
-- 4. support_tickets Table
-- ===========================
CREATE TABLE support_tickets (
    ticket_id TEXT PRIMARY KEY,
    account_id TEXT REFERENCES accounts(account_id),
    submitted_at TIMESTAMP NOT NULL,
    closed_at TIMESTAMP,
    resolution_time_hours REAL,
    priority TEXT,                       
    first_response_time_minutes INT,
    satisfaction_score INT,             
    escalation_flag BOOLEAN
);


-- ===========================
-- 5. churn_events Table
-- ===========================
CREATE TABLE churn_events (
    churn_event_id TEXT PRIMARY KEY,
    account_id TEXT REFERENCES accounts(account_id),
    churn_date DATE NOT NULL,
    reason_code TEXT,                
    refund_amount_usd NUMERIC(12,2), 
    preceding_upgrade_flag BOOLEAN,
    preceding_downgrade_flag BOOLEAN,
    is_reactivation BOOLEAN,
    feedback_text TEXT
);
-- ===========================
-- Data validation revealed usage_id is not unique despite documentation; 
--using SERIAL surrogate key to maintain data integrity
-- ===========================
ALTER TABLE feature_usage DROP CONSTRAINT feature_usage_pkey;

ALTER TABLE feature_usage ADD COLUMN id SERIAL PRIMARY KEY;

-- ===========================
-- checking any missing data through import (checking these numbers with kaggle)
--found differed count with feature_usage table. Kaggle(24979) and we have 25000
-- ===========================
SELECT 
    (SELECT COUNT(*) FROM accounts) as total_accounts,
    (SELECT COUNT(*) FROM subscriptions) as total_subscriptions,
    (SELECT COUNT(*) FROM feature_usage) as total_usage_rows,
	(SELECT COUNT(*) FROM churn_events) as total_churn_rows,
	(SELECT COUNT(*) FROM support_tickets) as total_supportTickets_rows;
	

-- ===========================
-- fetching the duplicates
-- ===========================
Select * from feature_usage
where usage_id in (SELECT usage_id
FROM feature_usage
GROUP BY usage_id
HAVING COUNT(*) > 1)
order by usage_id ASC;

-- ===========================
--Logical Date Validation
--In SaaS, time is the independent variable. If your dates are illogical, 
--your Churn and LTV calculations will break.
-- output is clean, so all good 
-- ===========================
-- Finding "Time Travelers" 
SELECT subscription_id, start_date, end_date
FROM subscriptions
WHERE end_date < start_date;

-- Finding tickets closed before they opened
SELECT ticket_id, submitted_at, closed_at
FROM support_tickets
WHERE closed_at < submitted_at;

-- ===========================

-- ===========================

-- CHECK 3: Usage recorded before the account signed up ( got 1000 such records)
SELECT f.usage_id, f.usage_date, a.signup_date
FROM feature_usage f
JOIN subscriptions s ON f.subscription_id = s.subscription_id
JOIN accounts a ON s.account_id = a.account_id
WHERE f.usage_date < a.signup_date;
  
   
   
-- ===========================
-- making sure if the duplicates are actual duplicates or id collision using md5 function
-- this compresses the row values as hash/string for each row and you compare the strings/hashes
--since all are id collisions, decided to keep all the data as we have used sorrogated primary key(serial id)
--now each row is unique.
-- ===========================
SELECT
    usage_id,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT md5(CAST((subscription_id, usage_date, feature_name, usage_count, 
						   usage_duration_secs, error_count,is_beta_feature, id)AS TEXT))) AS distinct_hashes,
    CASE
        WHEN COUNT(DISTINCT md5(CAST((usage_date, feature_name, subscription_id, usage_count) AS TEXT))) = 1
        THEN 'Exact duplicate'
        ELSE 'ID collision'
    END AS duplicate_type
FROM feature_usage
GROUP BY usage_id
HAVING COUNT(*) > 1
ORDER BY duplicate_type, usage_id;  

-- Are the violations clustered around a specific date?
SELECT 
    DATE_TRUNC('month', a.signup_date) AS signup_month,
    COUNT(*) AS violation_count
FROM feature_usage f
JOIN subscriptions s ON f.subscription_id = s.subscription_id
JOIN accounts a ON s.account_id = a.account_id
WHERE f.usage_date < a.signup_date
GROUP BY 1
ORDER BY violation_count DESC;

-- Check the time gap between usage and signup
-- to understand if it's seconds (clock skew) 
-- or days/months (trial usage or migration)
-- 77.8% usage 90+days before sigh up is unbelivably high
SELECT
    CASE
        WHEN (a.signup_date - f.usage_date) < 1
            THEN '< 1 day'
        WHEN (a.signup_date - f.usage_date) < 7
            THEN '1–7 days'
        WHEN (a.signup_date - f.usage_date) < 30
            THEN '7–30 days'
        WHEN (a.signup_date - f.usage_date) < 90
            THEN '30–90 days'
        ELSE '90+ days'
    END AS gap_bucket,
    COUNT(*) AS records,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM feature_usage f
JOIN subscriptions s ON f.subscription_id = s.subscription_id
JOIN accounts a ON s.account_id = a.account_id
WHERE f.usage_date < a.signup_date
GROUP BY 1
ORDER BY MIN(a.signup_date - f.usage_date);

-- avg gap days
SELECT
    DATE_TRUNC('month', a.signup_date) AS signup_month,
    COUNT(DISTINCT a.account_id) AS accounts,
    MIN(f.usage_date) AS earliest_usage,
    MAX(f.usage_date) AS latest_usage,
    ROUND(AVG(a.signup_date - f.usage_date)) AS avg_gap_days
FROM feature_usage f
JOIN subscriptions s ON f.subscription_id = s.subscription_id
JOIN accounts a ON s.account_id = a.account_id
WHERE f.usage_date < a.signup_date
GROUP BY 1
ORDER BY 1 DESC;

--490 are corrupted out of 500 accounts, so drop the dataset and get a newone
WITH affected AS (
    SELECT DISTINCT a.account_id
    FROM feature_usage f
    JOIN subscriptions s ON f.subscription_id = s.subscription_id
    JOIN accounts a ON s.account_id = a.account_id
    WHERE f.usage_date < a.signup_date
)
SELECT
    CASE 
        WHEN a.account_id IN (SELECT account_id FROM affected)
        THEN 'Affected accounts'
        ELSE 'Clean accounts'
    END AS account_group,
    COUNT(*) AS total_accounts,
    MIN(a.signup_date) AS earliest_signup,
    MAX(a.signup_date) AS latest_signup,
    -- Cast date to epoch, average it, cast back to date
    TO_TIMESTAMP(
        AVG(EXTRACT(EPOCH FROM a.signup_date::timestamptz))
    )::date AS avg_signup_date
FROM accounts a
GROUP BY 1;

   
---13198 usage recrods predated to account signup  
SELECT 
    f.usage_id, 
    f.usage_date, 
    a.signup_date,
    (a.signup_date - f.usage_date) AS lead_time_days
FROM feature_usage f
JOIN subscriptions s ON f.subscription_id = s.subscription_id
JOIN accounts a ON s.account_id = a.account_id
WHERE f.usage_date < a.signup_date
ORDER BY lead_time_days DESC;

-- CHECK 4: Subscriptions starting before account signup
SELECT s.subscription_id, s.start_date, a.signup_date
FROM subscriptions s
JOIN accounts a ON s.account_id = a.account_id
WHERE s.start_date < a.signup_date;

-- CHECK 5: Churning before signing up (Mathematical impossibility)
SELECT c.account_id, c.churn_date, a.signup_date
FROM churn_events c
JOIN accounts a ON c.account_id = a.account_id
WHERE c.churn_date < a.signup_date;

-- ===========================
--Total customers - 500
-- ===========================
select count(distinct(account_id))
from accounts;

-- ===========================
--Write a query to find the total number of active (non-churned) accounts by plan_tier and industry. 
--Include the average number of seats per tier.
-- ===========================
select  plan_tier,count(*) as active, round(avg(seats),0) as avgSeats
from accounts
where churn_flag = false
group by plan_tier
order by plan_tier;

-- ===========================
--Calculate the overall MRR (sum of mrr_amount) and ARR (sum of arr_amount) 
--for all paying customers (is_trial = FALSE) who are currently active (churn_flag = FALSE)
--FM removes leading blank spaces, and Extra groups of 999, allow for billions or even trillions of MRR.
-- ===========================

select to_char(sum(mrr_amount), 'FM$999,999,999,999,999.00')as MRR, 
	   to_char(sum(arr_amount), 'FM$999,999,999,999,999.00') as ARR,
	   count(*) as active_paying_accounts
from subscriptions
where is_trial = false 
	and churn_flag = false;
	













