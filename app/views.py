from flask import render_template
from app import app

@app.route('/')
@app.route('/dashboard')
def index():
    return render_template('dashboard.html')
    # return "Hello, World!"
