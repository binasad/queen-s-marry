-- Query appointments for specific user
SELECT 
  a.id,
  a.customer_name,
  a.customer_email,
  a.customer_phone,
  a.appointment_date,
  a.appointment_time,
  a.status,
  s.name as service_name,
  a.created_at,
  a.total_price,
  a.payment_status
FROM appointments a
LEFT JOIN services s ON a.service_id = s.id
WHERE a.customer_email = 'saadaztrosys03@gmail.com' OR a.user_id IN (
  SELECT id FROM users WHERE email = 'saadaztrosys03@gmail.com'
)
ORDER BY a.created_at DESC;
