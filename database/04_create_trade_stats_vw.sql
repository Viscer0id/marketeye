/*
-- Backout Script

-- NDS Schema
DROP VIEW nds.trade_summary;
DROP VIEW nds.trade_stats;
 */

create or replace view nds.trade_stats as
SELECT
  exchange_name,
  symbol,
  entry_date,
  exit_date,
  entry_price,
  exit_price,
  (exit_price - entry_price) AS profit,
  trade_commentary
FROM
  nds.trade_pair
ORDER BY
  exchange_name
  , symbol
  , entry_date;

create or replace view nds.trade_summary as
select
  exchange_name
  ,symbol
  ,sum(profit) AS profit
from nds.trade_stats
group BY
  exchange_name
  ,symbol
HAVING
  sum(profit) > 0
order BY
  sum(profit) desc;