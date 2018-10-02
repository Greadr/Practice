CREATE EXTENSION postgis CASCADE;

-- STOPS
-- filtering stops from trash like train platforms
SELECT id_0, geom, id, "@id", "name", operator, public_transport, "@relations", bus, trolleybus, tram, highway
into public_transport_filt
FROM public_transport
where bus='yes' or trolleybus='yes'or tram='yes' or highway='bus_stop' or public_transport='platform';

-- filtering bus routes that only intersects with big moscow boundary
select id_0, route_bus.geom, route_bus.id, "@id", "from", route_bus."name", network, 
	operator, payment_ca, payment_tr, public_tra, "ref", route, "to", "type"
into route_bus_moscow
from route_bus, Big_Moscow
where st_intersects(route_bus.geom, Big_Moscow.geom);
-- filtering stops that only intersects with big moscow boundary
select s.id_0, s.geom, s.id, s."@id", s."name", s.operator, s.public_transport, s."@relations", s.bus, s.trolleybus, s.tram, s.highway
into public_transport_filtered
from public_transport_filt s, big_moscow
where st_intersects(s.geom, Big_Moscow.geom);

-- minimal distance from stop to route.    Tram
SELECT p.id_0, p.geom, p."name", cjl.minimal
into minimal_dist_tram_stops
FROM public_transport_filtered p
CROSS JOIN LATERAL (
    SELECT min(st_distance(st_transform(r.geom,3857), st_transform(p.geom,3857))) as minimal 
    FROM route_tram r
    group by r.geom
    ORDER BY st_distance(r.geom, p.geom)
    LIMIT 1   
) cjl
where p.tram ='yes';
-- bus
SELECT p.id_0, p.geom, p."name", cjl.minimal
into minimal_dist_bus_stops
FROM public_transport_filtered p
CROSS JOIN LATERAL (
    SELECT st_distance(st_transform(r.geom,3857), st_transform(p.geom,3857)) as minimal 
    FROM route_bus r
    group by r.geom
    ORDER BY st_distance(r.geom, p.geom)
    LIMIT 1   
) cjl
where p.bus ='yes'or p.highway='bus_stop' and p.bus is null and p.public_transport!='platform' or
	p.public_transport='platform' and p.highway!='bus_stop'and p.bus is null;
SELECT p.id_0, p.geom, p."name", cjl.minimal
into minimal_dist_bus_stops_with_plat
FROM public_transport_filtered p
CROSS JOIN LATERAL (
    SELECT st_distance(st_transform(r.geom,3857), st_transform(p.geom,3857)) as minimal 
    FROM route_bus r
    group by r.geom
    ORDER BY st_distance(r.geom, p.geom)
    LIMIT 1   
) cjl
where p.public_transport='platform' and p.highway='bus_stop'and p.bus is null
union
select *
from minimal_dist_bus_stops;
-- trolley
SELECT p.id_0, p.geom, p."name", cjl.minimal
into minimal_dist_troll_stops
FROM public_transport_filtered p
CROSS JOIN LATERAL (
    SELECT st_distance(st_transform(r.geom,3857), st_transform(p.geom,3857)) as minimal 
    FROM route_trolleybus r
    group by r.geom
    ORDER BY st_distance(r.geom, p.geom)
    LIMIT 1   
) cjl
where p.trolleybus ='yes';

--check of different minimal distances of troll and bus
select t.id_0,  t.minimal troll, b.minimal bus
from minimal_dist_troll_stops t, minimal_dist_bus_stops_with_plat b
where t.minimal<100 and t.minimal!=b.minimal and t.id_0 = b.id_0;
select b.id_0, b.minimal bus
from minimal_dist_bus_stops_with_plat b;

--check of dubles between bus and trolley stops
delete from minimal_dist_troll_stops t using minimal_dist_bus_stops_with_plat b
where t.id_0=b.id_0;

--stops tables
select *
into stops_tram
from public_transport_filtered p
where p.tram ='yes';
select *
into stops_trolley
from public_transport_filtered p
where p.trolleybus ='yes';
select *
into stops_bus
from public_transport_filtered p
where p.bus ='yes' or
	p.highway='bus_stop' and p.bus is null and p.public_transport!='platform' and p.trolleybus!='yes' or
	p.public_transport='platform' and p.highway!='bus_stop'and p.bus is null and p.trolleybus!='yes' or
	p.public_transport='platform' and p.highway='bus_stop'and p.bus is null and p.trolleybus!='yes';

--giving prefix to name of routes
select id_0, geom, id, "@id", alt_ref, "from", "name", network, operator, payment_ca, 
payment_tr, public_tra, "ref" reference_raw, concat('Tm', "ref") reference, route, "to", "type", payment_cr, payment_de, via, descriptio, by_night, phone, website, "@relations"
into route_tram_refs
from route_tram;
select id_0, geom, id, "@id", "from", "name", network, operator, payment_ca, payment_tr, public_tra, 
"ref" reference_raw, concat('Av', "ref") reference, route, "to", "type"
into route_bus_moscow_refs
from route_bus_moscow;

select id_0, geom, id, "@id", "from", "name", "ref" reference_raw, concat('Tl', "ref") reference, route, "to", "type", 
operator, network, payment_ca, payment_tr, public_tra, payment_cr, payment_de, colour, direction, via, "@relations"
into route_trolleybus_refs
from route_trolleybus;

-- stops with references
select s.id_0, s.geom, string_agg(distinct(r.reference_raw), ', ') as reference_raw,  
string_agg(distinct(r.reference), ', ') reference
into stops_tram_references
from route_tram_refs r, minimal_dist_tram_stops s
where @(st_distance(st_transform(r.geom,3857), st_transform(s.geom,3857))-s.minimal)<20 and s.minimal<100
group by s.id_0, s.geom;

select s.id_0, s.geom, string_agg(distinct(r.reference_raw), ', ') as reference_raw, 
string_agg(distinct(r.reference), ', ') reference
into stops_trolley_references
from route_trolleybus_refs r, minimal_dist_troll_stops s
where @(st_distance(st_transform(r.geom,3857), st_transform(s.geom,3857))-s.minimal)<20 and s.minimal<100
group by s.id_0, s.geom;

-- only buses stops (where are 2 ways: by buffers and by distances)
-- way with buffers (fast,  but not accurate)
/*select id_0, st_buffer(st_transform(r.geom,3857),100) geom, id, "@id", "from", "name", network, operator, payment_ca, payment_tr, 
public_tra, reference_raw, reference, route, "to", "type"
into route_bus_moscow_refs_buffer
from route_bus_moscow_refs r;

CREATE INDEX "route_bus_moscow_refs_buffer_st_geom_idx" ON "route_bus_moscow_refs_buffer" USING GIST (geom);
VACUUM analyze "route_bus_moscow_refs_buffer";

SELECT s.id_0, s.geom, cjl.reference_raw, cjl.reference
into stops_buses_bus_references_raw
FROM minimal_dist_bus_stops_with_plat s
CROSS JOIN LATERAL (
    SELECT r.geom, r.reference_raw, r.reference
    FROM route_bus_moscow_refs_buffer r
    where st_within(st_transform(s.geom,3857), st_transform(r.geom,3857))
) cjl
where s.minimal<100; */

-- way with distance (very slow,  but accurate - 49 minutes remaining to process it)
SELECT s.id_0, s.geom, cjl.reference_raw, cjl.reference
into stops_buses_bus_references_raw
FROM minimal_dist_bus_stops_with_plat s
CROSS JOIN LATERAL (
    SELECT r.geom, r.reference_raw, r.reference
    FROM route_bus_moscow_refs r
    where @(st_distance(st_transform(r.geom,3857), st_transform(s.geom,3857))-s.minimal)<50
) cjl
where s.minimal<100;

-- string_agg routes of stops
select r.id_0, r.geom, string_agg(distinct(r.reference_raw), ', ') as reference_raw, string_agg(distinct(r.reference), ', ') reference
into stops_buses_bus_references
from stops_buses_bus_references_raw r
group by r.id_0, r.geom;

--only trolleys on busses stops
select s.id_0, s.geom, string_agg(distinct(t.reference_raw), ', ') as reference_raw, 
string_agg(distinct(t.reference), ', ') reference
into stops_buses_trolley_references
from minimal_dist_bus_stops_with_plat s, route_trolleybus_refs t
where @(st_distance(st_transform(t.geom,3857), st_transform(s.geom,3857))-s.minimal)<50 and s.minimal<100
group by s.id_0, s.geom;

-- concat stops with buses and trolleys
select b.id_0, b.geom, concat(b.reference_raw, ', ', t.reference_raw) reference_raw, concat(b.reference,', ', t.reference) reference
into stops_buses_with_trolleys
from stops_buses_bus_references b, stops_buses_trolley_references t
where b.id_0=t.id_0;

-- unite all bus and trolley stops
select *
into stops_bus_trolley
from stops_buses_with_trolleys bt
union
select b.id_0, b.geom, b.reference_raw, b.reference
from stops_buses_with_trolleys bt
right join stops_buses_bus_references b
on bt.id_0=b.id_0
where bt.id_0 is null;

-- union trams buses n trolleys
insert into stops_bus_trolley
select *
from stops_tram_references;

--counting of routes by type
ALTER TABLE stops_bus_trolley ADD count_tram int;
ALTER TABLE stops_bus_trolley ADD count_trolley int;
ALTER TABLE stops_bus_trolley ADD count_bus int;
update stops_bus_trolley s set count_tram = (length(s.reference)-length(replace(s.reference, 'Tm', '')))/2;
update stops_bus_trolley s set count_trolley = (length(s.reference)-length(replace(s.reference, 'Tl', '')))/2;
update stops_bus_trolley s set count_bus = (length(s.reference)-length(replace(s.reference, 'Av', '')))/2;

--ROUTES
select r.id_0, r.geom, r.reference_raw, r.reference, r."name" route_name, r.route transport_type
into routes_all
from route_bus_moscow_refs r
union
select r.id_0, r.geom, r.reference_raw, r.reference, r."name" route_name, r.route transport_type
from route_trolleybus_refs r
union
select r.id_0, r.geom, r.reference_raw, r.reference, r."name" route_name, r.route transport_type
from route_tram_refs r;

--checking lack of routes
select w.route, w.transport_type
into exception_routes
from routes_all r
right join 	routes_wikiroutes w
on w.route=r.reference_raw
where r.reference_raw is null;
