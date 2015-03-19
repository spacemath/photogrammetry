#!vanilla

class Image
    
    imageContainerClass: "drop-image-container"
    hoverClass: "drop-image-hover"
    
    constructor: (@spec) ->
        
        {@container, @loaded, @mousemove, @click} = @spec
        
        @imageContainer = $ "<div>",
            class: @imageContainerClass
            text: "Drop an image here."
        
        @imageContainer
            .on('dragenter', (e) => @highlight e)
            .on('dragexit', (e) => @highlight e, false)
            .on('dragover', (e) => e.preventDefault())
            .on('drop', (e) => @drop(e))
            
        @container.append @imageContainer
        
    drop: (e) ->
        
        @highlight e, false 
        
        file = e.originalEvent.dataTransfer.files[0]
        reader = new FileReader()
        loadend = (result) => @set(result)
        $(reader).on('loadend', -> loadend this.result)
        reader.readAsDataURL(file)
        
    set: (src) ->
        @image = $ "<img>", src: src
        @imageContainer.html @image
        
        w = @image.width()
        h = @image.height()
        
        @imageContainer.width(w).height(h)
        
        @canvas = $("<canvas>")
        @imageContainer.append @canvas
        
        @context = @canvas[0].getContext('2d')
        @context.canvas.width = w
        @context.canvas.height = h
        @context.drawImage(@image[0], 0, 0, w, h)
        
        @canvas.on "mousemove", (e) => @mousemove?(@mouseData(e))
            
        @canvas.on "click", (e) => @click?(@mouseData(e))
        
        @loaded?(this)
    
    mouseData: (e) ->
        pos = @mouseCoords(e)
        imageData = @imageData pos
        d = imageData.data
        color = {r: d[0], g: d[1], b: d[2], alpha: d[3]}
        {pos: pos, color: color, imageData: imageData}
        
    mouseCoords: (e) ->
        rect = @canvas[0].getBoundingClientRect()
        x: Math.round(e.clientX - rect.left)
        y: Math.round(e.clientY - rect.top)
        
    imageData: (pos) ->
        @context.getImageData(pos.x, pos.y, 1, 1)
        
    highlight: (e, highlight=true) ->
        e.preventDefault()
        method = if highlight then "addClass" else "removeClass"
        @imageContainer[method](@hoverClass)
    
class Demo
    
    constructor: ->
        @container = $("#image")
        loaded = (image) => @loaded image
        mousemove = (data) => @showData $("#image-data-current"), "Current coord: ", data
        click = (@data) => @showData $("#image-data-click"), "Clicked coord: ", @data
        new Image {@container, loaded, mousemove, click}

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
