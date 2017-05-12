width = 1350
height = 1160
selected = null
selectedTree = null
# lookup list of trees given a region
region_trees = {}
# lookup list of regions given a tree
tree_regions = {}
sizes = {x:90, y:180, padding:10}

overflow_limit = 25

# setup projection
svg = d3.select('body').append('svg')
    .attr('width', width)
    .attr('height', height)
projection = d3.geo.mercator()
    .scale(7500)
    .center([-121.5, 46.5])
    .translate([width/3, height/2])
path = d3.geo.path().projection(projection)

# map name
svg.append('text')
    .attr('x', (width/6))
    .attr('y', (50))
    .attr('class', 'mapname')
    .text('Washington state trees')

# project map and print names
initMap = (error, ecotopo) ->
    if error then return console.log error
    data = topojson.feature(ecotopo, ecotopo.objects.ecoregions)
    #add level 4 ecosystems
    svg.selectAll('.subunit')
        .data(data.features).enter()
        .append('path')
        .attr('class', getClassNameEco)
        .on('click', onClickEco)
        .attr('d', path)
    #add level 1 ecosystem labels
    svg.append("text")
        .attr("x", (width/3))
        .attr("y", (height/8))
        .attr("class", "label")
        .text("Northwestern Forested Mountains")
    svg.append("text")
        .attr("x", (width/2.3))
        .attr("y", (height/2.2))
        .attr("class", "label")
        .text("North American Deserts")
    svg.append("text")
        .attr("x", (width/20))
        .attr("y", (height/3.5))
        .attr("class", "label")
        .text("Marine West Coast Forest")

    region_trees[path.id] = [] for path in data.features
    loadJson('trees.json')

# create lists of regions <==> trees
processTree = (tree) ->
    console.log "~~~" + tree["common"] + "~~~"
    # make a table of regions to lists of trees in that region
    region_trees[region].push(tree["common"]) for region in tree["regions"]
    # make a table of trees to lists of regions that tree lives in
    tree_regions[getClassNameTree(tree["common"])] = tree["regions"]

loadJson = (fname) ->
    console.log "loading", fname
    fetch(fname, {method:'get'})
        .then((response) -> response.json())
        .then((json) -> processTree tree for tree in json["trees"])
        .then(() -> console.log region_trees)
        .catch((e) ->
          console.log "FLAGRANT ERROR:", e
        )

onClickTree = (d, i) ->
    if selectedTree
        d3.select(selectedTree).style('opacity', '1')
        region_list = tree_regions[selectedTree.id]
        d3.selectAll('.'+getSubClassNameEco(region)).style('opacity', '1') for region in region_list
    selectedTree = this
    d3.select(selectedTree).style('opacity', '0.5')
    region_list = tree_regions[selectedTree.id]
    d3.selectAll(".subunit").style('opacity', '0.25')
    d3.selectAll('.'+getSubClassNameEco(region)).style('opacity', '1') for region in region_list

onClickEco = (d, i) ->
    if selected
        selected.style('stroke', 'none')
    if selectedTree
        region_list = tree_regions[selectedTree.id]
        d3.selectAll('.'+getSubClassNameEco(region)).style('-webkit-filter', 'grayscale(0%)') for region in region_list
        selectedTree = null
    removeImages()
    selected = d3.select(this)
    selected.style('stroke', 'red')
    tree_list = region_trees[d.id]
    # changeText(d.id.split(' ')[2..].join(' '), tree_list.join(', '))
    changeText(d.id.split(' ')[2..].join(' '))
    yOffset = 0
    showImage tree,i for tree,i in tree_list

showImage = (name, i) ->
    id = getClassNameTree(name)
    fname = id + ".jpg"
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
      .attr("id", id)
      .on('click', onClickTree)

removeImages = () ->
    # console.log "removing"
    svg.selectAll("image").remove()

# helper function
getClassNameEco = (d) ->
    subclass = getSubClassNameEco(d.id)
    l1 = d.properties.L1.split(' ')[2..]
    return 'subunit ' + l1.join('_') + ' ' + subclass

getSubClassNameEco = (s) ->
    l4 = s.split(' ')[2..]
    return l4.join('_').replace('/', '_')

getClassNameTree = (s) ->
    return s.toLowerCase().replace(/ /g, '_')

splitText = (text) ->
    split = text.split(' ')
    result = ''
    while result.length < overflow_limit and split
        if result.length + split[0].length <= overflow_limit
          result += split.shift() + ' '
        else
          break
    return [result, split.join(' ')]

#ecoregion name display
selectedText = svg.append('text')
.attr('x', (width - width/4.5))
.attr('y', (70))
.attr('class', 'selected title')
.text('')

overflowText = svg.append('text')
.attr('x', (width - width/4.5))
.attr('y', (90))
.attr('class', 'selected title')
.text('')

#ecoregion detail displays
selectedTextDetail = svg.append('text')
.attr('x', (width/6 + 8))
.attr('y', (85))
.attr('class', 'selected detail')
.text('')

changeText = (text, textDetail) ->
    overflow = ''
    if text.length > overflow_limit
        list = splitText(text)
        text = list[0]
        overflow = list[1]
    selectedText
        .transition().duration(50)
        .style('opacity', 0)
        .transition().duration(250)
        .style('opacity', 1)
        .text(text)
    overflowText
        .transition().duration(50)
        .style('opacity', 0)
        .transition().duration(250)
        .style('opacity', 1)
        .text(overflow)
    if not textDetail
        textDetail = ''
    selectedTextDetail
        .transition().duration(50)
        .style('opacity',0)
        .transition().duration(250)
        .style('opacity',1)
        .text(textDetail)

d3.json("washington.topojson", initMap)
changeText('', 'Click on an ecological subregion to see its name.')
