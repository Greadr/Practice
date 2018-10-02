import csv
import json
import ast
from shapely.geometry import Point
import pandas as pd

def write_csv(data):
    with open ('velobike.csv', 'a', encoding='utf-8') as f:
        order = ['Address', 'Id', 'IsLocked', 'Geom',
                 'TotalPlaces', 'TotalOrdinaryPlaces', 'TotalElectricPlaces',
                 'FreeOrdinaryPlaces', 'FreeElectricPlaces']
        writer = csv.DictWriter(f, fieldnames=order)
        try:
            df = pd.read_csv('velobike.csv')
        except:
            writer.writeheader()
        writer.writerow(data)

path = 'velobike.json'

with open(path, 'r', encoding='utf-8') as f:
    parsed = json.load(f)
    print (json.dumps(parsed['Items'][52], indent=4, sort_keys=True))
    for row in parsed['Items']:
        data = {'Address':row['Address'], 'Id':row['Id'],
                'IsLocked':row['IsLocked'], 
                'Geom':Point(row['Position']['Lon'], row['Position']['Lat']),
                 'TotalPlaces':row['TotalPlaces'], 
                 'TotalOrdinaryPlaces':row['TotalOrdinaryPlaces'],
                 'TotalElectricPlaces':row['TotalElectricPlaces'],
                 'FreeOrdinaryPlaces':row['FreeOrdinaryPlaces'],
                 'FreeElectricPlaces':row['FreeElectricPlaces']
                }
        write_csv(data)
