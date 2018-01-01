/*
-- Backout Script

DROP FUNCTION nds.getTrailingStopValue;
DROP FUNCTION nds.getProtectiveStopValue;
DROP FUNCTION nds.activeTrade;
DROP FUNCTION nds.commentaryPrintln(text,date,text);
DROP FUNCTION nds.getDaysInTradeCount(date,date,varchar,varchar);
*/

CREATE OR REPLACE FUNCTION nds.getTrailingStopValue(IN inTradeDirection VARCHAR, IN inExchangeName VARCHAR, IN inSymbol VARCHAR, IN inTradeDate DATE, IN inDaysInTrade INT) RETURNS FLOAT
AS
$$
DECLARE
  trailStopLongCur NO SCROLL CURSOR (inExchangeName VARCHAR, inSymbol VARCHAR, inTradeDate DATE, inLookBack INTEGER) FOR select (min(low_price)) from nds.symbol_data where exchange_name = inExchangeName and symbol = inSymbol and trade_date <= inTradeDate and trade_date >= (inTradeDate - inLookBack) group by exchange_name, symbol;
  trailStopShortCur NO SCROLL CURSOR (inExchangeName VARCHAR, inSymbol VARCHAR, inTradeDate DATE, inLookBack INTEGER) FOR select (max(high_price)) from nds.symbol_data where exchange_name = inExchangeName and symbol = inSymbol and trade_date <= inTradeDate and trade_date >= (inTradeDate - inLookBack) group by exchange_name, symbol;
  trailingStop FLOAT := 0.0;
  inLookBack INT := 30;
BEGIN

  inLookBack := inLookBack - 2*FLOOR(inDaysInTrade/5); -- For every 5 days in a trade, decrease the number of lookback days by 2

  IF inLookBack < 6 THEN -- Never let the lookback days go lower than 6
    inLookBack := 6;
  END IF;

  IF inTradeDirection = 'LONG' THEN
    OPEN trailStopLongCur(inExchangeName, inSymbol, inTradeDate, inLookBack);
    FETCH trailStopLongCur INTO trailingStop;
    CLOSE trailStopLongCur;
  END IF;

  IF inTradeDirection = 'SHORT' THEN
    OPEN trailStopShortCur(inExchangeName, inSymbol, inTradeDate, inLookBack);
    FETCH trailStopShortCur INTO trailingStop;
    CLOSE trailStopShortCur;
  END IF;

  IF trailingStop IS NULL THEN
    RAISE EXCEPTION 'trailingStop returned NULL';
  ELSE
    RETURN trailingStop;
  END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION nds.getProtectiveStopValue(IN inExchangeName VARCHAR, IN inSymbol VARCHAR, IN inTradeDate DATE, IN inLookBack INT) RETURNS FLOAT
AS
$$
DECLARE
  protectStopCur NO SCROLL CURSOR (inExchangeName VARCHAR, inSymbol VARCHAR, inTradeDate DATE, inLookBack INTEGER) FOR select (max(high_price) - min(low_price)) / 2 + min(low_price) from nds.symbol_data where exchange_name = inExchangeName and symbol = inSymbol and trade_date <= inTradeDate and trade_date >= (inTradeDate - inLookBack) group by exchange_name, symbol;
  protectiveStop FLOAT := 0.0;
BEGIN
  OPEN protectStopCur(inExchangeName, inSymbol, inTradeDate, inLookBack);
  FETCH protectStopCur INTO protectiveStop;
  CLOSE protectStopCur;

  IF protectiveStop IS NULL THEN
    RAISE EXCEPTION 'protectiveStop returned NULL';
  ELSE
    RETURN protectiveStop;
  END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION nds.activeTrade(IN inExchangeName VARCHAR, IN inSymbol VARCHAR, IN inEntryDate DATE) RETURNS BOOLEAN
AS
$$
DECLARE
  exitDate DATE := NULL;
  tradePairCur NO SCROLL CURSOR FOR select exit_date from nds.trade_pair where exchange_name = inExchangeName and symbol = inSymbol and entry_date = inEntryDate;
BEGIN
  OPEN tradePairCur;
  FETCH tradePairCur INTO exitDate;
  CLOSE tradePairCur;

  IF exitDate IS NULL THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION nds.commentaryPrintln(IN inCommentaryText TEXT, IN inDATE DATE, IN inNewText TEXT) RETURNS TEXT
AS
$$
DECLARE
BEGIN
  inCommentaryText := inCommentaryText||TO_CHAR(inDate,'DD-MON-YYYY')||': '||inNewText||E'\r\n';
  RETURN inCommentaryText;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION nds.getDaysInTradeCount(IN inFromDate DATE, IN inToDate DATE, IN inExchangeName VARCHAR, IN inSymbol VARCHAR) RETURNS INT
AS
$$
DECLARE
  daysCount INT := NULL;
  daysCountCur NO SCROLL CURSOR FOR select count(*) from nds.symbol_data where exchange_name = inExchangeName and symbol = inSymbol and trade_date >= inFromDate and trade_date <= inToDate;
BEGIN
  OPEN daysCountCur;
  FETCH daysCountCur INTO daysCount;
  CLOSE daysCountCur;

  IF daysCount IS NULL THEN
    RAISE EXCEPTION 'getDaysInTradeCount returned NULL';
  ELSE
    RETURN daysCount;
  END IF;

END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION nds.isStopExitTriggered(IN inTradeDirection VARCHAR(5), IN inExchangeName VARCHAR, IN inSymbol VARCHAR, IN inTradeDate DATE, IN inStopValue REAL) RETURNS BOOLEAN
AS
$$
DECLARE
  symbolDataCur NO SCROLL CURSOR FOR select * from nds.symbol_data where exchange_name = inExchangeName and symbol = inSymbol and trade_date = inTradeDate;
  symbolDataRec nds.symbol_data%ROWTYPE;
BEGIN
  OPEN symbolDataCur;
  FETCH symbolDataCur INTO symbolDataRec;
  CLOSE symbolDataCur;

  IF inTradeDirection = 'LONG' THEN
    -- Trigger when the lowest price of the day is equal to or less than the stop value
    IF symbolDataRec.low_price <= inStopValue THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;

  ELSEIF inTradeDirection = 'SHORT' THEN
    -- Trigger when the highest price of the day is equal to or higher than the stop value
    IF symbolDataRec.high_price >= inStopValue THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;

  END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION nds.getStopExitValue(IN inTradeDirection VARCHAR(5), IN inExchangeName VARCHAR, IN inSymbol VARCHAR, IN inTradeDate DATE, IN inStopValue REAL) RETURNS REAL
AS
$$
DECLARE
  symbolDataCur NO SCROLL CURSOR FOR select * from nds.symbol_data where exchange_name = inExchangeName and symbol = inSymbol and trade_date = inTradeDate;
  symbolDataRec nds.symbol_data%ROWTYPE;
BEGIN
  OPEN symbolDataCur;
  FETCH symbolDataCur INTO symbolDataRec;
  CLOSE symbolDataCur;

  IF inTradeDirection = 'LONG' THEN
    IF symbolDataRec.open_price <= inStopValue THEN
      -- The symbol has gapped down and is opening on or below the stop value. In this case the exit trade will trigger but the best price we can hope for is the open price.
      RETURN symbolDataRec.open_price;
    ELSEIF symbolDataRec.low_price <= inStopValue THEN
      -- The symbol was above the stop value, the price action has moved down through it and triggered the exit. In this case the best price we can hope for is our stop price.
      RETURN inStopValue;
    ELSE
      RAISE 'Critical error determining the stop value for a long trade';
    END IF;
  ELSEIF inTradeDirection = 'SHORT' THEN
    IF symbolDataRec.open_price >= inStopValue THEN
      -- The symbol has gapped up and is opening on or above the stop value. In this case the exit trade will trigger but the best price we can hope for is the open price.
      RETURN symbolDataRec.open_price;
    ELSEIF symbolDataRec.high_price >= inStopValue THEN
      -- The symbol was below the stop value, the price action has moved up through it and triggered the exit. In this case the best price we can hope for is our stop price.
      RETURN inStopValue;
    ELSE
      RAISE 'Critical error determining the stop value for a short trade';
    END IF;
  ELSE
    RAISE 'Trade direction of either LONG or SHORT was not specified';
  END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION nds.gcf( a BIGINT,  b BIGINT)
RETURNS BIGINT
IMMUTABLE
STRICT
LANGUAGE SQL
AS $$
WITH RECURSIVE t(a,b) AS (
    VALUES (abs($1)::BIGINT, abs($2)::BIGINT)
UNION ALL
    SELECT b, MOD(a,b) FROM t
    WHERE b > 0
)
SELECT a FROM t WHERE b = 0
$$;

ALTER FUNCTION nds.gcf(BIGINT, BIGINT) OWNER TO jeremy;
ALTER FUNCTION nds.getDaysInTradeCount(DATE, DATE, VARCHAR, VARCHAR) OWNER TO jeremy;
ALTER FUNCTION nds.getTrailingStopValue(VARCHAR, VARCHAR, VARCHAR, DATE, INT) OWNER TO jeremy;
ALTER FUNCTION nds.getProtectiveStopValue(VARCHAR, VARCHAR, DATE, INT) OWNER TO jeremy;
ALTER FUNCTION nds.activeTrade(VARCHAR, VARCHAR, DATE) OWNER TO jeremy;
ALTER FUNCTION nds.commentaryPrintln(TEXT, DATE, TEXT) OWNER TO jeremy;
ALTER FUNCTION nds.isStopExitTriggered(VARCHAR, VARCHAR, VARCHAR, DATE,REAL) OWNER TO jeremy;
ALTER FUNCTION nds.getStopExitValue(VARCHAR, VARCHAR, VARCHAR, DATE, REAL) OWNER TO jeremy;