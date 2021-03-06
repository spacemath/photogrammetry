#!vanilla

class d3Object
    
    constructor: (id) ->
        @element = d3.select "##{id}"
        @element.selectAll("svg").remove()
        @obj = @element.append "svg"
        @initAxes()
        
    append: (obj) -> @obj.append obj
    
    initAxes: ->
    

class $blab.Plot extends d3Object
    
    colors: ["red", "blue", "green"]
    xTicks: 11
    yTicks: 6
    
    constructor: (@spec) ->
        
        {@id, @w, @h, @xMax, @grayScale, @rotation, @xLabel, @yLabel} = @spec
        
        super @id
        
        @obj.attr('width', @w).attr('height', @h)
        
        @plot = @obj.append('g')
            .attr("transform", "translate(0, 0)")
            .attr('width', @w)
            .attr('height', @h)
            
        @plot.attr("transform", "translate(#{@h}, 0) rotate(#{@rotation})") if @rotation  # ZZZ bug here
                
        @grid()
        @axesLabels()
            
        @line = d3.svg.line()
            .x((d) => @x2X d.interval)
            .y((d) =>  @y2Y d.intensity)
    
    initAxes: ->
        
        # x <-> pixels
        @x2X = d3.scale.linear()
            .domain([0, @xMax])
#            .domain([0, 1])
            .range([0, @w])
        @X2x = @x2X.invert
        
        # y <-> pixels
        @y2Y = d3.scale.linear()
            .domain([0, 255])
#            .domain([0, 1])
            .range([@h, 0])
        @Y2y = @y2Y.invert
        
        @xAxis = d3.svg.axis()
            .scale(@x2X)
            .orient("bottom")
            .ticks(@xTicks)
            
        @yAxis = d3.svg.axis()
            .scale(@y2Y)
            .orient("left")
            .ticks(@yTicks)
    
    grid: ->
        
        @plot.append("g")
            .attr("id","x-axis")
            .attr("class", "x axis")
            .attr("transform", "translate(0, #{@h})")
            .call(@xAxis)
            
        @plot.append("g")
            .attr("id","y-axis")
            .attr("class", "y axis")
            .attr("transform", "translate(0, 0)")
            .call(@yAxis)
        
        @plot.selectAll("line.horizontalGrid")
            .data(@y2Y.ticks(@yTicks))
            .enter()
            .append("line")
            .attr("class", "horizontalGrid")
            .attr("x1", 0)
            .attr("x2", @w)
            .attr("y1", (d) => @y2Y d)
            .attr("y2", (d) => @y2Y d)
            
        @plot.selectAll("line.verticalGrid")
            .data(@x2X.ticks(@xTicks))
            .enter()
            .append("line")
            .attr("class", "verticalGrid")
            .attr("y1", 0)
            .attr("y2", @h)
            .attr("x1", (d) => @x2X d)
            .attr("x2", (d) => @x2X d)
            
    axesLabels: ->
        
        @plot.append("text")
            .attr("class", "x label")
            .attr("text-anchor", "middle")
            .attr("x", @w/2)
            .attr("y", @h)
            .attr("dy", 50)
            .text(@xLabel)
#            .text("Normalized distance along line")
            
        @plot.append("text")
            .attr("class", "y label")
            .attr("text-anchor", "middle")
            .attr("x", -@h/2)
            .attr("y", 0)
            .attr("dy", -60)
            .attr("transform", "rotate(-90)")
            .text("Intensity"+(if @grayScale then "" else " (RGB)"))
        
    update: (data) ->
        # TODO: handle using d3 enter/exit approach.
        console.log "Update plot"
        if @grayScale
            intensity = @intensity(data)
            unless @lines
                @lines = @plotLine(intensity, "green")  # scalar
            else
                @lines.attr("d", @line(intensity))
        else
            unless @lines
                @lines = (@plotLine(data[color], color) for color in @colors)
            else
                line.attr("d", @line(data[@colors[idx]])) for line, idx in @lines
        
    plotLine: (data, color) ->
        @plot.append("path")
            .attr("class", "line")
            .attr("d", @line(data))
            .attr("stroke-width", 2)
            .attr("stroke", color)
            
    intensity: (data) ->
        data[@colors[0]]  # For speed: use only red value, assuming RGB all equal.


class $blab.Guide extends d3Object

    r: 15 # Marker radius
    tId: null
    computing: false
        
    constructor: (@spec) ->
        
        {@id, @w, @h, @grayScale} = @spec
        
        super @id
        
        # Initial marker positions.
        @markerPos = [
            {x: 0.0, y: 0.5*@h}
            {x: 0.95*@w, y: 0.5*@h}
        ]
        
        # housekeeping
        @obj.on("click", null)  # Clear any previous event handlers.
        d3.behavior.drag().on("drag", null)  # Clear any previous event handlers.
        
        @obj.attr('width', @w).attr('height', @h)
        
        @region = @obj.append('g')
            .attr("transform", "translate( #{0}, #{0})")
            .attr('width', @w)
            .attr('height', @h)
            .attr('class', 'unselectable')
        
        # Uncomment to include axes labels
        #@axesTicks()
        #@axesLabels()
        @grid()
        
        @m1 = @marker(@markerPos[0])
        @m2 = @marker(@markerPos[1])
        
        @line = @region.append("line")
            .attr("class", "modelline")
        
        @compFromMarkers()
        
        s = 100
        @steps = (x/s for x in [0..s])
        
    initAxes: ->
        
        # x <-> pixels
        @x2X = d3.scale.linear()
            .domain([0, @w])
            .range([0, @w])
        @X2x = @x2X.invert
        
        # y <-> pixels
        @y2Y = d3.scale.linear()
            .domain([0, @h])
            .range([@h, 0])
        @Y2y = @y2Y.invert
        
    axesTicks: ->
        
        @xAxis = d3.svg.axis()
            .scale(@x2X)
            .orient("bottom")
            .ticks(6)
            
        @yAxis = d3.svg.axis()
            .scale(@y2Y)
            .orient("left")
            
        @region.append("g")
            .attr("id","x-axis")
            .attr("class", "x axis")
            .attr("transform", "translate(0, #{@h})")
            .call(@xAxis)
        
        @region.append("g")
            .attr("id","y-axis")
            .attr("class", "y axis")
            .attr("transform", "translate(0, 0)")
            .call(@yAxis)
            
    axesLabels: ->
        
        @region.append("text")
            .attr("class", "x label")
            .attr("text-anchor", "end")
            .attr("dy", @h+50)
            .attr("dx", 220)
            .text("xlabel")
            
        @region.append("text")
            .attr("class", "y label")
            .attr("text-anchor", "end")
            .attr("dy", -60)
            .attr("dx", -90)
            .attr("transform", "rotate(-90)")
            .text("ylabel")
            
    grid: ->
        
        hg = @region.selectAll("line.horizontalGrid")
            .data(@y2Y.ticks(10))
            .enter()
            .append("line")
            .attr("class", "horizontalGrid")
            .attr("x1", 0)
            .attr("x2", @w)
            .attr("y1", (d) => @y2Y d)
            .attr("y2", (d) => @y2Y d)
        
        vg = @region.selectAll("line.verticalGrid")
#            .data(@x2X.ticks(30))
            .data(@x2X.ticks(@w/50))
            .enter()
            .append("line")
            .attr("class", "verticalGrid")
            .attr("y1", 0)
            .attr("y2", @h)
            .attr("x1", (d) => @x2X d)
            .attr("x2", (d) => @x2X d)
        
    marker: (pos) ->
        m = @region.append('circle')
            .attr('r', @r)
            .attr("cx", @x2X pos.x)
            .attr("cy", @y2Y pos.y)
            .attr("class", "modelcircle")
            .call(
                d3.behavior
                .drag()
                .origin(=>
                    x:m.attr("cx")
                    y:m.attr("cy")
                )
                .on("drag", => @dragMarker(m, d3.event.x, d3.event.y))
            )
            
    dragMarker: (marker, x, y) ->
        
        x = 0 if x<0
        x = @w if x>@w
        y = 0 if y<0
        y = @h if y>@h
        
        marker.attr("cx", x)
        marker.attr("cy", y)
        
        @compFromMarkers()
        
    compFromMarkers: ->
        
        X1 = +@m1.attr("cx")
        Y1 = Math.floor(+@m1.attr("cy"))
        X2 = +@m2.attr("cx")
        Y2 = Math.floor(+@m2.attr("cy"))
        
        @line
            .attr("x1", X1)
            .attr("y1", Y1)
            .attr("x2", X2)
            .attr("y2", Y2)
        
        if @tId
            clearTimeout @tId
            @tId = null
            
        unless @computing
            @tId = setTimeout (=> @computeColor(X1, Y1, X2, Y2)), 40
    
    computeColor: (X1, Y1, X2, Y2) =>
        
        @computing = true
        
        abs = Math.abs
        floor = Math.floor
        dist = (x, y) -> floor(Math.sqrt(x*x + y*y))
        
        intensity = (data, clr, idx) -> data[idx].color[clr]
        
        color = (data, q1, q2, clr) =>
            q10 = q1[0]
            q20 = q2[0]
            ({interval: dist(q1i-q10, q2[idx]-q20), intensity: intensity(data, clr, idx)} for q1i, idx in q1)
        
        if abs(X2-X1) > abs(Y2-Y1)
            p = ["x", "y"]
            q1r = [X1, X2]
            q2r = [Y1, Y2]
        else
            p = ["y", "x"]
            q1r = [Y1, Y2]
            q2r = [X1, X2]
            
        d1 = q1r[1] - q1r[0]
        d2 = q2r[1] - q2r[0]
        q1 = [q1r[0]..q1r[1]]
        q2 = if abs(d1)>0 then (floor(q2r[0] + d2/d1*(q1i-q1r[0])) for q1i in q1) else [floor(q2r[1])]
        
        z = (q1i, q2i) ->
            s = {}
            s[p[0]] = q1i
            s[p[1]] = q2i
            s
                
        imageData = ($blab.image.mouseData(z(q1i, q2[idx])) for q1i, idx in q1)
        
        data =
            red: color(imageData, q1, q2, "r")
            blue: color(imageData, q1, q2, "b")
            green: color(imageData, q1, q2, "g")
                
        $blab.plot.update(data)
        
        @computing = false
    
    OLD_computeColor: (X1, Y1, X2, Y2) =>
        
        @computing = true
        
        dX = X2 - X1
        dY = Y2 - Y1
        
        Xq = (Math.round(X1 + dX*ri) for ri in @steps)
        Yq = (Math.round(Y1 + dY*ri) for ri in @steps)
        
        imageData = ($blab.image.mouseData(x: Xq[idx], y: Yq[idx]) for s, idx in @steps)
        
        intensity = (clr, idx) -> imageData[idx].color[clr]/255
        
        color = (clr) => ({interval: s, intensity: intensity(clr, idx)} for s, idx in @steps)
        
        data =
            red: color("r")
            blue: color("b")
            green: color("g")
        
        $blab.plot.update(data)
        
        @computing = false

