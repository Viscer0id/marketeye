INSERT INTO nds.exchange VALUES ('ASX','Australian Securities Exchange');

INSERT INTO nds.symbol (exchange_name, symbol)
  SELECT DISTINCT exchange_name, symbol FROM stg.symbol_data;

INSERT INTO nds.symbol_data
  WITH base AS
  (
  SELECT
    exchange_name
    ,symbol
    ,TO_DATE(trade_date,'YYYYMMDD') AS trade_date
    ,open_price
    ,high_price
    ,low_price
    ,close_price
    ,volume
    ,TO_DATE(lag(trade_date, 1) over (partition by exchange_name, symbol ORDER BY trade_date),'YYYYMMDD') prior1_trade_date
    ,lag(high_price, 1) over (partition by exchange_name, symbol ORDER BY trade_date) prior1_high_price
    ,lag(low_price, 1) over (partition by exchange_name, symbol ORDER BY trade_date) prior1_low_price
    ,lag(high_price, 2) over (partition by exchange_name, symbol ORDER BY trade_date) prior2_high_price
    ,lag(low_price, 2) over (partition by exchange_name, symbol ORDER BY trade_date) prior2_low_price
    ,lag(high_price, 3) over (partition by exchange_name, symbol ORDER BY trade_date) prior3_high_price
    ,lag(low_price, 3) over (partition by exchange_name, symbol ORDER BY trade_date) prior3_low_price
    ,TO_DATE(lead(trade_date, 1) over (partition by exchange_name, symbol ORDER BY trade_date),'YYYYMMDD') next1_trade_date
    ,lead(open_price, 1) over (partition by exchange_name, symbol ORDER BY trade_date) next1_open_price
    ,AVG(close_price) OVER (partition by exchange_name, symbol ORDER BY trade_date ROWS BETWEEN 15 PRECEDING AND CURRENT ROW) SMA_15
    ,AVG(close_price) OVER (partition by exchange_name, symbol ORDER BY trade_date ROWS BETWEEN 50 PRECEDING AND CURRENT ROW) SMA_50
    ,MAX(high_price) OVER  (partition by exchange_name, symbol ORDER BY trade_date ROWS BETWEEN 31 PRECEDING AND 1 PRECEDING ) DONCHIAN_30_HIGH
    ,MIN(low_price) OVER  (partition by exchange_name, symbol ORDER BY trade_date ROWS BETWEEN 31 PRECEDING AND 1 PRECEDING) DONCHIAN_30_LOW
  FROM
    stg.symbol_data
  ),
  base_bartype AS
  (
  SELECT
    b.*
    ,SIGN(b.SMA_15-b.SMA_50) as SMA_15_50_change
    ,CASE
      WHEN (b.high_price > b.DONCHIAN_30_HIGH) THEN 'UPTREND'
      WHEN (b.low_price < b.DONCHIAN_30_LOW) THEN 'DOWNTREND'
    END AS donchian_channel_30
    ,CASE
      WHEN (b.high_price > b.prior1_high_price) AND (b.low_price >= b.prior1_low_price) THEN 'UP'
      WHEN (b.high_price <= b.prior1_high_price) AND (b.low_price < b.prior1_low_price) THEN 'DOWN'
      WHEN (b.high_price <= b.prior1_high_price) AND (b.low_price >= b.prior1_low_price) THEN 'INSIDE'
      WHEN (b.high_price > b.prior1_high_price) AND (b.low_price < b.prior1_low_price) THEN 'OUTSIDE'
    END AS bar_type
  FROM base b
  ),
  base_bartype_lag AS
  (
  SELECT
    bb.*
    ,lag(SMA_15_50_change, 1) over (partition by exchange_name, symbol ORDER BY trade_date) prior1_SMA_15_50_change
    ,lag(bar_type, 1) over (partition by exchange_name, symbol ORDER BY trade_date) prior1_bar_type
  FROM
    base_bartype bb
  ),
  base_bartype_lag_peak_trough_gann_swing AS
  (
  SELECT
    bbl.*
    ,CASE
      WHEN (bbl.SMA_15_50_change <> prior1_SMA_15_50_change) THEN TRUE
      ELSE FALSE
    END AS sma_15_50_crossover
    ,CASE
      WHEN (bbl.bar_type='DOWN') AND ((bbl.prior1_bar_type='UP') OR (bbl.prior1_bar_type ='OUTSIDE')) THEN 'PEAK'
      WHEN (bbl.bar_type='UP') AND ((bbl.prior1_bar_type='DOWN') OR (bbl.prior1_bar_type ='OUTSIDE')) THEN 'TROUGH'
    END AS trend_peak_trough
    ,CASE
      WHEN (bbl.high_price>bbl.prior1_high_price) AND (bbl.prior1_high_price>bbl.prior2_high_price) THEN 'UPSWING'
      WHEN (bbl.low_price<bbl.prior1_low_price) AND (bbl.prior1_low_price<bbl.prior2_low_price) THEN 'DOWNSWING'
    END AS trend_gann_2day_swing
    ,CASE
      WHEN (bbl.high_price>bbl.prior1_high_price) AND (bbl.prior1_high_price>bbl.prior2_high_price) AND (bbl.prior2_high_price>bbl.prior3_high_price) THEN 'UPSWING'
      WHEN (bbl.low_price<bbl.prior1_low_price) AND (bbl.prior1_low_price<bbl.prior2_low_price) AND (bbl.prior2_low_price<bbl.prior3_low_price) THEN 'DOWNSWING'
    END AS trend_gann_3day_swing
  FROM
    base_bartype_lag bbl
  )
   SELECT * FROM base_bartype_lag_peak_trough_gann_swing;

