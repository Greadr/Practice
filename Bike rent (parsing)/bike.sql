CREATE EXTENSION postgis CASCADE;

-- creating buffers
select id, st_transform(st_buffer(st_transform(u.geom,32637), 200), 4326) geom, code, arrivals, 
	average, departures, dayscount_total, slots, "name" name_st, unique_clients, unique_rides, roundtrips
into urbica_row_buff
from urbica_row u;


-- spatial index
CREATE INDEX "urbica_row_buff_st_geom_idx" ON "urbica_row_buff" USING GIST (geom);
VACUUM analyze "urbica_row_buff";
CREATE INDEX "velobike_buff_st_geom_idx" ON "velobike_buff" USING GIST (geom);
VACUUM analyze "velobike_buff";
CREATE INDEX "shop_polygon_st_geom_idx" ON "shop_polygon" USING GIST (geom);
VACUUM analyze "shop_polygon";
CREATE INDEX "amenity_polygon_st_geom_idx" ON "amenity_polygon" USING GIST (geom);
VACUUM analyze "amenity_polygon";

-- count pois for urbica_row

select u.code, count(api.geom)
--into count_poi_api
from urbica_row_buff u, amenity_point api
where st_intersects(u.geom, api.geom)
group by u.code;

select u.code, count(spi.geom)
--into count_poi_spi
from urbica_row_buff u, shop_point spi
where st_intersects(u.geom, spi.geom)
group by u.code;

select u.code, count(spo.geom)
into count_poi_spo
from urbica_row_buff u, shop_polygon spo
where st_intersects(u.geom, spo.geom)
group by u.code;

-- unite count POI
select geom, u.code, arrivals, 
	average, departures, dayscount_total, slots, "name" name_st, unique_clients, unique_rides, roundtrips, 
	COALESCE(spo."count",0)+COALESCE(spi."count",0)+COALESCE(api."count",0) all_poi_200m
into urbica_row_poi
from urbica_row u
left join count_poi_spo spo on u.code=spo.code
left join count_poi_spi spi on u.code=spi.code
left join count_poi_api api on u.code=api.code;

--nearest metro

select
from urbica_row u
left join metro m on u.geom<

SELECT u.code, u.geom, st_distance(st_transform(cjl.geom,32637),st_transform(u.geom,32637)), 
	(COALESCE(u.arrivals,0) + COALESCE(u.departures,0))/COALESCE(u.dayscount_total,0) rides_per_day
into urbica_row_metro_dist
FROM urbica_row u
CROSS JOIN LATERAL (
    SELECT m.geom, m.id 
    FROM metro m
    ORDER BY st_transform(u.geom,32637)<#>st_transform(m.geom,32637)
    LIMIT 1
) cjl;

--count leisure
CREATE INDEX "leisure_polygon_st_geom_idx" ON "leisure_polygon" USING GIST (geom);
VACUUM analyze "leisure_polygon";

select u.code, count(lpol.geom)
into count_leisure_pol
from urbica_row_buff u, leisure_polygon lpol
where st_intersects(u.geom, lpol.geom)
group by u.code;

select u.code, count(lpoi.geom)
into count_leisure_point
from urbica_row_buff u, leisure_point lpoi
where st_intersects(u.geom, lpoi.geom)
group by u.code;

-- unite count POI
select u.geom, u.code, arrivals, 
	average, departures, dayscount_total, name_st, unique_clients, unique_rides, roundtrips, 
	(COALESCE(u.arrivals,0) + COALESCE(u.departures,0))/COALESCE(u.dayscount_total,0) rides_per_day, slots,
	COALESCE(spo."count",0)+COALESCE(spi."count",0)+COALESCE(api."count",0) all_poi_200m, 
	COALESCE(lpi."count",0)+COALESCE(lpol."count",0) all_leisure_200m,
	dist.st_distance distance_to_metro
into urbica_row_poi_leisure_metro
from urbica_row_poi u
left join count_poi_spo spo on u.code=spo.code
left join count_poi_spi spi on u.code=spi.code
left join count_poi_api api on u.code=api.code
left join count_leisure_point lpi on u.code=lpi.code
left join count_leisure_pol lpol on u.code=lpol.code
left join urbica_row_metro_dist dist on u.code=dist.code;

-- unite exist rides of velo with samo

select v."Id" id, v.geom, v."Address" address, v."IsLocked" is_locked, 'Велосипед' station_type, 
	v."TotalPlaces" totalplaces, u.rides_per_day 
into result_temp
from velobike v
inner join urbica_row_poi_leisure_metro u on st_distance(st_transform(v.geom,32637),st_transform(u.geom,32637))<15
where v."TotalElectricPlaces"=0
union all
select v."Id" id, v.geom, v."Address" address, v."IsLocked" is_locked, 'Велосипед и электровелосипед' station_type, 
	v."TotalPlaces" totalplaces, Null rides_per_day
from velobike v
where v."TotalElectricPlaces">0;

select v."Id" id, v.geom, v."Address" address, v."IsLocked" is_locked, 'Велосипед' station_type, 
	v."TotalPlaces" totalplaces, null rides_per_day 
into result_rent_bikes
from velobike v
inner join (select v."Id" id
	from velobike v
	except 
	select r.id
	from result_temp r) a on a.id=v."Id"
union all
select *
from result_temp
union all
select d.id+1000 id, d.geom, d."name" address, 'False' is_locked, 'Самокат' station_type, 
	d.total_vehicles totalplaces, null rides_per_day
from delisamokat d;

alter table result_rent_bikes ADD column lng numeric(8);
update result_rent_bikes set lng=st_x(geom);
alter table result_rent_bikes ADD column lat numeric(8);
update result_rent_bikes set lat=st_y(geom);

