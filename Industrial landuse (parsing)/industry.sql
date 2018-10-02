CREATE EXTENSION postgis CASCADE;

-- getting "toxic" points
SELECT obj_name, ST_SetSRID(ST_MakePoint(cast(split_part(point, ' ', 2) as float), cast(split_part(point, ' ', 1) as float)), 4326) geom, 'ТЭЦ' category
into toxic_points
from tecs
union all
select obj_name, (ST_Dump(geom)).geom geom, 'РТС' category
from rts
union all
select "ShortName" obj_name, geom, "Specialization" category
from datamos_industrias
where "Specialization" like 'Нефтеперерабатывающая промышленность%' or "Specialization" like'Металлургическая промышленность%';

-- getting poly of industry land
select row_number() over (ORDER BY geom) u_id, "name" obj_name, geom, status
into industrial_zones
from all_promzones
union all
select row_number() over (ORDER BY geom)+59 u_id, "name" obj_name, geom, 'renovation' status
from promzones_renovation;

-- work with wikimapia data

select *
into wikimapia_promzones_all
from wikimapia_promzones
union all
select *
from wikimapia_promzones2;

select a.poly_id
into poly_id_renovation
from wikimapia_promzones_all a, promzones_renovation r
where st_intersects(a.geom, r.geom);
select a.poly_id
into poly_id_exist
from wikimapia_promzones_all a
except
select * from poly_id_renovation;

select a.poly_id, a."name", a.geom, 'renovation' status
into industrial_zones
from wikimapia_promzones_all a, poly_id_renovation r
where r.poly_id=a.poly_id
union all
select a.poly_id, a."name", a.geom, 'exist' status
from wikimapia_promzones_all a, poly_id_exist r
where r.poly_id=a.poly_id;

select distinct a.poly_id, a."name", a.geom, status
into industrial_zones_moscow
from industrial_zones a, boundary_polygon b
where st_intersects(a.geom, b.geom);