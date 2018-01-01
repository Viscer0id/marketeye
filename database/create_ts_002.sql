/*
-- Backout Script

DELETE FROM nds.trade_system WHERE system_id = 2;
DROP FUNCTION nds.ts_2(VARCHAR, VARCHAR);
*/

INSERT INTO nds.trade_system VALUES (2,'SHORT','Donchian Channel trade system; trade short when the current low is lower than the lowest low of the past 30 days');

CREATE OR REPLACE FUNCTION nds.ts_2(inExchangeName VARCHAR, inSymbol VARCHAR) RETURNS VOID
AS
$$
DECLARE
  systemId INTEGER := 2;
  tradeDirection VARCHAR(5) := 'SHORT';
	tradeDataRec nds.symbol_data%ROWTYPE;
  entryRec nds.symbol_data%ROWTYPE;
  activeTrade BOOLEAN := FALSE;
  daysInTrade INTEGER := 0;
  lookBack INTEGER := 30;
  tradeCommentary TEXT := '';
  protectiveStop REAL := 0.0;
  trailingStop REAL := 0.0;
  stopExitValue REAL := 0.0;

  tradeDataCur NO SCROLL CURSOR FOR select * from nds.symbol_data WHERE exchange_name = inExchangeName AND symbol = inSymbol ORDER BY trade_date ASC;

BEGIN
	OPEN tradeDataCur;
    LOOP
    	FETCH tradeDataCur INTO tradeDataRec;
      EXIT WHEN NOT FOUND;

      -- Still in trade
      IF (activeTrade IS TRUE) THEN
        daysInTrade := nds.getdaysintradecount(entryRec.trade_date, tradeDataRec.trade_date, inExchangeName, inSymbol);
        trailingStop := nds.gettrailingstopvalue(tradeDirection, inExchangeName, inSymbol, tradeDataRec.trade_date, daysInTrade);
        tradeCommentary := nds.commentaryPrintLn(tradeCommentary,tradeDataRec.trade_date,'setting trailing stop at '||TO_CHAR(trailingStop,'FM999999.00'));
      END IF;

      -- Entry
      IF (activeTrade IS FALSE AND tradeDataRec.next1_trade_date IS NOT NULL AND tradeDataRec.donchian_channel_30 = 'DOWNTREND') THEN
        activeTrade := TRUE;
        daysInTrade := 1;
        tradeCommentary := '';

        tradeCommentary := nds.commentaryPrintLn(tradeCommentary, tradeDataRec.trade_date, 'trade entry identified');
        FETCH tradeDataCur INTO tradeDataRec; -- Increment the cursor one day. We do this because we enter on the morning after identifying a trade.
        entryRec := tradeDataRec; -- Store the record which we entered on

        INSERT INTO nds.trade_pair (system_id, entry_date, exit_date, entry_price, exit_price, exchange_name, symbol, trade_direction) VALUES (systemId, entryRec.trade_date, null, entryRec.open_price, null, inExchangeName, inSymbol, tradeDirection);
        tradeCommentary := nds.commentaryPrintLn(tradeCommentary, tradeDataRec.trade_date, 'entering trade on open at '||TO_CHAR(entryRec.open_price,'FM999999.00'));

        protectiveStop := nds.getProtectiveStopValue(inExchangeName, inSymbol, tradeDataRec.trade_date, lookBack);
        tradeCommentary := nds.commentaryPrintLn(tradeCommentary, tradeDataRec.trade_date, 'setting protective stop at '||TO_CHAR(protectiveStop,'FM999999.00'));

        trailingStop = nds.getTrailingstopvalue(tradeDirection, inExchangeName, inSymbol, tradeDataRec.trade_date, daysInTrade);
        tradeCommentary := nds.commentaryPrintLn(tradeCommentary,tradeDataRec.trade_date,'setting trailing stop at '||TO_CHAR(trailingStop,'FM999999.00'));
      END IF;

      -- Stoploss exit
      IF (activeTrade IS TRUE AND nds.isStopExitTriggered(tradeDirection, inExchangeName, inSymbol, tradeDataRec.trade_date, LEAST(trailingStop,protectiveStop))) THEN
        tradeCommentary := nds.commentaryPrintLn(tradeCommentary, tradeDataRec.trade_date, 'stoploss triggered, exiting the trade');
        stopExitValue := nds.getStopExitValue(tradeDirection, inExchangeName, inSymbol, tradeDataRec.trade_date, LEAST(trailingStop,protectiveStop));
        UPDATE nds.trade_pair SET exit_date = tradeDataRec.trade_date, days_in_trade = daysInTrade, exit_price = stopExitValue, trade_commentary = tradeCommentary WHERE system_id = systemId AND exchange_name = inExchangeName AND symbol = inSymbol AND entry_date = entryRec.trade_date;
        activeTrade := FALSE;
      END IF;

      -- Signal exit
      IF (activeTrade IS TRUE AND tradeDataRec.donchian_channel_30 = 'UPTREND') THEN
        tradeCommentary := nds.commentaryPrintLn(tradeCommentary, tradeDataRec.trade_date, 'trade exit identified');
        FETCH tradeDataCur INTO tradeDataRec; -- Increment the cursor one day. We do this because we exit on the morning after identifying the exit.
        UPDATE nds.trade_pair SET exit_date = tradeDataRec.trade_date, days_in_trade = daysInTrade, exit_price = tradeDataRec.open_price, trade_commentary = tradeCommentary WHERE system_id = systemId AND exchange_name = inExchangeName AND symbol = inSymbol AND entry_date = entryRec.trade_date;
        activeTrade := FALSE;
      END IF;

    END LOOP;
    CLOSE tradeDataCur;
END;
$$
LANGUAGE 'plpgsql';

ALTER FUNCTION nds.ts_2 OWNER TO jeremy;