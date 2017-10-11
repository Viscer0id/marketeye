CREATE SCHEMA nds;

CREATE SCHEMA stg;

CREATE SEQUENCE nds.trade_pair_system_id_seq START WITH 1;

CREATE SEQUENCE nds.trade_system_system_id_seq START WITH 1;

CREATE TABLE nds.exchange (
	exchange_name        varchar(10)  NOT NULL,
	description          text  ,
	CONSTRAINT exchange_pkey PRIMARY KEY ( exchange_name )
 );

CREATE TABLE nds.symbol (
	exchange_name        varchar(10)  NOT NULL,
	symbol               varchar(10)  NOT NULL,
	description          text  ,
	CONSTRAINT symbol_pkey PRIMARY KEY ( exchange_name, symbol ),
	CONSTRAINT pk_symbol UNIQUE ( exchange_name )
 );

CREATE INDEX symbol_ix001 ON nds.symbol ( symbol );

CREATE TABLE nds.symbol_data (
	exchange_name        varchar(10)  NOT NULL,
	symbol               varchar(10)  NOT NULL,
	date_trade           date  NOT NULL,
	open_price           real  NOT NULL,
	high_price           real  NOT NULL,
	low_price            real  NOT NULL,
	close_price          real  NOT NULL,
	volume               integer  NOT NULL,
	CONSTRAINT symbol_data_pkey PRIMARY KEY ( exchange_name, symbol, date_trade )
 );

CREATE INDEX symbol_data_ix001 ON nds.symbol_data ( symbol );

CREATE INDEX symbol_data_ix002 ON nds.symbol_data ( date_trade );

CREATE TABLE nds.trade_system (
	system_id            serial  NOT NULL,
	description          text  NOT NULL,
	CONSTRAINT trade_system_pkey PRIMARY KEY ( system_id )
 );

CREATE TABLE nds.trade_pair (
	system_id            serial  NOT NULL,
	exchange_name        varchar(10)  NOT NULL,
	symbol               varchar(10)  NOT NULL,
	entry_date           date  ,
	exit_date            date  ,
	entry_price          real  ,
	exit_price           real  ,
	CONSTRAINT trade_pair_pkey PRIMARY KEY ( system_id, exchange_name, symbol )
 );

CREATE INDEX trade_pair_ix001 ON nds.trade_pair ( exchange_name );

CREATE INDEX trade_pair_ix002 ON nds.trade_pair ( symbol );

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

ALTER TABLE nds.symbol ADD CONSTRAINT exchange_fk FOREIGN KEY ( exchange_name ) REFERENCES nds.exchange( exchange_name );

ALTER TABLE nds.symbol_data ADD CONSTRAINT symbol_fk FOREIGN KEY ( symbol ) REFERENCES nds.symbol( symbol ) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE nds.trade_pair ADD CONSTRAINT trade_system_fk FOREIGN KEY ( system_id ) REFERENCES nds.trade_system( system_id ) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE nds.trade_pair ADD CONSTRAINT symbol_fk FOREIGN KEY ( exchange_name, symbol ) REFERENCES nds.symbol( exchange_name, symbol ) ON DELETE RESTRICT ON UPDATE RESTRICT;

