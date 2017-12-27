INSERT INTO nds.trade_system VALUES (1,'Donchian Channel trade system test. Trade long when the current high is greater than the highest high of the past 30 days and short when the low price is lower than the low of the past 30 days');

CREATE OR REPLACE FUNCTION nds.ts_1() RETURNS void
AS
$$
DECLARE
  systemId INTEGER = 1;
	rec RECORD;
  entryRec RECORD;
  activeTrade BOOLEAN = FALSE;
  myCur NO SCROLL CURSOR FOR select * from nds.symbol_temp ORDER BY exchange_name, symbol, trade_date;
BEGIN
	OPEN myCur;
    LOOP
    	FETCH myCur INTO rec;
      EXIT WHEN NOT FOUND;

      -- Check to see if we have moved to a different exchange / symbol
--       IF rec.exchange_name <> currExchangeName OR rec.symbol <> currSymbol THEN
--         activeTrade = FALSE;
--       END IF;
      IF rec.next1_trade_date ISNULL THEN
        activeTrade = FALSE;
      END IF;

      -- Entry
      IF rec.donchian_channel_30 = 'UPTREND' AND activeTrade = FALSE AND rec.next1_trade_date NOTNULL THEN
        entryRec = rec;
        activeTrade = TRUE;
        INSERT INTO nds.trade_pair (system_id, entry_date, exit_date, entry_price, exit_price, exchange_name, symbol) VALUES (systemId, entryRec.next1_trade_date, null, entryRec.next1_open_price, null, entryRec.exchange_name, entryRec.symbol);
        protectiveStop = select (max) high_price - min(low_price) / 2 + min(low_price) from nds.symbol_temp where exchange_name = rec.exchange_name and symbol = rec.symbol and trade_date between rec.next1_trade_date and rec.
      END IF;

      -- Exit
      IF rec.donchian_channel_30 = 'DOWNTREND' AND activeTrade = TRUE THEN
        UPDATE nds.trade_pair SET exit_date = rec.next1_trade_date, exit_price = rec.next1_open_price WHERE system_id = systemId AND exchange_name = entryRec.exchange_name AND symbol = entryRec.symbol AND entry_date = entryRec.next1_trade_date;
        activeTrade = FALSE;
      END IF;

    END LOOP;
    CLOSE myCur;
END;
$$
LANGUAGE 'plpgsql';

ALTER FUNCTION nds.ts_1()
    OWNER TO jeremy;

DO $$
BEGIN
  PERFORM nds.ts_1();
END;
$$