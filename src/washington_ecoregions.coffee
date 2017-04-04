width = 1350
height = 1160
selected = null
region_trees = {}
sizes = {x:90, y:180, padding:10}

svg = d3.select('body').append('svg')
    .attr('width', width)
    .attr('height', height)

svg.append('text')
    .attr('x', (width/6))
    .attr('y', (50))
    .attr('class', 'mapname')
    .text('Washington state ecoregions')

projection = d3.geo.mercator()
    .scale(7500)
    .center([-121.5, 46.5])
    .translate([width/3, height/2])

path = d3.geo.path().projection(projection)

getClassName = (d) ->
    l4 = d.id.split(' ')[2..]
    l1 = d.properties.L1.split(' ')[2..]
    return 'subunit ' + l1.join('_') + ' ' + l4.join('_').replace('/', '_')

showImage = (name, i) ->
    fname = name.toLowerCase().replace(/ /g, '_') + ".jpg"
    # console.log "appending " + fname, i
    y = 100 + (i//3) * (sizes.y + sizes.padding)
    if i % 3 == 0
      x = width - 3 * (sizes.x + sizes.padding)
    if i % 3 == 1
      x = width - 2 * (sizes.x + sizes.padding)
    if i % 3 == 2
      x = width - 1 * (sizes.x + sizes.padding)
    svg.append("svg:image")
      .attr("xlink:href", "images/" + fname)
      .attr("x", x)
      .attr("y", y)
      .attr("width", sizes.x)
      .attr("height", sizes.y)

removeImages = () ->
    # console.log "removing"
    svg.selectAll("image").remove()

onClick = (d, i) ->
    if selected
        selected.style('stroke', 'none')
    removeImages()
    selected = d3.select(this)
    selected.style('stroke', 'red')
    tree_list = region_trees[d.id]
    changeText(d.id.split(' ')[2..].join(' '), tree_list.join(', '))
    yOffset = 0
    showImage tree,i for tree,i in tree_list
    # showImage("Douglas Fir")

processTree = (tree) ->
    console.log "~~~" + tree["common"] + "~~~"
    # we need to lookup a region to get the tree
    region_trees[region].push(tree["common"]) for region in tree["regions"]

loadJson = (fname) ->
    console.log "loading", fname
    fetch(fname, {method:'get'})
        .then((response) -> response.json())
        .then((json) -> processTree tree for tree in json["trees"])
        .then(() -> console.log region_trees)
        .catch((e) ->
          console.log "FLAGRANT ERROR:", e
        )

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
        .attr("x", (width/3))
        .attr("y", (height/7))
        .attr("class", "label")
        .text("Northwestern Forested Mountains")
    svg.append("text")
        .attr("x", (width/2.3))
        .attr("y", (height/2))
        .attr("class", "label")
        .text("North American Deserts")
    svg.append("text")
        .attr("x", (width/10))
        .attr("y", (height/3))
        .attr("class", "label")
        .text("Marine West Coast Forest")

    region_trees[path.id] = [] for path in data.features
    loadJson('trees_wa.json')

#ecoregion name display
selectedText = svg.append('text')
.attr('x', (width/6 + 8))
.attr('y', (70))
.attr('class', 'selected title')
.text('')
#ecoregion detail displays
selectedTextDetail = svg.append('text')
.attr('x', (width/6 + 8))
.attr('y', (85))
.attr('class', 'selected detail')
.text('')

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
