# Market Eye
Trade System Evaluator 

## Installation
### Front-end
None 

### Back-end
1. Install PostgreSQL database, ensure default isolation is set to "Read Committed" (this is usually default) 
2. Untar data.tar.gz into a directory [data] 
3. Run 01_create.sql 
4. Run 02_populate_stg.sql* This script will need to be edited. It loads datafiles from the [data] directory that the data.tar.gz file just untarred to. Change the FROM portion of the script (/Users/Daedalus/marketeye/data/) to wherever the [data] directory is. This script will take awhile as it loads approx 4 million rows. 
5. Run 03_populate_nds.sql This script will take quite awhile (10 -> 15 mins) as it is processing the entire history of the ASX. 

## Front-end (UI)
Web application using Python Flask. 

## Back-end
PostgreSQL Database has two layers: Staging (STG) and Normalised Data Storage (NDS). 
<b>STG</b> is where the raw stock market data is loaded .
<b>NDS</b> is where the data is conformed and loaded into the Trade System Evaluation data model. 

All of the data processing happens in the Back-end, primarily using PL/PGSQL. The web-application will call PL/PGSQL Stored Procedures or Views to retrieve data or execute processes. 

## Directory Structure
root 
run.py Top level used to start the Python Flask webapp 
app/ Contains the Front-end application and associated code 
database/ Contains the Back-end scripts 