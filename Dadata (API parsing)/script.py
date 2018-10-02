from dadata import DaDataClient
import csv
import vertica_python
import time

conn_info_old = {'host': '***','port': 5433,'user': 'scriptor','password': 'dPQzakp9DM',
                 'database': 'msk','read_timeout': 600,'unicode_error': 'strict','ssl': False,'connection_timeout': 50}
columns_query = """select unom, address_full from temp.adresa_2;"""
connection = vertica_python.connect(**conn_info_old)
cur = connection.cursor()
cur.execute(columns_query)
data = cur.fetchall()
connection.close()
print (data[0])

    
def csv_headers(client):
    global order
    order=[]
    order.append('unom')
    with open('dadata_output.csv', 'a', encoding='utf-8') as f:
        headers = client.response.json()[0].keys()
        for header in headers:
            order.append(header)
        writer = csv.DictWriter(f, delimiter=';', fieldnames=order, quoting=csv.QUOTE_ALL)
        writer.writeheader()

def write_csv(data_row, order):
    with open('dadata_output.csv', 'a', encoding='utf-8') as f:
        writer = csv.DictWriter(f, delimiter=';', fieldnames=order, quoting=csv.QUOTE_ALL)
        writer.writerow(data_row)
        #

key = '***'
secret = '***'
client = DaDataClient(key = key, secret = secret)


addresses = data
print (addresses[0][1])
for i in range(0, len(addresses), 3): #len(addresses)
    print (i)
    addresses_for_request = []
    for row in addresses[i:i+3]:
        print (row)
        addresses_for_request.append(row[1])
    client.address = addresses_for_request
    time.sleep(1)
    client.address.request()
    if i==0:
        csv_headers(client)
    json_list = client.response.json()
    for n in range(len(json_list)):
        json_list[n]['unom'] = data[i+n][0]
        print  (json_list[n]['result'])
        write_csv(json_list[n], order)
###    
###
