from flask import Flask, request, jsonify
import sqlite3
from threading import Lock

app = Flask(__name__)
db_lock = Lock()

DATABASE = "bmi_sql.db"

def get_db_connection():
    conn = sqlite3.connect(DATABASE, check_same_thread=False)  # Allow multithreading
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/calculate', methods=['POST'])
def calculate_bmi():
    data = request.get_json()
    name = data['name']
    age = data['age']
    height = data['height']
    weight = data['weight']

    bmi = weight / (height ** 2)
    message = "Underweight" if bmi < 18.5 else "Healthy weight" if bmi < 24.9 else "Overweight"

    with db_lock:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO bmi (name, age, height, weight, bmi) VALUES (?, ?, ?, ?, ?)",
            (name, age, height, weight, bmi),
        )
        conn.commit()
        conn.close()

    return jsonify({'bmi': round(bmi, 2), 'message': message})

@app.route('/records', methods=['GET'])
def get_records():
    with db_lock:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM bmi")
        records = cursor.fetchall()
        conn.close()

    return jsonify([dict(record) for record in records])

if __name__ == "__main__":
    app.run(debug=True)
