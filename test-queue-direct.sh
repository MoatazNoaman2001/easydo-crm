#!/bin/bash

CAMPAIGN_ID="bd5eaecc-5693-4fa3-8f15-02bccc0ccc9a"

echo "Testing campaign queue execution directly via SQL..."
echo ""

ssh easydo-whatsapp "PGPASSWORD='averystrongpassword@098123' psql -h 127.0.0.1 -U ubuntu -d whatsappflow" <<EOF
-- Test the GET_CAMPAIGN_RECIPIENTS_FOR_QUEUE query
SELECT 
    phone_number,
    customer_name,
    message_status_id
FROM (
    WITH campaign_data AS (
        SELECT 
            c.id as campaign_id,
            c.phone_numbers,
            c.group_id,
            c.template_name,
            c.template_code,
            c.template_params
        FROM campaigns c
        WHERE c.id = '${CAMPAIGN_ID}'
    ),
    all_recipients AS (
        SELECT DISTINCT
            cd.campaign_id,
            cms.id as message_status_id,
            COALESCE(cms.phone_number, phone_list.mobile_number, group_cust.mobile_number) as phone_number,
            cd.template_name,
            cd.template_code,
            cd.template_params
        FROM campaign_data cd
        LEFT JOIN campaign_message_status cms ON cms.campaign_id = cd.campaign_id
        LEFT JOIN LATERAL UNNEST(cd.phone_numbers) AS phone_list(mobile_number) ON cd.phone_numbers IS NOT NULL
        LEFT JOIN customers group_cust ON group_cust.gid = cd.group_id
        WHERE COALESCE(cms.phone_number, phone_list.mobile_number, group_cust.mobile_number) IS NOT NULL
    )
    SELECT 
        ar.campaign_id,
        ar.message_status_id,
        ar.phone_number,
        cust.user_name as customer_name,
        ar.template_name,
        ar.template_code,
        ar.template_params
    FROM all_recipients ar
    LEFT JOIN customers cust ON cust.mobile_number = ar.phone_number
) AS recipients
LIMIT 5;
EOF

echo ""
echo "Checking Redis queue stats..."
ssh easydo-whatsapp "redis-cli INFO keyspace"

echo ""
echo "Done!"

