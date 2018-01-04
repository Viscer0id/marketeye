from flask import render_template
from app import app, db
from app.model import TradeSummary, TradeStats


print('Connecting to the PostgreSQL database...')


@app.route('/')
@app.route('/dashboard')
@app.route('/index')
def index():
    return render_template('dashboard.html')


@app.route('/tradesummary')
@app.route('/tradesummary/<int:page>', methods=['GET', 'POST'])
def tradesummary(page=1):
    results = TradeSummary.query.paginate(page,20,False)
    return render_template('tradesummary.html',results=results)


@app.route('/tradestats/<string:selectionId>', methods=['GET', 'POST'])
def tradestats(selectionId: str):
    # results = TradeStats.query.filter_by(selection_id=selectionId)
    trades = db.session.query(TradeStats).filter_by(selection_id=selectionId)
    summary = db.session.query(TradeSummary).filter_by(selection_id = selectionId).first()
    return render_template('tradestats.html',trades=trades, summary=summary)


@app.route('/charts')
def charts():
    return render_template('charts.html')