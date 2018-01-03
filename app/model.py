from app import db

from sqlalchemy.ext.declarative import declarative_base

# Base = declarative_base()
#
# class TradeStatistic(Base):
#     __tablename__ = 'trade_summary'
#     __table_args__ = {"schema": "nds"}
#     system_id = Column(Integer, primary_key=True)
#     exchange_name = Column(String(10), primary_key=True)
#     symbol = Column(String(10), primary_key=True)
#     trade_direction = Column(String(5), primary_key=True)
#     count_profit = Column(REAL, primary_key=False)
#     count_loss = Column(REAL, primary_key=False)
#     approx_pl_trade_ratio = Column(Text, primary_key=False)
#     avg_days_in_trade = Column(Integer, primary_key=False)
#     sum_profit = Column(REAL, primary_key=False)
#     sum_loss = Column(REAL, primary_key=False)
#     total_position = Column(REAL, primary_key=False)

# Base = declarative_base()

class TradeStatistic(db.Model):
    __tablename__ = 'trade_summary'
    __table_args__ = {"schema": "nds"}
    system_id = db.Column(db.Integer, primary_key=True)
    exchange_name = db.Column(db.String(10), primary_key=True)
    symbol = db.Column(db.String(10), primary_key=True)
    trade_direction = db.Column(db.String(5), primary_key=True)
    count_profit = db.Column(db.REAL, primary_key=False)
    count_loss = db.Column(db.REAL, primary_key=False)
    approx_pl_trade_ratio = db.Column(db.Text, primary_key=False)
    avg_days_in_trade = db.Column(db.Integer, primary_key=False)
    sum_profit = db.Column(db.REAL, primary_key=False)
    sum_loss = db.Column(db.REAL, primary_key=False)
    total_position = db.Column(db.REAL, primary_key=False)
