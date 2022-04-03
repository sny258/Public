from csv import reader
import requests

# open file in read mode
with open('test.csv', 'r') as read_obj:
    csv_reader = reader(read_obj)
    header = next(csv_reader)
    # Check file as empty
    if header != None:
        for row in csv_reader:
            print(row[0])
            api_url = "https://jsonplaceholder.typicode.com/todos"
            todo = {"userId": row[0], "title": row[1], "completed": row[2]}
            response = requests.post(api_url, json=todo)
            print(response.json())
            print(response.json()['userId'])
            print(response.status_code)
            print('-----------------------------')
