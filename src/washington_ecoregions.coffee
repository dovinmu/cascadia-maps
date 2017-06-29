width = 1350
height = 1160
selected = null
selectedTree = null
# lookup list of trees given a region
region_trees = {}
# lookup list of regions given a tree
tree_regions = {}
# the original tree object, lookup by tree name
trees = {}

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

# map labels
marineLabel = null
mountainLabel = null
desertLabel = null

disclaimer = []
quote = []

# set map name and description
mapTitle = svg.append('text')
    .attr('x', (width/6))
    .attr('y', (50))
    .attr('class', 'mapname')
    .text('Washington state evergreens')
mapDescription = svg.append('text')
    .attr('x', (width/6 + 10))
    .attr('y', (75))
    .attr('class', 'selected detail')
    .text('Click on an ecoregion to see the list of evergreen trees native to it.')

#ecoregion name display
treeMenuText = svg.append('text')
.attr('x', (width - width/4.5))
.attr('y', (70))
.attr('class', 'selected title')
.text('')

treeMenuOverflowText = svg.append('text')
.attr('x', (width - width/4.5))
.attr('y', (90))
.attr('class', 'selected title')
.text('')

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

    mountainLabel = svg.append("text")
    .attr("x", (width/3))
    .attr("y", (height/8))
    .attr("class", "label")
    .text("Northwestern Forested Mountains")
    desertLabel = svg.append("text")
    .attr("x", (width/2.3))
    .attr("y", (height/2.2))
    .attr("class", "label")
    .text("North American Deserts")
    marineLabel = svg.append("text")
    .attr("x", (width/20))
    .attr("y", (height/3.5))
    .attr("class", "label")
    .text("Marine West Coast Forest")

    disclaimer.push(svg.append("text")
        .attr("x", (width - width/4.5))
        .attr("y", (110) + i*20)
        .attr("class", "detail")
        .style('opacity', 0)
        .text(line)) for line,i in ["Tree ranges are based on the data ",
                                    "available and not guaranteed to be",
                                    "accurate."
                                   ]
    quote.push(svg.append("text")
        .attr("x", (width - width/4.5))
        .attr("y", (110) + i*20)
        .attr("class", "quote")
        .style('opacity', 0)
        .text(line)) for line,i in ["A tree is beautiful, but what’s more, it has a right ",
                                    "to life; like water, the sun and the stars, it is ",
                                    "essential. Life on earth is inconceivable without trees.",
                                    " - Chekov"
                                   ]

    region_trees[path.id] = [] for path in data.features
    loadJson('trees.wa.json')
    showQuote()

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
        .then(() -> console.log region_trees)
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

onClickEco = (d, i) ->
    hideTreeMenuText()
    if selected
        selected.style('stroke', 'none')
    if selectedTree
        region_list = tree_regions[selectedTree.id]
        d3.selectAll('.subunit').style('opacity', '1') for region in region_list
        selectedTree = null
        setTitleAndDescription('Washington state trees', 'Click on an ecoregion to see the list of trees native to it.')
        showLabels()
    removeImages()
    selected = d3.select(this)
    selected.style('stroke', 'red')
    tree_list = region_trees[d.id]
    # setTreeMenuText(d.id.split(' ')[2..].join(' '), tree_list.join(', '))
    setTreeMenuText(d.id.split(' ')[2..].join(' '))
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
    console.log "HI"



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

d3.json("washington.topojson", initMap)
# setTreeMenuText('', 'Click on an ecological subregion to see its name.')
