select UpdateGeometrySRID('moscow_iso','iso15_geom',32637);
select UpdateGeometrySRID('moscow_iso','iso10_geom',32637);
select UpdateGeometrySRID('moscow_iso','iso5_geom',32637);

SELECT id_0, geom, id, "name", 
lat, lng, st_transform(iso15_geom,4326) iso15_geom, st_transform(iso10_geom,4326) iso10_geom, st_transform(iso5_geom,4326) iso5_geom
into moscow_isochrones
FROM public.moscow_iso;

select moscow_isochrones."name", ST_Centroid(st_union(moscow_isochrones.geom)), st_union(moscow_isochrones.iso5_geom) iso5_geom, 
st_union(moscow_isochrones.iso10_geom) iso10_geom, st_union(moscow_isochrones.iso15_geom) iso15_geom
into moscow_isochrones_union
from moscow_isochrones
group by moscow_isochrones."name";

select moscow_iso.id_0, moscow_iso.id, moscow_isochrones_union."name", moscow_iso.lat, moscow_iso.lng ,moscow_iso.geom, moscow_isochrones_union.iso5_geom, 
moscow_isochrones_union.iso10_geom, moscow_isochrones_union.iso15_geom
into moscow_isochrones_union_full
from moscow_isochrones_union
inner join moscow_iso
on moscow_iso."name"=moscow_isochrones_union."name"