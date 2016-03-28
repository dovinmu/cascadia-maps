width = 1200
height = 1200

svg = d3.select('body').append('svg')
    .attr('width', width)
    .attr('height', height)

svg.append('text')
    .attr('x', (width/4))
    .attr('y', (height/10))
    .attr('class', 'mapname')
    .text('Oregon state ecoregions')

projection = d3.geo.mercator()
    .scale(100)
    .center([-120, 45])
    .translate([width/3, height/2])

path = d3.geo.path().projection(projection)

initMap = (error, oregon) ->
    if error then return
    data = topojson.feature(oregon, oregon.objects.oregon_l3_geo)
    svg.append('path')
        .datum(data)
        .attr('d', path)

d3.json('oregon_l3_topo.json', initMap)
