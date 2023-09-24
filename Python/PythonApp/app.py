from flask import Flask     #, render_template
import custommetric         # this will be your file name; minus the `.py`

app = Flask(__name__)

@app.route('/')
def dynamic_page():
    #return "Congratulations, it's a web app!"
    #return render_template('custommetric.py')
    return custommetric.metric()

if __name__ == '__main__':
    #app.run(debug=True)
    app.run(host='0.0.0.0', port='5000', debug=True)

#http://0.0.0.0:8080/