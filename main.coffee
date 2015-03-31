#!vanilla

class Image
    
    imageContainerClass: "drop-image-container"
    hoverClass: "drop-image-hover"
    
    constructor: (@spec) ->
        
        {@container, @loaded, @mousemove, @click, @mouseenter, @mouseleave} = @spec
        
        @imageContainer = $ "<div>",
            class: @imageContainerClass
            text: "Drop an image here."
            #mouseenter: (e) => @mouseenter(e)
            #mouseleave: (e) => @mouseleave(e)
        
        @dropTarget = $("#guide")
        
        @dropTarget.mouseenter (e) => @mouseenter(e)
        @dropTarget.mouseleave (e) => @mouseleave(e)
        
        @dropTarget
            .on('dragenter', (e) => @highlight e)
            .on('dragexit', (e) => @highlight e, false)
            .on('dragover', (e) => e.preventDefault())
            .on('drop', (e) => @drop(e))
            
        @container.append @imageContainer
    
    drop: (e) ->
        @highlight e, false
        @setInitialPos e
        file = e.originalEvent.dataTransfer.files[0]
        reader = new FileReader()
        loadend = (result) => @set(result)
        $(reader).on('loadend', -> loadend this.result)
        reader.readAsDataURL(file)
        
    setInitialPos: (e) ->
        # Handles initial mouse coords/data.
        # Works only if container same size as canvas.
        o = e.originalEvent
        ot = o.originalTarget
        # Fixes difference between Chrome/Safari and Firefox:
        if ot
            # Firefox
            @containerPos = {x: o.clientX - ot.offsetLeft, y: o.clientY - ot.offsetTop}
        else
            # Chrome/Safari
            @containerPos = {x: o.offsetX, y: o.offsetY}
        
    set: (src) ->
        @imageContainer.empty()
        @image = $ "<img>", load: => @draw()
        @imageContainer.append @image
        @image.attr src: src
        
    draw: ->
        
        @w = @image.width()
        @h = @image.height()
        
        console.log "width", @w
        $(".temp").css
          width: @w + "px"
          marginLeft: -@w/2 + "px"
          
        $("#analyze").height @h+50
        #$("#plot-outer").height 300
        
        @imageContainer.width(@w).height(@h)
        
        @canvas = $("<canvas>")
        @imageContainer.append @canvas
        
        @image.hide()
        
        @context = @canvas[0].getContext('2d')
        @context.canvas.width = @w
        @context.canvas.height = @h
        
        @context.drawImage(@image[0], 0, 0, @w, @h)
        
        #@canvas.on "mousemove", (e) => @mousemove?(@mouseData(@mouseCoords(e)))
        $("#guide").on "mousemove", (e) => @mousemove?(@mouseData(@mouseCoords(e)))
        
        #@canvas.on "click", (e) => @click?(@mouseData(@mouseCoords(e)))
        $("#guide").on "click", (e) => @click?(@mouseData(@mouseCoords(e)))
        
        # Initial postion--to handle case in which mouse hasn't moved since dropping image.
        @imageContainer.css(cursor: "crosshair")  # Cursor before mouse moves after drop.
        @mousemove?(@mouseData(@containerPos)) if @containerPos?

        @loaded?(this)
        
    mouseData: (pos) ->
        return null unless pos?.x? and pos?.y?
        @containerPos = pos
        if pos? then imageData = @imageData pos, {dx:1, dy:1}
        d = imageData.data
        color = {r: d[0], g: d[1], b: d[2], alpha: d[3]}
        {pos: pos, color: color, imageData: imageData}
        
    mouseCoords: (e) ->
        rect = @canvas[0].getBoundingClientRect()
        round = Math.round
        x: round(e.clientX - rect.left)
        y: round(e.clientY - rect.top)

    imageData: (pos, rng) ->
        pos ?= {x:0, y:0}
        rng ?= {dx:@w, dy:@h}
        @context?.getImageData(pos.x, pos.y, rng.dx, rng.dy)
        
    getPixels: ->
        @imageData().data

    putPixels: (newData) ->
        imageData = @context?.getImageData(0, 0, @w, @h)
        imageData.data[k] = newData[k] for k in [0...newData.length]
        @context?.putImageData(imageData, 0, 0);

    highlight: (e, highlight=true) ->
        e.preventDefault()
        method = if highlight then "addClass" else "removeClass"
        @imageContainer[method](@hoverClass)
    
class Demo
    
    constructor: ->
        @container = $("#image")
        @current = $("#image-data-current")
        @clicked = $("#image-data-click")
        loaded = (image) => @loaded image
        mousemove = (data) => @showData @current, "Current coord: ", data
        click = (@data) => #@showData @clicked, "Clicked coord: ", @data
        mouseenter = => #@current.show()
        mouseleave = => @showData @current #@current.hide()
        image = new Image {@container, loaded, mousemove, click, mouseenter, mouseleave}
        image.set("SMPTE_Color_Bars.png")
        #@current.html "&nbsp;"
        @showData @current
        @current.show()

    loaded: (image) ->
        console.log "LOADED"
        $blab.image = image
        guide = new $blab.Guide image.w, image.h
        $blab.plot = new $blab.Plot image.w, image.h

        #guide.dragMarker(guide.m1, 0, 0)
        
    showData: (el, txt, data) ->
        unless data
          el.html "&nbsp;"
          return
        pos = data.pos
        color = @getColor data
        el.html "#{txt}(#{pos.x}, #{pos.y}) #{color}"
        
    getColor: (data) ->
        c = data.color
        s = c.r + c.g + c.b
        textCol = if s<500 then "white" else "black"
        hex = "#" + ("000000" + @rgbToHex(c.r, c.g, c.b)).slice(-6)
        "<span class='image-color' style='color: #{textCol}; background: #{hex}'>#{hex}</span>"
        
    rgbToHex: (r, g, b) -> ((r << 16) | (g << 8) | b).toString(16)
    
new Demo

