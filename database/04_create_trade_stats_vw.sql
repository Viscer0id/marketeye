/*
-- Backout Script

-- NDS Schema
DROP VIEW nds.trade_summary;
DROP VIEW nds.trade_stats;
 */

create or replace view nds.trade_stats as
SELECT
  system_id,
  trade_direction,
  exchange_name,
  symbol,
  entry_date,
  exit_date,
  entry_price,
  exit_price,
  days_in_trade,
  CASE
    WHEN trade_direction = 'LONG' THEN (exit_price - entry_price)
    WHEN trade_direction = 'SHORT' THEN (entry_price - exit_price)
  END AS profit,
  trade_commentary
FROM
  nds.trade_pair
ORDER BY
  system_id
  , exchange_name
  , symbol
  , trade_direction
  , entry_date;

create or replace view nds.trade_summary as
with stats1 as
(
  select
    system_id
    , exchange_name
    , symbol
    , trade_direction
    , sum(profit) AS total_position
    , COUNT(CASE WHEN sign(profit) >= 0 THEN 1 END) as count_profit
    , COUNT(CASE WHEN sign(profit) <0 THEN 1 END) as count_loss
    , SUM(CASE WHEN sign(profit) >= 0 THEN profit END ) AS sum_profit
    , SUM(CASE WHEN sign(profit) < 0 THEN profit END ) AS sum_loss
    , round(avg(days_in_trade), 0) AS avg_days_in_trade
  FROM nds.trade_stats
  GROUP BY
    system_id
    , exchange_name
  , symbol
  , trade_direction
)
select
  system_id
  ,exchange_name
  ,symbol
  ,trade_direction
  ,count_profit
  ,count_loss
  ,CASE
    WHEN (count_profit <> 0 and count_loss <> 0 and count_profit <= count_loss) THEN '1 : '||round(cast(count_loss as numeric)/cast(count_profit as numeric),1)
    WHEN (count_profit <> 0 and count_loss <> 0 and count_profit > count_loss) THEN round(cast(count_profit as numeric)/cast(count_loss as numeric),1)||' : 1'
    ELSE NULL
  END as approx_pl_trade_ratio
  ,avg_days_in_trade
  ,sum_profit
  ,sum_loss
  ,total_position
from stats1
order by
  total_position DESC;