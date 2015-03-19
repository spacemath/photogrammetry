#!vanilla

class Image
    
    imageContainerClass: "drop-image-container"
    hoverClass: "drop-image-hover"
    
    constructor: (@spec) ->
        
        {@container, @loaded, @mousemove, @click, @mouseenter, @mouseleave} = @spec
        
        @imageContainer = $ "<div>",
            class: @imageContainerClass
            text: "Drop an image here."
            mouseenter: (e) => @mouseenter(e)
            mouseleave: (e) => @mouseleave(e)
        
        @imageContainer
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
        
        @imageContainer.width(@w).height(@h)
        
        @canvas = $("<canvas>")
        @imageContainer.append @canvas
        
        @image.hide()
        
        @context = @canvas[0].getContext('2d')
        @context.canvas.width = @w
        @context.canvas.height = @h
        
        @context.drawImage(@image[0], 0, 0, @w, @h)
        
        @canvas.on "mousemove", (e) => @mousemove?(@mouseData(@mouseCoords(e)))
        
        @canvas.on "click", (e) => @click?(@mouseData(@mouseCoords(e)))
        
        # Initial postion--to handle case in which mouse hasn't moved since dropping image.
        @imageContainer.css(cursor: "crosshair")  # Cursor before mouse moves after drop.
        @mousemove?(@mouseData(@containerPos))
        
        @loaded?(this)
        
    mouseData: (pos) ->
        return null unless pos?.x? and pos?.y?
        @containerPos = pos
        imageData = @imageData pos
        d = imageData.data
        color = {r: d[0], g: d[1], b: d[2], alpha: d[3]}
        {pos: pos, color: color, imageData: imageData}
        
    mouseCoords: (e) ->
        rect = @canvas[0].getBoundingClientRect()
        round = Math.round
        x: round(e.clientX - rect.left)
        y: round(e.clientY - rect.top)
        
    imageData: (pos) ->
        return null unless pos.x? and pos.y?
        @context?.getImageData(pos.x, pos.y, 1, 1)
        
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
        click = (@data) => @showData @clicked, "Clicked coord: ", @data
        mouseenter = => @current.show()
        mouseleave = => @current.hide()
        new Image {@container, loaded, mousemove, click, mouseenter, mouseleave}

    loaded: (image) ->
        console.log "Image loaded", image
        
    showData: (el, txt, data) ->
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
