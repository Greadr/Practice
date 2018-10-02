import csv
import json
import ast
import asyncio
import asyncpg
from shapely.geometry import Polygon

def write_csv(data,i):
    with open ('promzones_renovation.csv', 'a', encoding='utf-8') as f:
        order = ['name', 'polygon', 'status', 'func', 'url']
        writer = csv.DictWriter(f, fieldnames=order)
        if i==0:
           writer.writeheader()
        writer.writerow(data)

path = 'promzones.json'

with open(path) as f:
    data = json.load(f)

#print (data[1])
for i in range(len(data)):
    write_data = {'name':data[i]['name'],
                  'polygon':ast.literal_eval(data[i]['polygon'])[0],
                  'status': data[i]['status'], 
                  'func': data[i]['func'], 
                  'url': data[i]['url']}
    some_poly = Polygon([[p[0], p[1]] for p in write_data['polygon']])
    write_data['polygon'] = some_poly  
    write_csv(write_data,i)
    print (write_data)

