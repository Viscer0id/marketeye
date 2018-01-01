INSERT INTO nds.exchange VALUES ('ASX','Australian Securities Exchange');

INSERT INTO nds.symbol (exchange_name, symbol)
  SELECT DISTINCT exchange_name, symbol FROM stg.symbol_data;

INSERT INTO nds.symbol_data
  WITH base_0 AS
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
    ,high_price - low_price SPREAD
    ,AVG(high_price - low_price) OVER  (partition by exchange_name, symbol ORDER BY trade_date ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) MOV30AVG_SPREAD
    ,STDDEV(high_price - low_price) OVER  (partition by exchange_name, symbol ORDER BY trade_date ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) MOV30STD_SPREAD
    ,AVG(volume)  OVER  (partition by exchange_name, symbol ORDER BY trade_date ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) MOV30AVG_VOLUME
    ,STDDEV(volume) OVER  (partition by exchange_name, symbol ORDER BY trade_date ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) MOV30STD_VOLUME
    ,low_price + ((high_price - low_price)/3) LOWER_THIRD
    ,high_price - ((high_price - low_price)/3) UPPER_THIRD
    ,low_price + ((high_price - low_price)/2) MID_POINT
  FROM
    stg.symbol_data
  ),
    base_1 AS
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
    ,(b.SPREAD - b.MOV30AVG_SPREAD)/NULLIF(b.MOV30STD_SPREAD,0) AS MOV30_SPREAD_Z_SCORE
    ,(b.VOLUME -b.MOV30AVG_VOLUME)/NULLIF(b.MOV30STD_VOLUME,0) AS MOV30_VOLUME_Z_SCORE
  FROM base_0 b
  ),
    base_2 as
  (
  SELECT
    b1.*
    ,lag(SMA_15_50_change, 1) over (partition by exchange_name, symbol ORDER BY trade_date) prior1_SMA_15_50_change
    ,lag(bar_type, 1) over (partition by exchange_name, symbol ORDER BY trade_date) prior1_bar_type
  FROM
    base_1 b1
  ),
  base_3 AS
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
    base_2 bbl
  )
    SELECT
      exchange_name,
      symbol,
      trade_date,
      open_price,
      high_price,
      low_price,
      close_price,
      volume,
      prior1_trade_date,
      prior1_high_price,
      prior1_low_price,
      prior2_high_price,
      prior2_low_price,
      prior3_high_price,
      prior3_low_price,
      next1_trade_date,
      next1_open_price,
      sma_15,
      sma_50,
      donchian_30_high,
      donchian_30_low,
      sma_15_50_change,
      donchian_channel_30,
      bar_type,
      prior1_sma_15_50_change,
      prior1_bar_type,
      sma_15_50_crossover,
      trend_peak_trough,
      trend_gann_2day_swing,
      trend_gann_3day_swing,
      spread,
      mov30avg_spread,
      mov30std_spread,
      mov30avg_volume,
      mov30std_volume,
      mov30_spread_z_score,
      mov30_volume_z_score,
      lower_third,
      upper_third,
      mid_point
    FROM base_3;