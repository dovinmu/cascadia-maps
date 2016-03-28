width = 1160
height = 1160

svg = d3.select('body').append('svg')
    .attr('width', width)
    .attr('height', height)

svg.append('text')
    .attr('x', (width/4))
    .attr('y', (height/10))
    .attr('class', 'mapname')
    .text('Washington state ecoregions')

projection = d3.geo.mercator()
    .scale(7500)
    .center([-122, 47])
    .translate([width/3, height/2])

path = d3.geo.path().projection(projection)

getClassName = (d) ->
    l4 = d.id.split(' ')[2..]
    l1 = d.properties.L1.split(' ')[2..]
    return 'subunit ' + l1.join('_') + ' ' + l4.join('_').replace('/', '_')

selected = null

onClick = (d, i) ->
    console.log selected
    if selected
        selected.style('stroke', 'none')
    selected = d3.select(this)
    selected.style('stroke', 'red')
    changeText(d.id.split(' ')[2..].join(' '))

#ecoregion name display
selectedText = svg.append('text')
.attr('x', (width/4 + 8))
.attr('y', (height/8 + 5))
.attr('class', 'selected title')
.text('')
#ecoregion detail displays
selectedTextDetail = svg.append('text')
.attr('x', (width/4 + 8))
.attr('y', (height/8 + 20))
.attr('class', 'selected detail')
.text('')

initMap = (error, ecotopo) ->
    if error then return console.log error

    data = topojson.feature(ecotopo, ecotopo.objects.ecoregions)
    #add level 4 ecosystems
    svg.selectAll('.subunit')
        .data(data.features).enter()
        .append('path')
        .attr('class', getClassName)
        .on('click', onClick)
        .attr('d', path)
    #add level 1 ecosystem labels
    svg.append("text")
        .attr("x", (width/2.5))
        .attr("y", (height/5.5))
        .attr("class", "label")
        .text("Northwestern Forested Mountains");
    svg.append("text")
        .attr("x", (width/1.8))
        .attr("y", (height/2))
        .attr("class", "label")
        .text("North American Deserts");
    svg.append("text")
        .attr("x", (width/9))
        .attr("y", (height/2))
        .attr("class", "label")
        .text("Marine West Coast Forest");

changeText = (text, textDetail) ->
    selectedText
        .transition().duration(100)
        .style('opacity', 0)
        .transition().duration(350)
        .style('opacity', 1)
        .text(text)
    if not textDetail
        textDetail = ''
    selectedTextDetail
        .transition().duration(100)
        .style('opacity',0)
        .transition().duration(350)
        .style('opacity',1)
        .text(textDetail)

d3.json("washington.topojson", initMap)
changeText('', 'Click on an ecological subregion to see its name.')
