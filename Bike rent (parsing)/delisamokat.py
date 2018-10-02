import csv
import json
import ast
from shapely.geometry import Point
import pandas as pd

def write_csv(data):
    with open ('delisamokat.csv', 'a', encoding='utf-8') as f:
        order = ['id', 'geom', 'active', 'available_vehicles',
                 'max_vehicles', 'name', 'translated_name',
                 'total_vehicles']
        writer = csv.DictWriter(f, fieldnames=order)
        try:
            df = pd.read_csv('delisamokat.csv')
        except:
            writer.writeheader()
        writer.writerow(data)

path = 'delisamokat.json'

with open(path, 'r', encoding='utf-8') as f:
    parsed = json.load(f)
    print (json.dumps(parsed['data'][1], indent=4, sort_keys=True))
    for row in parsed['data']:
        if row['city_id']==1:
            data = {'id':row['id'], 'geom':Point(row['lng'], row['lat']),
                    'active':row['active'], 
                    'available_vehicles':row['available_vehicles'], 
                    'max_vehicles':row['max_vehicles'],
                    'name':row['name'],
                    'translated_name':row['translated_name'],
                    'total_vehicles':row['total_vehicles']
                    }
            write_csv(data)
