import geopandas as gpd
import csv

def write_csv(data,i):
    with open ('try.csv', 'a') as f:
        order = ['geom','CommonName', 'global_id', 'FullName']
        writer = csv.DictWriter(f, fieldnames=order)
        if i==0:
           writer.writeheader()
        writer.writerow(data)

path = 'D:\Temp\check.json'

file = gpd.read_file(path)

#for attr in file['Attributes']:
#    print (attr.keys())
    
print (file['Attributes'][0].keys())

for i in range(len(file['Attributes'])):
#    print (attr.keys())
    data = {'geom':file.loc[i]['geometry'],
            'CommonName':file['Attributes'][i]['CommonName'], 
            'global_id':file['Attributes'][i]['global_id'], 
            'FullName':file['Attributes'][i]['FullName']}
    write_csv(data,i)
    print (data)
