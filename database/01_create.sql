﻿/*
-- Backout Script

-- STG Schema
DROP TABLE stg.symbol_data;

-- NDS Schema
DROP VIEW nds.trade_summary;
DROP VIEW nds.trade_stats;
DROP TABLE nds.trade_pair;
DROP TABLE nds.symbol_data;
DROP TABLE nds.trade_system;
DROP TABLE nds.symbol;
DROP TABLE nds.exchange;
*/

-- STG Schema
CREATE SCHEMA stg;

CREATE TABLE stg.symbol_data (
exchange_name        varchar(10)  ,
symbol               varchar(10)  ,
trade_date           date  ,
open_price           real  ,
high_price           real  ,
low_price            real  ,
close_price          real  ,
volume               integer
);

-- NDS Schema
CREATE SCHEMA nds;

CREATE TABLE nds.exchange (
  exchange_name        varchar(10)  NOT NULL,
  description          text  ,
	CONSTRAINT exchange_pkey PRIMARY KEY ( exchange_name )
 );

CREATE TABLE nds.symbol (
	exchange_name        varchar(10)  NOT NULL,
	symbol               varchar(10)  NOT NULL,
	description          text  ,
	CONSTRAINT symbol_pkey PRIMARY KEY ( exchange_name, symbol )
 );

CREATE INDEX symbol_ix001 ON nds.symbol ( symbol );

CREATE TABLE nds.symbol_data (
	exchange_name        varchar(10)  ,
	symbol               varchar(10)  ,
	trade_date           date  ,
	open_price           real  ,
	high_price           real  ,
	low_price            real  ,
	close_price          real  ,
	volume               integer  ,
	prior1_trade_date    date  ,
	prior1_high_price    real  ,
	prior1_low_price     real  ,
	prior2_high_price    real  ,
	prior2_low_price     real  ,
	prior3_high_price    real  ,
	prior3_low_price     real  ,
	next1_trade_date     date  ,
	next1_open_price     real  ,
	sma_15               real  ,
	sma_50               real  ,
	donchian_30_high     real  ,
	donchian_30_low      real  ,
	sma_15_50_change     real  ,
	donchian_channel_30  varchar(10)  ,
	bar_type             varchar(10)  ,
	prior1_sma_15_50_change real  ,
	prior1_bar_type      varchar(10)  ,
	sma_15_50_crossover  bool  ,
	trend_peak_trough    varchar(10)  ,
	trend_gann_2day_swing varchar(10)  ,
	trend_gann_3day_swing varchar(10) ,
  spread	          REAL,
  mov30avg_spread	  REAL,
  mov30std_spread	  REAL,
  mov30avg_volume	  REAL,
  mov30std_volume	  REAL,
  mov30_spread_z_score	REAL,
  mov30_volume_z_score	REAL,
  lower_third   REAL,
  upper_third   REAL,
  mid_point     REAL,
	CONSTRAINT symbol_data_pkey PRIMARY KEY ( exchange_name, symbol, trade_date )
 );

CREATE INDEX symbol_data_ix001 ON nds.symbol_data ( symbol );

CREATE INDEX symbol_data_ix002 ON nds.symbol_data ( trade_date );

CREATE TABLE nds.trade_system (
	system_id            int  NOT NULL,
  trade_direction      VARCHAR(5) NOT NULL,
  description          text  NOT NULL,
	CONSTRAINT trade_system_pkey PRIMARY KEY ( system_id, trade_direction )
 );

CREATE TABLE nds.trade_pair (
	system_id            int  NOT NULL,
  trade_direction      VARCHAR(5) NOT NULL,
	exchange_name        varchar(10)  NOT NULL,
	symbol               varchar(10)  NOT NULL,
	entry_date           date  NOT NULL,
	exit_date            date  ,
	entry_price          real  ,
	exit_price           real  ,
	trade_commentary		 text,
	days_in_trade				 int,
	CONSTRAINT trade_pair_pkey PRIMARY KEY ( system_id, trade_direction, exchange_name, symbol, entry_date )
 );

CREATE INDEX trade_pair_ix001 ON nds.trade_pair ( exchange_name );

CREATE INDEX trade_pair_ix002 ON nds.trade_pair ( symbol );

CREATE INDEX trade_pair_ix003 ON nds.trade_pair ( entry_date );

CREATE INDEX trade_system_ix002 ON nds.trade_system (trade_direction);

ALTER TABLE nds.symbol ADD CONSTRAINT exchange_fk FOREIGN KEY ( exchange_name ) REFERENCES nds.exchange( exchange_name );

ALTER TABLE nds.symbol_data ADD CONSTRAINT symbol_fk FOREIGN KEY ( exchange_name, symbol ) REFERENCES nds.symbol( exchange_name, symbol ) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE nds.trade_pair ADD CONSTRAINT trade_system_fk FOREIGN KEY ( system_id, trade_direction ) REFERENCES nds.trade_system( system_id, trade_direction ) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE nds.trade_pair ADD CONSTRAINT symbol_fk FOREIGN KEY ( exchange_name, symbol ) REFERENCES nds.symbol( exchange_name, symbol ) ON DELETE RESTRICT ON UPDATE RESTRICT;
