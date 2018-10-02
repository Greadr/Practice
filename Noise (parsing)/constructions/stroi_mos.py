import csv
import json
import ast
from shapely.geometry import Polygon
from shapely.geometry import Point
import pandas as pd


def write_csv(data, geom_type):
    if geom_type=='polygon':
        with open ('constructions_polygons.csv', 'a', encoding='utf-8') as f:
            order = ['s_id', 'name', 'geom', 'status', 'func', 'url', 'address', 'end_year']
            writer = csv.DictWriter(f, fieldnames=order)
            try:
                df = pd.read_csv('constructions_polygons.csv')
            except:
                writer.writeheader()
            writer.writerow(data)
    else:
        with open ('constructions_points.csv', 'a', encoding='utf-8') as f:
            order = ['s_id', 'name', 'geom', 'status', 'func', 'url', 'address', 'end_year']
            writer = csv.DictWriter(f, fieldnames=order)
            try:
                df = pd.read_csv('constructions_points.csv')
            except:
                writer.writeheader()
            writer.writerow(data)        

path = 'construction.json'

with open(path, 'r', encoding='utf-8') as f:
    parsed = json.load(f)
    for row in parsed:
#        print (json.dumps(row, indent=4, sort_keys=True))
        geom_type=''
        if 'polygon' in row and row['polygon']!='' and len(ast.literal_eval(row['polygon'])[0])>2:
            geom_type='polygon'
            polygon = ast.literal_eval(row['polygon'])[0]
            geom = Polygon([[p[0], p[1]] for p in polygon])
        else:
            point = ast.literal_eval(row['coords'])
            geom = Point(point[0], point[1])
            
        if 'end_year' in row:  
            end_year = row['end_year']
        else:
            end_year=None
            
        if 'address' in row:  
            address = row['address']
        else:
            address=None        
        data={'s_id':row['id'],
              'name':row['name'], 
              'geom':geom,
              'status':row['status'],
              'func':row['func'],
              'url':row['url'],
              'address':address,
              'end_year':end_year
                }
        write_csv(data, geom_type)
    
#for i in range(len(data)):
#    write_data = {'name':data[i]['name'],
#                  'polygon':ast.literal_eval(data[i]['polygon'])[0],
#                  'status': data[i]['status'], 
#                  'func': data[i]['func'], 
#                  'url': data[i]['url']}
#    some_poly = Polygon([[p[0], p[1]] for p in write_data['polygon']])
#    write_data['polygon'] = some_poly  
#    write_csv(write_data,i)
#    print (write_data)

