use Airbnb_Sandbox_p3
select * from nyc_airbnb_listings

--1. Total active listings audit
select count(*) as total_active_listings
from nyc_airbnb_listings

-- 2. Five distinct NYC boroughs
select distinct neighbourhood_group 
from nyc_airbnb_listings
order by neighbourhood_group;

--3. Audit zero-price data errors
select count(*) as zero_price_records
from nyc_airbnb_listings
where price <= 0;


/*
===========================================================================================
PROJECT 3: NYC Airbnb Investment Yield & Neighborhood Opportunity Engine
AUTHOR: Naman Bhati
DATE: 04/10/2026
DATABASE: Airbnb_Sandbox
===========================================================================================
*/

with clean_nyc_listings as (
 select id, 
        name,
        neighbourhood_group,
        neighbourhood,
        room_type,
        price,
        minimum_nights,
        number_of_reviews,
        reviews_per_month,
        availability_365,
 -- Proxy Revenue Engine: Price * Estimated Occupied Days
        (price * (365 - availability_365)) as estimated_annual_revenue
from nyc_airbnb_listings
where price > 0
      AND availability_365 > 0 
      AND availability_365 < 365
),
Neighbourhood_performance as (
    select neighbourhood_group,
           neighbourhood,
           count(*) as total_active_listings,
           Round(Avg(Cast(price as float)),2) as average_nightly_price,
           Round(Avg(Cast(Coalesce(reviews_per_month, 0) as float)), 2) as average_monthly_review_velocity,
           Round(Avg(Cast(estimated_annual_revenue as float)), 2) as average_proxy_annual_revenue
    from clean_nyc_listings
    group by neighbourhood_group,
              neighbourhood
    having count(*) > 50   -- Filters out low-sample statistical noise
)
Select DENSE_RANK() over (Order By average_proxy_annual_revenue DESC) as revenue_rank,
       neighbourhood_group,
       neighbourhood,
       total_active_listings,
       average_nightly_price,
       average_monthly_review_velocity,
       average_proxy_annual_revenue
From Neighbourhood_performance
Order By revenue_rank ASC




-- The most profitable room type.

with clean_nyc_listings as (
 select id, 
        name,
        neighbourhood_group,
        neighbourhood,
        room_type,
        price,
        minimum_nights,
        number_of_reviews,
        reviews_per_month,
        availability_365,
 -- Proxy Revenue Engine: Price * Estimated Occupied Days
        (price * (365 - availability_365)) as estimated_annual_revenue
from nyc_airbnb_listings
where price > 0
      AND availability_365 > 0 
      AND availability_365 < 365
),
room_type_performance as (
    select room_type,
           count(*) as total_active_listings,
           Round(Avg(Cast(price as float)),2) as average_nightly_price,
           Round(Avg(Cast(Coalesce(reviews_per_month, 0) as float)), 2) as average_monthly_review_velocity,
           Round(Avg(Cast(estimated_annual_revenue as float)), 2) as average_proxy_annual_revenue
    from clean_nyc_listings
    group by room_type
    having count(*) > 50   -- Filters out low-sample statistical noise
)
Select room_type,
       total_active_listings,
       average_nightly_price,
       average_monthly_review_velocity,
       average_proxy_annual_revenue
From room_type_performance
order by average_proxy_annual_revenue desc;

