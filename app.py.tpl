from flask import Flask, render_template, request, jsonify
import mysql.connector
import json
from mysql.connector import Error
from mysql.connector import errorcode

app = Flask(__name__)
app.debug = True

@app.route('/index')
@app.route('/')
def index():
  return render_template('index.html')

@app.route('/addmore')
def addmore():
  return render_template('addmore.html')

@app.route('/getall', methods=['GET'])
def get_from_db():
    try:
        db_connection = mysql.connector.connect(
            host="${host}",
            user="${user}",
            passwd="${passwd}",
            database="${database}"
        )
        mycursor = db_connection.cursor()
        sql = "SELECT * FROM `animals`"

        print("sql: "+sql)
        mycursor.execute(sql)
        row_headers=[x[0] for x in mycursor.description] #this will extract row headers
        rv = mycursor.fetchall()
        json_data=[]
        for result in rv:
            json_data.append(dict(zip(row_headers,result)))

    except mysql.connector.Error as error:
        db_connection.rollback() #rollback if any exception occures
        print("Failed selecting record(s) from table {}".format(error))

    finally:
        #closing database connection.
        if(db_connection.is_connected()):
            mycursor.close()
            db_connection.close()
            print("Database connection closed!")

    json_data = {'data': json_data}
    return jsonify(json_data)

@app.route('/putname', methods=['POST'])
def add_name_to_db():
    details = request.form
    animal_name = details['animal_name']
    print (animal_name)
    try:
        db_connection = mysql.connector.connect(
            host="${host}",
            user="${user}",
            passwd="${passwd}",
            database="${database}"
        )
        mycursor = db_connection.cursor()
        sql = "INSERT INTO `animals`(name) VALUES ("+"'"+animal_name+"');"

        print("sql: "+sql)
        mycursor.execute(sql)

    except mysql.connector.Error as error:
        db_connection.rollback() #rollback if any exception occures
        print("Failed selecting record(s) from table {}".format(error))

    finally:
        db_connection.commit()
        #closing database connection.
        if(db_connection.is_connected()):
            mycursor.close()
            db_connection.close()
            print("Database connection closed!")

    return "Success! data inserted into database. <a href='/index'>Show Updated List</a>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')