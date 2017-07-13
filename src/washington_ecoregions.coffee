
selected = selectedTree = currentTreeId = null
# lookup list of trees given a region
region_trees = {}
# lookup list of regions given a tree
tree_regions = {}
# the original tree object, lookup by tree name
trees = {}

sizes = { x: 100, y: 180, padding: 3 }

overflow_limit = 25


width = height = 0
portrait = false

# map labels and text
mapTitle = mapDescription = treeMenuText = treeMenuOverflowText = marineLabel = mountainLabel = desertLabel = null
disclaimer = []
quote = []
treeMenuLat = treeMenuLon = 0

svg = d3.select('#map').append('svg')
    .attr('id', 'svg')

# setup projection
projection = path = null
makeProjection = () ->
    if portrait
        scaling = 7
        xTrans = width / 1.8
        yTrans = height / 3.5
    else
        scaling = 5
        xTrans = width / 2.4
        yTrans = width / 4.5
    projection = d3.geo.mercator()
        .scale(width * scaling)
        .center([-120.5, 47.75])
        .translate([xTrans, yTrans])

    path = d3.geo.path().projection(projection)

$("#disclaimer").click(() -> showDisclaimer())

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
      .style('fill', getColor)

    # Title
    mapTitle = svg.append('text')
      .attr('class', 'mapname')
      .text('Washington state evergreens')
    mapDescription = svg.append('text')
      .attr('class', 'selected detail')
      .text('Click on an ecoregion to see the list of evergreen trees native to it.')

    # Tree menu
    treeMenuText = svg.append('text')
      .attr('class', 'selected title')
      .text('')
    treeMenuOverflowText = svg.append('text')
      .attr('class', 'selected title')
      .text('')
    disclaimer.push(svg.append("text")
      .attr("class", "detail")
      .style('opacity', 0)
      .text(line)) for line,i in ["Tree ranges are based on the data ",
                                  "available and not guaranteed to be",
                                  "accurate."
                                 ]
    quote.push(svg.append("text")
      .attr("class", "quote")
      .style('opacity', 0)
      .text(line)) for line,i in ["A tree is beautiful, but what’s more, it has a right ",
                                  "to life; like water, the sun and the stars, it is ",
                                  "essential. Life on earth is inconceivable without trees.",
                                  " - Chekov"
                                 ]

    # Map labels
    mountainLabel = svg.append("text")
      .attr("class", "label")
      .text("Northwestern Forested Mountains")
    desertLabel = svg.append("text")
      .attr("class", "label")
      .text("North American Deserts")
    marineLabel = svg.append("text")
      .attr("class", "label")
      .text("Marine West Coast Forest")

    region_trees[path.id] = [] for path in data.features
    loadJson('trees.wa.json')
    resize()
    positionText()
    showQuote()

positionText = () ->
    # Title
    if portrait
        titleLat =  49.2
        titleLon = -124.2
    else
        titleLat =  49.2
        titleLon = -123.2
    coords = projection([titleLon, titleLat])
    mapTitle
        .attr('x', coords[0])
        .attr('y', coords[1])
    coords = projection([titleLon - 0.06, titleLat - 0.1])
    mapDescription
        .attr('x', coords[0])
        .attr('y', coords[1])

    #Tree menu
    if portrait
        treeMenuLat = 45.8
        treeMenuLon = -125
    else
        treeMenuLat = 49.1
        treeMenuLon = -116.9
    coordsText = projection([treeMenuLon, treeMenuLat])
    coordsOverflow = projection([treeMenuLon, treeMenuLat - 0.1])
    coordsParagraph = projection([treeMenuLon, treeMenuLat - 0.15])
    diff = projection([-122,47])[1] - projection([-122,47.08])[1]
    treeMenuText
        .attr('x', coordsText[0])
        .attr('y', coordsText[1])
    treeMenuOverflowText
        .attr('x', coordsOverflow[0])
        .attr('y', coordsOverflow[1])
    line
        .attr("x", coordsParagraph[0])
        .attr("y", coordsParagraph[1] + i * diff) for line,i in disclaimer
    line
        .attr("x", coordsParagraph[0])
        .attr("y", coordsParagraph[1] + i * diff) for line,i in quote

    # Map labels
    coords = projection([-121,48.75])
    mountainLabel
      .attr("x", coords[0])
      .attr("y", coords[1])

    coords = projection([-120.5,46.8])
    desertLabel
      .attr("x", coords[0])
      .attr("y", coords[1])

    coords = projection([-124.5,47.9])
    marineLabel
      .attr("x", coords[0])
      .attr("y", coords[1])


# create lists of regions <==> trees
processTree = (tree) ->
    console.log "~~~" + tree["common"] + "~~~"
    # make a table of regions to lists of trees in that region
    region_trees[region].push(tree["common"]) for region in tree["regions"]
    # make a table of trees to lists of regions that tree lives in
    className = getClassNameTree(tree["common"])
    tree_regions[className] = tree["regions"]
    trees[className] = tree

loadJson = (fname) ->
    console.log "loading", fname
    fetch(fname, {method:'get'})
        .then((response) -> response.json())
        .then((json) -> processTree tree for tree in json["evergreen"])
        # .then(() -> console.log region_trees)
        .catch((e) ->
          console.log "FLAGRANT ERROR:", e
        )

onClickTree = (d, i) ->
    if selectedTree
        d3.select(selectedTree).style('opacity', '1')
        region_list = tree_regions[selectedTree.id]
        d3.selectAll('.'+getSubClassNameEco(region)).style('opacity', '1').style('color', getColor) for region in region_list
    selectedTree = this
    # change tree opacities
    d3.selectAll('image').style('opacity', '0.5')
    d3.select(selectedTree).style('opacity', '1')
    hideLabels()

    # change region opacities
    region_list = tree_regions[selectedTree.id]
    d3.selectAll(".subunit").style('opacity', '0.25')
    d3.selectAll('.'+getSubClassNameEco(region)).style('opacity', '1') for region in region_list

    # change text
    name = selectedTree.id.split('_').join(' ')
    name = name.charAt(0).toUpperCase() + name.slice(1)
    description = trees[selectedTree.id]['latin']
    setTitleAndDescription(name, description)

onClickEco = (d) ->
    hideTreeMenuText()
    if selected
      selected.style('stroke', 'none')
      if selectedTree
        region_list = tree_regions[selectedTree.id]
        d3.selectAll('.subunit').style('opacity', '1') for region in region_list
        selectedTree = null
        setTitleAndDescription('Washington state evergreens', 'Click on an ecoregion to see the list of trees native to it.')
        showLabels()
    selected = d3.select(this)
    selected.style('stroke', 'red')
    drawTreeMenu(d.id)

drawTreeMenu = (treeId, selected) ->
    currentTreeId = treeId
    removeImages()
    if not treeId
        return
    tree_list = region_trees[treeId]
    setTreeMenuText(treeId.split(' ')[2..].join(' '))
    showImage tree,i for tree,i in tree_list

showImage = (name, i) ->
    id = getClassNameTree(name)
    fname = id + ".jpg"

    startCoords = projection([treeMenuLon, treeMenuLat - 0.2])
    stride = [sizes.x + sizes.padding, sizes.y + sizes.padding]
    if portrait
        horizontalCount = (width) // stride[0]
    else
        horizontalCount = 3 # TODO: actually compute this
    console.log "we can fit", horizontalCount, "trees"

    y = startCoords[1] + (i // horizontalCount) * stride[1]
    x = startCoords[0] + (i % horizontalCount) * stride[0]

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

lightenColor = (d, i) ->
    color = getColor(d, i)
    shadeColor2(color, 0.05)

getColor = (d, i) ->
    l1_dict = {'10':'#aa9900', '6':'#337711', '7':'#118855'}
    j = 0
    l4_dict = {}
    for letter, index in 'abcdefghijklmnopqrstuvwxyz'
        l4_dict[letter] = index

    l1 = d.properties.L1.split(' ')[0]
    l4 = d.id.split(' ')[0]
    l2 = parseInt(l4.slice(0, -1))
    letter = l4.slice(-1)

    base = l1_dict[l1]
    percent = (l4_dict[letter] % 5) / 10
    color = shadeColor2(base, percent)
    # console.log base, percent, color, d.properties.L1
    color

shadeColor2 = (color, percent) ->
    # hacker cowboy code copied from http://stackoverflow.com/questions/5560248/programmatically-lighten-or-darken-a-hex-color-or-rgb-and-blend-colors
    f = parseInt(color.slice(1),16)
    t = if percent<0 then 0 else 255
    p = if percent<0 then percent*-1 else percent
    R = f>>16
    G = f>>8&0x00FF
    B = f&0x0000FF
    return "#"+(0x1000000+(Math.round((t-R)*p)+R)*0x10000+(Math.round((t-G)*p)+G)*0x100+(Math.round((t-B)*p)+B)).toString(16).slice(1)

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

setTitleAndDescription = (title, description) ->
    mapTitle
        .transition().duration(50)
        .style('opacity', 0)
        .transition().duration(250)
        .style('opacity', 1)
        .text(title)
    mapDescription
        .transition().duration(50)
        .style('opacity', 0)
        .transition().duration(250)
        .style('opacity', 1)
        .text(description)

setTreeMenuText = (text, detailText) ->
    overflow = ''
    if text.length > overflow_limit
        list = splitText(text)
        text = list[0]
        overflow = list[1]
    treeMenuText
        .transition().duration(50)
        .style('opacity', 0)
        .transition().duration(250)
        .style('opacity', 1)
        .text(text)
    treeMenuOverflowText
        .transition().duration(50)
        .style('opacity', 0)
        .transition().duration(250)
        .style('opacity', 1)
        .text(overflow)

    # if not detailText
        # TODO: iterate over array of text lines until they're all cleared.
    if detailText
        split = splitText(detailText)
    # TODO: array of text lines that handle overflow properly, iteratively calling splitText
    # until the last line is under the detail text overflow limit

hideLabels = () ->
    console.log "hide"
    if not marineLabel or not desertLabel or not mountainLabel
        console.log "null"
        return
    mountainLabel
        .transition().duration(50)
        .style('opacity', 0)
    desertLabel
        .transition().duration(50)
        .style('opacity', 0)
    marineLabel
        .transition().duration(50)
        .style('opacity', 0)

showLabels = () ->
    console.log "show"
    #add level 1 ecosystem labels
    mountainLabel
        .transition().duration(50)
        .style('opacity', 1)
    desertLabel
        .transition().duration(50)
        .style('opacity', 1)
    marineLabel
        .transition().duration(50)
        .style('opacity', 1)

showQuote = () ->
    removeImages()
    setTreeMenuText("")
    line
        .transition().duration(50)
        .style('opacity', 1) for line in quote



showDisclaimer = () ->
    removeImages()
    setTreeMenuText("Disclaimer")
    line
        .transition().duration(50)
        .style('opacity', 1) for line in disclaimer

hideTreeMenuText = () ->
    line
        .transition().duration(50)
        .style('opacity', 0) for line in disclaimer
    line
        .transition().duration(50)
        .style('opacity', 0) for line in quote

resize = () ->
    # define initial width and height-to-width ratio
    margin = { top: 10, left: 10, bottom: 10, right: 10 }
    width = parseInt(d3.select('#map').style('width'))
    width = width - margin.left - margin.right
    bodyHeight = $(window).height()

    mapRatio = .55
    portrait = false
    height = width * mapRatio
    if bodyHeight > width
        mapRatio = width / bodyHeight
        portrait = true
        height = $(window).height()
    console.log "width, height:", width, height

    # update projection
    makeProjection()

    # resize the map container
    svg
      .style('width', width + 'px')
      .style('height', height + 'px');

    # resize the map
    svg.selectAll('.subunit').attr('d', path);
    # svg.selectAll('.state').attr('d', path);
    positionText()
    drawTreeMenu(currentTreeId)

d3.json("washington.topojson", initMap)
d3.select(window).on('resize', resize)
# setTreeMenuText('', 'Click on an ecological subregion to see its name.')
