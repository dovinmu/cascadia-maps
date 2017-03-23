width = 1160
height = 1160
treename = "alnurubr"

Array::unique = ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output

svg = d3.select('body').append('svg')
    .attr('width', width)
    .attr('height', height)

svg.append('text')
    .attr('x', (width/4))
    .attr('y', (height/10))
    .attr('class', 'mapname')
    .text(treename)

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
    # console.log selected
    # console.log d
    #if selected
    #    selected.style('fill', 'black')
    selected = d3.select(this)
    tree_id = selected.attr('id')
    tree_class = selected.attr('class')
    console.log "select all: ", tree_class
    if tree_id
        region_class = tree_class.split(' ')[1]
        tree_class = '.' + tree_class.split(' ')[2]
        fill = '#000'
        if region_class == ""
            fill = '#333'
        else if region_class == ""
            fill = '#666'
        else if region_class == ""
            fill = '#999'
        d3.selectAll(tree_class)
          .style('fill', fill)
          .attr('id', null)
    else
        tree_class = '.' + tree_class.split(' ')[2]
        d3.selectAll(tree_class)
          .style('fill', 'red')
          .attr('id', 'in-map')

    # changeText(d.id.split(' ')[2..].join(' '))
    changeText(d.id)

onSubmit = (d, i) ->
    console.log "selecting reds for " + treename
    treemap = []
    selected = d3.selectAll("#in-map")
        .each((d) ->
            treemap.push '"' + d.id + '",'
            # console.log d
            )
    console.log treemap.unique().join('\n')

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

# to get list of regions where the tree exists
submitText = svg.append('text')
  .attr('x', (width - 200))
  .attr('y', (height/8 + 5))
  .attr('class', 'submit')
  .text('Submit')
  .on('click', onSubmit)

initMap = (error, ecotopo) ->
    if error then return console.log error

    data = topojson.feature(ecotopo, ecotopo.objects.ecoregions)

    feature_string = ""
    # for feature in data.features
    #   feature_string += '"' + feature.id + '",\n'
    # console.log feature_string
    #add level 4 ecosystems
    svg.selectAll('.subunit')
        .data(data.features).enter()
        .append('path')
        .attr('class', getClassName)
        .on('click', onClick)
        .attr('d', path)

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

drawDot = (x,y) ->
    coordinates = projection([x,y]);
    svg.append('circle')
        .attr('cx', coordinates[0])
        .attr('cy', coordinates[1])
        .attr('r', 2)
        .style('fill', 'purple')

drawSHP = (shp, source) ->
    if not shp.done
        # console.log shp.value.geometry.coordinates[0][0]
        for coords in shp.value.geometry.coordinates[0]
            drawDot(coords[0], coords[1])
        svg.selectAll('.trees')
          .data(shp.value.geometry).enter()
          .append('path')
          .style('fill', 'green')
          .attr('d', path)
        source.read().then((shp) -> drawSHP(shp, source))
    else
        console.log "done"

console.log "drawing dem trees"
shapefile.open("tree_range/"+treename+".shp", null)
    .then((source) ->
        source.read().then((shp) -> drawSHP(shp, source))
    )
    .catch((error) ->
        console.log "aww heck"
        console.log error
    )
changeText('', 'Click on an ecological subregion to see its name.')
