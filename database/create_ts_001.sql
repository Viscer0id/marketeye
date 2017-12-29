/*
-- Backout Script

DELETE FROM nds.trade_system WHERE system_id = 1;
DROP FUNCTION nds.ts_1(VARCHAR, VARCHAR);
*/

INSERT INTO nds.trade_system VALUES (1,'Donchian Channel trade system test. Trade long when the current high is greater than the highest high of the past 30 days and short when the low price is lower than the low of the past 30 days');

CREATE OR REPLACE FUNCTION nds.ts_1(inExchangeName VARCHAR, inSymbol VARCHAR) RETURNS VOID
AS
$$
DECLARE
  systemId INTEGER := 1;
	tradeDataRec nds.symbol_data%ROWTYPE;
  entryRec RECORD;
  activeTrade BOOLEAN := FALSE;
  daysInTrade INTEGER := 0;
  lookBack INTEGER := 30;
  tradeCommentary TEXT := '';
  protectiveStop REAL := 0.0;
  trailingStop REAL := 0.0;
  tradeDirection VARCHAR(5) := 'LONG';

  tradeDataCur NO SCROLL CURSOR (inExchangeName VARCHAR, inSymbol VARCHAR) FOR select * from nds.symbol_data WHERE exchange_name = inExchangeName AND symbol = inSymbol ORDER BY trade_date ASC;
--   protectStopCur NO SCROLL CURSOR (inExchangeName VARCHAR, inSymbol VARCHAR, inTradeDate DATE, inLookBack INTEGER) FOR select (max(high_price) - min(low_price)) / 2 + min(low_price) from nds.symbol_data where exchange_name = inExchangeName and symbol = inSymbol and trade_date <= inTradeDate and trade_date >= (inTradeDate - inLookBack) group by exchange_name, symbol;
--   trailingStopCur NO SCROLL CURSOR (inExchangeName VARCHAR, inSymbol VARCHAR, inTradeDate DATE, inLookBack INTEGER) FOR select (min(low_price)) from nds.symbol_data where exchange_name = inExchangeName and symbol = inSymbol and trade_date <= inTradeDate and trade_date >= (inTradeDate - inLookBack) group by exchange_name, symbol;

BEGIN
	OPEN tradeDataCur (inExchangeName, inSymbol);
    LOOP
    	FETCH tradeDataCur INTO tradeDataRec;
      EXIT WHEN NOT FOUND;

      -- Check to see if we have moved to a different exchange / symbol
      IF tradeDataRec.next1_trade_date ISNULL THEN
        activeTrade := FALSE;
        daysInTrade := 0;
        lookBack := 30;
        tradeCommentary := '';
      END IF;

      -- Still in trade
      IF (activeTrade IS TRUE) THEN
        daysInTrade := daysInTrade+1;
      END IF;

      -- Entry
      IF (tradeDataRec.donchian_channel_30 = 'UPTREND' AND activeTrade IS FALSE AND tradeDataRec.next1_trade_date NOTNULL) THEN
        tradeCommentary := TO_CHAR(tradeDataRec.trade_date,'DD-MON-YYYY')||': Trade identified'||E'\r\n';
        FETCH tradeDataCur INTO tradeDataRec; -- Increment the cursor one day. We do this because we enter on the morning after identifying a trade.
        entryRec := tradeDataRec;
        activeTrade := TRUE;
        daysInTrade := 1;

        INSERT INTO nds.trade_pair (system_id, entry_date, exit_date, entry_price, exit_price, exchange_name, symbol) VALUES (systemId, entryRec.trade_date, null, entryRec.open_price, null, entryRec.exchange_name, entryRec.symbol);
        tradeCommentary := tradeCommentary||TO_CHAR(tradeDataRec.trade_date,'DD-MON-YYYY')||': Entering trade on open at '||TRIM(TO_CHAR(entryRec.open_price,'9999.99'))||', ';

        --OPEN protectStopCur(inExchangeName:=tradeDataRec.exchange_name, inSymbol:= tradeDataRec.symbol, inTradeDate:=tradeDataRec.trade_date, inLookBack:=lookBack);
        --FETCH protectStopCur INTO protectiveStop;
        --CLOSE protectStopCur;
--         protectiveStop = getprotectivestopvalue(tradeDataRec.exchange_name,tradeDataRec.symbol, tradeDataRec.trade_date, lookBack);
--         tradeCommentary := tradeCommentary||'setting protective stop at '||COALESCE(TRIM(TO_CHAR(protectiveStop,'9999.99')),'NULL ERROR')||', ';

        --OPEN trailingStopCur(inExchangeName:=tradeDataRec.exchange_name, inSymbol:= tradeDataRec.symbol, inTradeDate:=tradeDataRec.trade_date, inLookBack:=lookBack);
        --FETCH trailingStopCur INTO trailingStop;
        --CLOSE trailingStopCur;
        --trailingStop = gettrailingstopvalue(rec.exchange_name, rec.symbol, rec.trade_date, 30, daysInTrade);
        --tradeCommentary := tradeCommentary||'setting trailing stop at '||COALESCE(TRIM(TO_CHAR(trailingStop,'9999.99')),'NULL ERROR')||E'\r\n';

      --trailingStop = gettrailingstopvalue(rec.exchange_name, rec.symbol, rec.trade_date, 30, daysInTrade);
      --tradeCommentary := tradeCommentary||'setting trailing stop at '||COALESCE(TRIM(TO_CHAR(trailingStop,'9999.99')),'NULL ERROR')||E'\r\n';
      END IF;

      trailingStop = nds.gettrailingstopvalue(tradeDirection, tradeDataRec.exchange_name, tradeDataRec.symbol, tradeDataRec.trade_date, daysInTrade);
      tradeCommentary := tradeCommentary||TO_CHAR(tradeDataRec.trade_date,'DD-MON-YYYY')||'setting trailing stop at '||COALESCE(TRIM(TO_CHAR(trailingStop,'9999.99')),'NULL ERROR')||E'\r\n';
      -- Adjust the trailing stop
      --IF (activeTrade IS TRUE AND mod(daysInTrade,5) = 0) THEN
        --IF (lookBack - 2) >= 6 THEN
          --lookBack := lookBack-2;
        --END IF;

        --OPEN trailingStopCur(inExchangeName:=tradeDataRec.exchange_name, inSymbol:= tradeDataRec.symbol, inTradeDate:=tradeDataRec.trade_date, inLookBack:=lookBack);
        --FETCH trailingStopCur INTO trailingStop;
        --CLOSE trailingStopCur;
        --tradeCommentary := tradeCommentary||TO_CHAR(tradeDataRec.trade_date,'DD-MON-YYYY')||': currently '||TRIM(TO_CHAR(daysInTrade,'9999'))||' days in trade, setting trailing stop at '||TRIM(TO_CHAR(trailingStop,'999.99'))||E'\r\n';
      --END IF;

      -- Exit on protective stop
      IF (activeTrade IS TRUE AND tradeDataRec.low_price <= protectiveStop) THEN
        tradeCommentary := tradeCommentary||TO_CHAR(tradeDataRec.trade_date,'DD-MON-YYYY')||': protective stop triggered, exiting the trade at '||TRIM(TO_CHAR(protectiveStop,'9999.99'))||E'\r\n';
        UPDATE nds.trade_pair SET exit_date = tradeDataRec.trade_date, exit_price = protectiveStop, trade_commentary = tradeCommentary WHERE system_id = systemId AND exchange_name = entryRec.exchange_name AND symbol = entryRec.symbol AND entry_date = entryRec.trade_date;
        activeTrade := FALSE;
        daysInTrade := 0;
        lookBack := 30;
        tradeCommentary := '';
      END IF;

      -- Exit on trailing stop
      IF (activeTrade IS TRUE AND tradeDataRec.low_price <= trailingStop) THEN
        tradeCommentary := tradeCommentary||TO_CHAR(tradeDataRec.trade_date,'DD-MON-YYYY')||': trailing stop triggered, exiting the trade at '||TRIM(TO_CHAR(trailingStop,'9999.99'))||E'\r\n';
        UPDATE nds.trade_pair SET exit_date = tradeDataRec.trade_date, exit_price = trailingStop, trade_commentary = tradeCommentary WHERE system_id = systemId AND exchange_name = entryRec.exchange_name AND symbol = entryRec.symbol AND entry_date = entryRec.trade_date;
        activeTrade := FALSE;
        daysInTrade := 0;
        lookBack := 30;
        tradeCommentary := '';
      END IF;

      -- Exit
      IF (activeTrade IS TRUE AND tradeDataRec.donchian_channel_30 = 'DOWNTREND') THEN
        tradeCommentary := tradeCommentary||TO_CHAR(tradeDataRec.trade_date,'DD-MON-YYYY')||': Direction change identified'||E'\r\n';
        FETCH tradeDataCur into tradeDataRec; -- Increment the cursor one day. We do this because we exit the morning after identifying the exit of a trade.
        tradeCommentary := tradeCommentary||TO_CHAR(tradeDataRec.trade_date,'DD-MON-YYYY')||': Exiting the trade on open at '||TRIM(TO_CHAR(tradeDataRec.open_price,'9999.99'))||E'\r\n';
        UPDATE nds.trade_pair SET exit_date = tradeDataRec.trade_date, exit_price = tradeDataRec.open_price, trade_commentary = tradeCommentary WHERE system_id = systemId AND exchange_name = entryRec.exchange_name AND symbol = entryRec.symbol AND entry_date = entryRec.trade_date;
        activeTrade := FALSE;
        daysInTrade := 0;
        lookBack := 30;
        tradeCommentary := '';
      END IF;

    END LOOP;
    CLOSE tradeDataCur;
END;
$$
LANGUAGE 'plpgsql';

ALTER FUNCTION nds.ts_1() OWNER TO jeremy;