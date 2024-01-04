SELECT
    count(*) as rec_cnt
from {{ source('thelook_ecommerce', 'users')}}