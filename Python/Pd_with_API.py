import pandas as pd
import requests

# df = pd.read_excel(r"C:\Users\soura\Desktop\New Microsoft Excel Worksheet.xlsx")
# print(df)
# filtered_df = df[(df.Title == 'app2') & (df.Completed == False )]
# filtered_df

df = pd.read_csv('test.csv')
api_url = "https://jsonplaceholder.typicode.com/todos"
s1 = ""
for index, value in df.iterrows():
    val1 = value.to_dict()
    response = requests.post(api_url, json=val1)
    s1 = s1 + str((response.json()['userId'])) + "\n"   #Case-Sensitive

with open ('abc.txt', 'w') as file:
    file.write(s1)
