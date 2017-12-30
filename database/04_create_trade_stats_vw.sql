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
  JOIN nds.trade_system on trade_pair.system_id = trade_system.system_id
ORDER BY
  exchange_name
  , symbol
  , entry_date;

create or replace view nds.trade_summary as
select
  exchange_name
  ,symbol
  ,sum(profit) AS profit
  ,round(avg(days_in_trade),0) as avg_days_in_trade
from nds.trade_stats
group BY
  exchange_name
  ,symbol
HAVING
  sum(profit) > 0
order BY
  sum(profit) desc;