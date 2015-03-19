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
        
        @canvas.on "mousemove", (e) => @mousemove?(@mouseCoords(e))
        @canvas.on "click", (e) => @click?(@mouseCoords(e))
        
        @loaded?(this)
        
    mouseCoords: (e) ->
        rect = @canvas[0].getBoundingClientRect()
        x: e.clientX - rect.left
        y: e.clientY - rect.top
        
    highlight: (e, highlight=true) ->
        e.preventDefault()
        method = if highlight then "addClass" else "removeClass"
        @imageContainer[method](@hoverClass)
    
class Demo
    
    constructor: ->
        @container = $("#image")
        loaded = (image) => @loaded image
        mousemove = (pos) => @showCoords pos
        click = (@pos) => @showCoords @pos
        new Image {@container, loaded, mousemove, click}

    loaded: (image) ->
        console.log "Image loaded", image
        
    showCoords: (pos) ->
        clicked = if @pos then " (clicked x: #{@pos.x}, y: #{@pos.x})" else ""
        $("#coords").html "x: #{pos.x}, y: #{pos.y}" + clicked
        
new Demo
