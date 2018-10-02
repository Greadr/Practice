CREATE EXTENSION postgis CASCADE;

-- find the most popular tags
select a.leisure, count(a.leisure) counting
into leisure_count
from (
	select p.leisure
	from osm_points p
	union all
	select pl.leisure
	from osm_polygons pl
	union all
	select 'DATA_MOS_culture_houses' leisure
	from houses_culture
	union all
	select 'DATA_MOS_leisure_with_children' leisure
	from places_leis_children
	union all
	select 'DATA_MOS_sport' leisure
	from sport
	union all
	select 'DATA_MOS_dogs' leisure
	from dogs
) a
group by a.leisure
order by counting DESC;

-- only more then 100 objects
delete from leisure_count where counting<100;

create table leisure_points (
	id serial,
	tag varchar,
	geom geometry,
	data_source varchar
);
create table leisure_polygons (
	id serial,
	tag varchar,
	geom geometry,
	data_source varchar
);

insert into leisure_polygons (tag, geom, data_source)
select pl.leisure tag, pl.geom, 'OpenStreetMap' data_source
from osm_polygons pl, leisure_count c
where pl.leisure=c.leisure;

insert into leisure_points (tag, geom, data_source)
select pl.leisure tag, pl.geom, 'OpenStreetMap' data_source
from osm_points pl, leisure_count c
where pl.leisure=c.leisure
union all
select 'children_leisure' tag, pl.geom, 'data.mos' data_source
from places_leis_children pl
union all
select 'sports_centre' tag, s.geom, 'data.mos' data_source
from sports s;