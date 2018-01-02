from flask import render_template
from app import app

@app.route('/')
@app.route('/dashboard')
@app.route('/index')
def index():
    return render_template('dashboard.html')

@app.route('/tradestats')
def tradestats():
    return render_template('tradestats.html')

@app.route('/charts')
def charts():
    return render_template('charts.html')