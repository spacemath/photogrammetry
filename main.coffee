class Image
    
    imageContainerClass: "drop-image-container"
    hoverClass: "drop-image-hover"
    
    constructor: (@container, @loaded) ->
        
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
        @imageContainer.width(@image.width()).height(@image.height())
        @loaded?()
            
    highlight: (e, highlight=true) ->
        e.preventDefault()
        method = if highlight then "addClass" else "removeClass"
        @imageContainer[method](@hoverClass)
    

container = $("#image")
callback = ->
    console.log "Image loaded"
new Image container, callback
