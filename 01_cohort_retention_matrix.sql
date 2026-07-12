WITH user_cohorts AS (
    SELECT 
        user_id,
        DATE_TRUNC('week', MIN(order_date))::DATE AS onboarding_week
    FROM blinkit_orders
    GROUP BY 1
),

 
weekly_user_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('week', order_date)::DATE AS active_week,
        SUM(order_amount) AS total_weekly_spend
    FROM blinkit_orders
    GROUP BY 1, 2
),

 
cohort_sizes AS (
    SELECT 
        onboarding_week,
        COUNT(DISTINCT user_id) AS total_users_w0
    FROM user_cohorts
    GROUP BY 1
)

 
SELECT
    uc.onboarding_week,
    cs.total_users_w0,
   
    FLOOR(EXTRACT(DAY FROM (wa.active_week - uc.onboarding_week)) / 7)::INT AS week_index,
    COUNT(DISTINCT wa.user_id) AS active_users_count,
     ROUND((COUNT(DISTINCT wa.user_id)::NUMERIC / cs.total_users_w0) * 100, 2) AS retention_rate_pct,
    ROUND(SUM(wa.total_weekly_spend)::NUMERIC, 2) AS revenue_retained
FROM user_cohorts uc
JOIN weekly_user_activity wa ON uc.user_id = wa.user_id
JOIN cohort_sizes cs ON uc.onboarding_week = cs.onboarding_week
WHERE wa.active_week >= uc.onboarding_week
GROUP BY 1, 2, 3, cs.total_users_w0
HAVING FLOOR(EXTRACT(DAY FROM (wa.active_week - uc.onboarding_week)) / 7) <= 8
ORDER BY onboarding_week DESC, week_index ASC;
