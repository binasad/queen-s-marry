-- Query appointments with service details
SELECT 
  a.id,
  a.customer_name,
  a.customer_email,
  a.customer_phone,
  a.appointment_date,
  a.appointment_time,
  a.status,
  s.name as service_name,
  a.created_at
FROM appointments a
LEFT JOIN services s ON a.service_id = s.id
ORDER BY a.created_at DESC
LIMIT 50;
