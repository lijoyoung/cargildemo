import mysql.connector
from mysql.connector import Error
from mysql.connector import errorcode

try:
    db_connection = mysql.connector.connect(
        host="${host}",
        user="${user}",
        passwd="${passwd}",
        database="${database}"
    )
    mycursor = db_connection.cursor()
    sql = "CREATE TABLE IF NOT EXISTS `animals` (`id` INT AUTO_INCREMENT PRIMARY KEY, `name` VARCHAR(255) NULL)"

    print("sql: "+sql)
    mycursor.execute(sql)         

except mysql.connector.Error as error:
    db_connection.rollback() #rollback if any exception occures
    print("Failed creating table {}".format(error))

finally:
    #closing database connection.
    if(db_connection.is_connected()):
        mycursor.close()
        db_connection.close()
        print("Database connection closed!")