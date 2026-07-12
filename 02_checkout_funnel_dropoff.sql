WITH session_funnel AS (
    SELECT 
        session_id,
        device_type,
        MAX(CASE WHEN event_name = 'app_open' THEN 1 ELSE 0 END) AS step_1_open,
        MAX(CASE WHEN event_name = 'product_view' THEN 1 ELSE 0 END) AS step_2_view,
        MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS step_3_cart,
        MAX(CASE WHEN event_name = 'checkout_initiated' THEN 1 ELSE 0 END) AS step_4_checkout,
        MAX(CASE WHEN event_name = 'payment_success' THEN 1 ELSE 0 END) AS step_5_success
    FROM blinkit_clickstream_logs
    WHERE event_timestamp >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 1, 2
),
 
funnel_totals AS (
    SELECT
        device_type,
        SUM(step_1_open) AS homepage_opens,
        SUM(step_2_view) AS product_views,
        SUM(step_3_cart) AS cart_adds,
        SUM(step_4_checkout) AS checkout_starts,
        SUM(step_5_success) AS orders_completed
    FROM session_funnel
    GROUP BY 1
)

 
SELECT
    device_type,
    homepage_opens AS total_traffic,
    
 
    ROUND((product_views::NUMERIC / homepage_opens) * 100, 2) AS open_to_view_pct,
    ROUND((cart_adds::NUMERIC / homepage_opens) * 100, 2) AS open_to_cart_pct,
    ROUND((orders_completed::NUMERIC / homepage_opens) * 100, 2) AS overall_cr_pct,

    
    ROUND((1 - (checkout_starts::NUMERIC / NULLIF(cart_adds, 0))) * 100, 2) AS cart_abandonment_rate,
    ROUND((1 - (orders_completed::NUMERIC / NULLIF(checkout_starts, 0))) * 100, 2) AS payment_dropoff_rate
FROM funnel_totals
ORDER BY total_traffic DESC;
