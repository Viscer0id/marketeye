/*
-- Backout Script

-- NDS Schema
DROP VIEW nds.trade_summary;
DROP VIEW nds.trade_stats;
 */

create or replace view nds.trade_stats as
SELECT
  trade_direction,
  exchange_name,
  symbol,
  entry_date,
  exit_date,
  entry_price,
  exit_price,
  days_in_trade,
  (exit_price - entry_price) AS profit,
  trade_commentary
FROM
  nds.trade_pair
ORDER BY
  exchange_name
  , symbol
  , trade_direction
  , entry_date;

create or replace view nds.trade_summary as
with stats1 as
(
    select
    exchange_name
  , symbol
  , trade_direction
  , sum(profit) AS total_profit
  , COUNT(CASE WHEN sign(profit) >= 0 THEN 1 END) as count_profit
  , COUNT(CASE WHEN sign(profit) <0 THEN 1 END) as count_loss
  , SUM(CASE WHEN sign(profit) >= 0 THEN profit END ) AS sum_profit
  , SUM(CASE WHEN sign(profit) < 0 THEN profit END ) AS sum_loss
  , round(avg(days_in_trade), 0) AS avg_days_in_trade
  FROM nds.trade_stats
  GROUP BY
    exchange_name
  , symbol
  , trade_direction
)
select
  exchange_name
  ,symbol
  ,trade_direction
  ,count_profit
  ,count_loss
  ,CASE
    WHEN count_profit <= count_loss THEN '1 : '||round(cast(count_loss as numeric)/cast(count_profit as numeric),1)
    WHEN count_profit > count_loss THEN round(cast(count_profit as numeric)/cast(count_loss as numeric),1)||' : 1'
  END as approx_pl_trade_ratio
  ,avg_days_in_trade
  ,sum_profit
  ,sum_loss
  ,total_profit
from stats1
order by
  total_profit;