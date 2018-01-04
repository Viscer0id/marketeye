from app import db


class TradeSummary(db.Model):
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
    selection_id = db.Column(db.String, primary_key=False, unique=False)


class TradeStats(db.Model):
    __tablename_ = 'trade_stats'
    __table_args__ = {"schema": "nds"}
    system_id = db.Column(db.Integer, primary_key=True)
    exchange_name = db.Column(db.String(10), primary_key=True)
    symbol = db.Column(db.String(10), primary_key=True)
    trade_direction = db.Column(db.String(5), primary_key=True)
    entry_date = db.Column(db.Date, primary_key=True)
    exit_date = db.Column(db.Date, primary_key=False)
    entry_price = db.Column(db.REAL, primary_key=False)
    exit_price = db.Column(db.REAL, primary_key=False)
    days_in_trade = db.Column(db.Integer, primary_key=False)
    profit = db.Column(db.REAL, primary_key=False)
    trade_commentary = db.Column(db.Text, primary_key=False)
    selection_id = db.Column(db.String, primary_key=False, unique=False)

class SymbolData(db.Model):
    __tablename_ = 'symbol_data'
    __table_args__ = {"schema": "nds"}
    exchange_name = db.Column(db.String(10), primary_key=True)
    symbol = db.Column(db.String(10), primary_key=True)
    trade_date = db.Column(db.Date, primary_key=True)
    open_price = db.Column(db.REAL, primary_key=False)
    high_price = db.Column(db.REAL, primary_key=False)
    low_price = db.Column(db.REAL, primary_key=False)
    close_price = db.Column(db.REAL, primary_key=False)
    volume = db.Column(db.Integer, primary_key=False)
