from flask import render_template, request, json
from app import app, db
from app.model import TradeSummary, TradeStats, SymbolData

@app.route('/')
@app.route('/dashboard')
@app.route('/index')
def index():
    return render_template('dashboard.html')


@app.route('/tradesummary')
@app.route('/tradesummary/<int:page>', methods=['GET', 'POST'])
def tradesummary(page=1):
    results = TradeSummary.query.paginate(page, 20, False)
    return render_template('tradesummary.html',results=results)


@app.route('/tradestats/<string:selectionId>', methods=['GET', 'POST'])
def tradestats(selectionId: str):
    # system_id = request.form['systemId']
    # exchange_name = request.form['exchangeName']
    # symbol = request.form['symbol']
    trades = db.session.query(TradeStats).filter_by(selection_id=selectionId)
    summary = db.session.query(TradeSummary).filter_by(selection_id = selectionId).first()
    return render_template('tradestats.html', trades=trades, summary=summary)


@app.route('/charts')
def charts():
    return render_template('charts.html')


@app.route('/getchartdata', methods=['POST'])
def getchartdata():
    exchange_name = request.form['exchangeName']
    symbol = request.form['symbol']
    entry_date = request.form['entryDate']
    exit_date = request.form['exitDate']
    recordset = db.session.query(SymbolData).filter_by(exchange_name=exchange_name, symbol=symbol).filter(SymbolData.trade_date >= entry_date, SymbolData.trade_date <= exit_date).all()
    # print(json.dumps([row.as_dict for row in recordset]))
    # return json.dumps([dict(row) for row in recordset])
    # return json.dumps({'status':200})
    return json.dumps([row.as_dict for row in recordset])
