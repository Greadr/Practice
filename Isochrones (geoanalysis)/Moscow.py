import osmnx as ox, networkx as nx, geopandas as gpd, matplotlib.pyplot as plt
from shapely.geometry import Point, LineString, Polygon
from descartes import PolygonPatch
ox.config(log_console=True, use_cache=True)
import csv
import pandas as pd

# configure the place, network type, trip times, and travel speed
place = 'Moscow, Russia'
network_type = 'walk'
trip_times = [5, 10, 15] #in minutes
travel_speed = 4.5 #walking speed in km/hour

#G = ox.graph_from_place(place, network_type=network_type, simplify=False)

G = ox.load_graphml(filename='moscow.graphml')
#ox.save_graphml(G, filename='moscow.graphml')

# add an edge attribute for time in minutes required to traverse each edge
meters_per_minute = travel_speed * 1000 / 60 #km per hour to m per minute
for u, v, k, data in G.edges(data=True, keys=True):
    data['time'] = data['length'] / meters_per_minute

def make_iso_polys(G, edge_buff=25, node_buff=50, infill=False):
    isochrone_polys = []
    for trip_time in sorted(trip_times, reverse=True):
        print ('Beginning subgraph')
        subgraph = nx.ego_graph(G, center_node, radius=trip_time, distance='time')
        print ('Beginning nodes')
        node_points = [Point((data['x'], data['y'])) for node, data in subgraph.nodes(data=True)]
        nodes_gdf = gpd.GeoDataFrame({'id': subgraph.nodes()}, geometry=node_points)
        nodes_gdf = nodes_gdf.set_index('id')
        print ('Beginning lines')
        edge_lines = []
        for n_fr, n_to in subgraph.edges():
            f = nodes_gdf.loc[n_fr].geometry
            t = nodes_gdf.loc[n_to].geometry
            edge_lines.append(LineString([f,t]))

        n = nodes_gdf.buffer(node_buff).geometry
        e = gpd.GeoSeries(edge_lines).buffer(edge_buff).geometry
        all_gs = list(n) + list(e)
        new_iso = gpd.GeoSeries(all_gs).unary_union
        
        # try to fill in surrounded areas so shapes will appear solid and blocks without white space inside them
        if infill:
            new_iso = Polygon(new_iso.exterior)
        isochrone_polys.append(new_iso)
    return isochrone_polys

def write_csv(data,i):
    with open('moscow_iso.csv', 'a') as f:
        order = ['id', 'name', 'lat', 'lng', 'geom', 'iso15_geom', 'iso10_geom', 'iso5_geom']
        writer = csv.DictWriter(f, delimiter=';', fieldnames=order)
        if i==0:
            writer.writeheader()
        writer.writerow(data)

df = pd.read_csv('metro.csv', names=['id', 'name', 'lat', 'lng', 'geom'], sep=';',skiprows=1)


for i in range (len(df.index)):
    print ('Beginning get_nearest_node')
    center_node = ox.get_nearest_node(G, (df.iloc[i]['lat'], df.iloc[i]['lng']))
    if i == 0:
        print ('Beginning project')
        G_projected = ox.project_graph(G)
        print ('Beginning saving')
        #ox.save_graphml(G_projected, filename='moscow_projected.graphml')
#        G2 = ox.simplify_graph(G_projected)
#        Gi = ox.clean_intersections(G2, tolerance=15, dead_ends=False)
    print ('Beginning make_iso')
    isochrone_polys = make_iso_polys(G_projected, edge_buff=25, node_buff=0, infill=True)
    data = {'id':df.loc[i]['id'], 'name':df.loc[i]['name'], 'lat':df.loc[i]['lat'], 'lng':df.loc[i]['lat'],
            'geom':df.loc[i]['geom'], 'iso15_geom':isochrone_polys[0], 'iso10_geom':isochrone_polys[1], 'iso5_geom':isochrone_polys[2]}
    write_csv(data,i)
