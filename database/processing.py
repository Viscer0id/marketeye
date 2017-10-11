import psycopg2

try:
    conn = psycopg2.connect("dbname='market_eye' user='jeremy' host='localhost' password='10Forward' port='5433'")
except:
    print("I am unable to connect to the database")

cur = conn.cursor()
cur.execute("""SELECT * FROM nds.symbol_data""")
rows = cur.fetchall()
for row in rows:
    print(row[1])