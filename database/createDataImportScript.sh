#!/bin/bash

current_directory=`pwd`
data_directory="/Users/Daedalus/marketeye/data/"
script_prefix="\COPY stg.symbol_data(symbol,trade_date,open_price,high_price,low_price,close_price,volume) FROM '"
script_suffix="' WITH CSV"
output_file=import_data.sql

echo > $output_file	# Creates the file if it doesn't exist. If it does, truncates the file

for filename in $data_directory*
do
	echo $script_prefix$filename$script_suffix >> $output_file
done;

echo "Run the following command to load the data: /Library/PostgreSQL/10/bin/psql -h localhost -p 5433 -d market_eye -U jeremy -f '$current_directory/import_data.sql'"