/*
-- Backout Script

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
  tradePairCur NO SCROLL CURSOR (inExchangeName VARCHAR, inSymbol VARCHAR, inEntryDate DATE) FOR select exit_date from nds.trade_pair where exchange_name = inExchangeName and symbol = inSymbol and entry_date = inEntryDate;
BEGIN
  OPEN tradePairCur(inExchangeName, inSymbol, inEntryDate);
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

CREATE OR REPLACE FUNCTION println(IN inputText TEXT) RETURNS TEXT
AS
$$
DECLARE
BEGIN
  RETURN '';
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION stopExitTriggered(IN inputText TEXT) RETURNS BOOLEAN
AS
$$
DECLARE
BEGIN
  RETURN '';
END;
$$
LANGUAGE 'plpgsql';


ALTER FUNCTION nds.getTrailingStopValue(VARCHAR, VARCHAR, VARCHAR, DATE, INT) OWNER TO jeremy;
ALTER FUNCTION nds.getProtectiveStopValue(VARCHAR, VARCHAR, DATE, INT) OWNER TO jeremy;
ALTER FUNCTION nds.activeTrade(VARCHAR, VARCHAR, DATE) OWNER TO jeremy;