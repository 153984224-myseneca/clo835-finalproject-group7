from flask import Flask, render_template, request
from pymysql import connections
import os
import random
import argparse
import boto3

app = Flask(__name__)

DBHOST = os.environ.get("DBHOST") or "localhost"
DBUSER = os.environ.get("DBUSER") or "root"
DBPWD = os.environ.get("DBPWD") or "passwors"
DATABASE = os.environ.get("DATABASE") or "employees"
COLOR_FROM_ENV = os.environ.get('APP_COLOR') or "lime"
DBPORT = int(os.environ.get("DBPORT"))

GROUP = os.environ.get('GROUP_NAME') or ""
SLOGAN = os.environ.get('SLOGAN') or ""
IMAGEURL = os.environ.get('BACKGROUND_IMAGE_URL') or ""
BUCKET = os.environ.get('BUCKET_NAME') or ""
FILE = os.environ.get('FILE_NAME') or ""
IMAGE_PATH = os.environ.get('IMAGE_PATH') or ""

# AWS credentails
ACCESS_KEY = os.environ.get('AWS_ACCESS_KEY_ID') or ""
SECRET_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY') or ""
SESSION_TOKEN = os.environ.get('AWS_SESSION_TOKEN') or ""

# Create a connection to the MySQL database
db_conn = connections.Connection(
    host= DBHOST,
    port=DBPORT,
    user= DBUSER,
    password= DBPWD, 
    db= DATABASE
)
output = {}
table = 'employee';

# Define the supported color codes
color_codes = {
    "red": "#e74c3c",
    "green": "#16a085",
    "blue": "#89CFF0",
    "blue2": "#30336b",
    "pink": "#f4c2c2",
    "darkblue": "#130f40",
    "lime": "#C1FF9C",
}


# Create a string of supported colors
SUPPORTED_COLORS = ",".join(color_codes.keys())

# Generate a random color
COLOR = random.choice(["red", "green", "blue", "blue2", "darkblue", "pink", "lime"])

def checkFileExists(filepath):
    if os.path.exists(filepath):
        return True
    else:
        return False

def getBackground():
    if IMAGE_PATH != "":
        print(IMAGE_PATH)
        if checkFileExists(IMAGE_PATH):
            return f"background-image: url({IMAGE_PATH}); background-size: cover;"
        else:
            color = color_codes[COLOR]
            return f"background-color: {color};"
    
    path = f"static/background.jpg"
    # Check local background image exsits 
    if checkFileExists(path):
        return f"background-image: url({path}); background-size: cover;"
    else:
        if FILE != "" and BUCKET != "":
            # Look up the s3 to get a backgound image and download it
            path = downloadFile(FILE, BUCKET)
            if path != "":
                return f"background-image: url({path}); background-size: cover;"
        return f"background-color: {color};"

# Download a file from S3 bucket
def downloadFile(file_name, bucket):
    if ACCESS_KEY != "" and SECRET_KEY != "" and SESSION_TOKEN != "":
        # Provide credentials to Boto3
        session = boto3.Session(
            aws_access_key_id=ACCESS_KEY,
            aws_secret_access_key=SECRET_KEY,
            aws_session_token=SESSION_TOKEN
        )
        s3 = session.resource('s3')
        path = f"static/{file_name}"
        # Download filie into path
        s3.Bucket(bucket).download_file(file_name, path)
        print("downloaded image location in s3:", f"{bucket}/static/{file_name}")
        return path
    
BACKGROUND = getBackground()

@app.route("/", methods=['GET', 'POST'])
def home():
    return render_template('addemp.html', background=BACKGROUND, group_name=GROUP, slogan=SLOGAN)

@app.route("/about", methods=['GET','POST'])
def about():
    return render_template('about.html', background=BACKGROUND, group_name=GROUP, slogan=SLOGAN)
    
@app.route("/addemp", methods=['POST'])
def AddEmp():
    emp_id = request.form['emp_id']
    first_name = request.form['first_name']
    last_name = request.form['last_name']
    primary_skill = request.form['primary_skill']
    location = request.form['location']

  
    insert_sql = "INSERT INTO employee VALUES (%s, %s, %s, %s, %s)"
    cursor = db_conn.cursor()

    try:
        
        cursor.execute(insert_sql,(emp_id, first_name, last_name, primary_skill, location))
        db_conn.commit()
        emp_name = "" + first_name + " " + last_name

    finally:
        cursor.close()

    print("all modification done...")
    return render_template('addempoutput.html', name=emp_name, background=BACKGROUND)

@app.route("/getemp", methods=['GET', 'POST'])
def GetEmp():
    return render_template("getemp.html", background=BACKGROUND)


@app.route("/fetchdata", methods=['GET','POST'])
def FetchData():
    emp_id = request.form['emp_id']

    output = {}
    select_sql = "SELECT emp_id, first_name, last_name, primary_skill, location from employee where emp_id=%s"
    cursor = db_conn.cursor()

    try:
        cursor.execute(select_sql,(emp_id))
        result = cursor.fetchone()
        
        # Add No Employee found form
        output["emp_id"] = result[0]
        output["first_name"] = result[1]
        output["last_name"] = result[2]
        output["primary_skills"] = result[3]
        output["location"] = result[4]
        
    except Exception as e:
        print(e)

    finally:
        cursor.close()

    return render_template("getempoutput.html", id=output["emp_id"], fname=output["first_name"],
                           lname=output["last_name"], interest=output["primary_skills"], location=output["location"], color=color_codes[COLOR])

if __name__ == '__main__':
    
    # Check for Command Line Parameters for color
    parser = argparse.ArgumentParser()
    parser.add_argument('--color', required=False)
    args = parser.parse_args()

    if args.color:
        print("Color from command line argument =" + args.color)
        COLOR = args.color
        if COLOR_FROM_ENV:
            print("A color was set through environment variable -" + COLOR_FROM_ENV + ". However, color from command line argument takes precendence.")
    elif COLOR_FROM_ENV:
        print("No Command line argument. Color from environment variable =" + COLOR_FROM_ENV)
        COLOR = COLOR_FROM_ENV
    else:
        print("No command line argument or environment variable. Picking a Random Color =" + COLOR)

    # Check if input color is a supported one
    if COLOR not in color_codes:
        print("Color not supported. Received '" + COLOR + "' expected one of " + SUPPORTED_COLORS)
        exit(1)

    app.run(host='0.0.0.0',port=8080,debug=True)
