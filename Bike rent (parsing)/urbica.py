import csv
import json
import ast
from shapely.geometry import Point
import pandas as pd

def write_csv(data):
    with open ('urbica_row.csv', 'a', encoding='utf-8') as f:
        order = ['code', 'arrivals', 'average',
                 'departures', 'dayscount_total', 'geom',
                 'slots', 'name', 'unique_clients', 'unique_rides', 'roundtrips']
        writer = csv.DictWriter(f, fieldnames=order)
        try:
            df = pd.read_csv('urbica_row.csv')
        except:
            writer.writeheader()
        writer.writerow(data)  

path = 'stations_all_urbica.json'

with open(path, 'r', encoding='utf-8') as f:
    parsed = json.load(f)
#    print (json.dumps(parsed[55], indent=4, sort_keys=True))
    for row in parsed:
        data = {'code':row['code'], 'arrivals':row['arrivals'],
                'average':row['average'], 'departures':row['departures'], 
                 'dayscount_total':row['dayscount']["total"], 
                 'geom':Point(row['lon'], row['lat']), 'slots':row['slots'], 
                 'name':row['name'], 'unique_clients':row['unique_clients'],
                 'unique_rides':row['unique_rides'], 'roundtrips':row['roundtrips']
                }
        write_csv(data)