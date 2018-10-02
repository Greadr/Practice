-- dogs park creating
create table dogs_points (
	id serial,
	tag varchar,
	geom geometry,
	data_source varchar
);
create table dogs_polygons (
	id serial,
	tag varchar,
	geom geometry,
	data_source varchar
);

insert into dogs_polygons (tag, geom, data_source)
select leisure tag, geom, 'OpenStreetMap' data_source
from osm_polygons
where leisure='dog_park';

insert into dogs_points (tag, geom, data_source)
select leisure tag, geom, 'OpenStreetMap' data_source
from osm_points
where leisure='dog_park'
union all
select 'dog_park' tag, geom, 'data.mos' data_source
from dogs;



