#!vanilla

class Image
    
    imageContainerClass: "drop-image-container"
    hoverClass: "drop-image-hover"
    
    constructor: (@spec) ->
        
        {@container, @dropTarget, @grayScale, @loaded, @mousemove, @click, @mouseenter, @mouseleave} = @spec
        
        @imageContainer = $ "<div>",
            class: @imageContainerClass
            text: "Drop an image here."
        
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
        @image = $ "<img>",
            class: "desaturate"
            load: => @draw()
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
        @grayScaleFilter() if @grayScale
        
        @dropTarget.on "mousemove", (e) => @mousemove?(@mouseData(@mouseCoords(e)))
        @dropTarget.on "click", (e) => @click?(@mouseData(@mouseCoords(e)))
        
        # Initial postion--to handle case in which mouse hasn't moved since dropping image.
        @imageContainer.css(cursor: "crosshair")  # Cursor before mouse moves after drop.
        @mousemove?(@mouseData(@containerPos)) if @containerPos?
        
        @loaded?(this)
        
    grayScaleFilter: ->
        
        # Color contributions (alt: 0.3, 0.59, 0.11)
        t = [0.34, 0.5, 0.16]
        
        imageData = @context.getImageData(0, 0, @w, @h)
        d = imageData.data
                
        gray = (n) ->
            b = 0
            b += t[i]*d[n+i] for i in [0..2]
            d[i] = b for i in [n..n+2]
            
        filter = (f) -> f(k) for dk, k in d by 4
        
        filter gray
        
        @context.putImageData(imageData, 0, 0)
        
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
        @context?.putImageData(imageData, 0, 0)
        @loaded?(this)
        
    highlight: (e, highlight=true) ->
        e.preventDefault()
        method = if highlight then "addClass" else "removeClass"
        @imageContainer[method](@hoverClass)
    
class Simulation
    
    # TODO: path const
    images:
        test: {img: "../resources/images/SMPTE_Color_Bars.png", button: "#test-image-button"}
        jellyfish: {img: "../resources/images/jellyfish.png", button: "#jellyfish-image-button"}
        craters: {img: "../resources/images/mars-crater.jpg", button: "#craters-image-button"}
    
    plotHeight: 200
    
    grayScale: true
    
    constructor: ->
        @container = $("#image")
        @dropTarget = $("#guide")
        @current = $("#image-data-current")
        @clicked = $("#image-data-click")
        loaded = (image) => @loaded image
        mousemove = (data) => @showData @current, "Current coord: ", data
        click = (@data) => # no method
        mouseenter = => # no method
        mouseleave = => @showData @current
        @image = new Image {@container, @dropTarget, @grayScale, loaded, mousemove, click, mouseenter, mouseleave}
        @image.set(@images.craters.img)
        @showData @current
        @current.show()
        
        # Image buttons
        set = (img) => => @setImage(img)
        $(i.button).click(set(i.img)) for label, i of @images
        
    setImage: (img) ->
        #$("#image-loading").html "Loading..."
        @image.set(img)
        false  # For anchor
        
    loaded: (image) ->
        
        $blab.image = image
        
        @w = image.w
        @h = image.h
        
        console.log "LOADED IMAGE", @w, @h
        $("#image-loading").empty()
        
        # Set outer/container sizes based on image size
        @setDims "#image-outer", "#image-container", @w, @h+30
        @setDims "#plot-outer", "#plot", @w, @plotHeight+100
        
        @draw()
        
    draw: ->
        
        guide = new $blab.Guide
            id: "guide"
            w: @w
            h: @h
            grayScale: @grayScale
        
        xMax = Math.round(Math.sqrt(@w*@w + @h*@h))
        $blab.plot = new $blab.Plot
            id: "plot"
            w: xMax #@w
            h: @plotHeight
            xMax: xMax
            grayScale: @grayScale
            xLabel: "Distance along path (pixels)"
            
        ###
        $blab.yplot = new $blab.Plot
            id: "yplot"
            w: @h  # ZZZ const
            h: @plotHeight
            grayScale: @grayScale
            rotation: 90
            xLabel: "Vertical pixel"
        ###
        
    setDims: (outerSel, containerSel, w, h) ->
        $(outerSel).height(h)
        c = $ containerSel
        c.width(w).height(h)
        c.css(marginLeft: -w/2)
        
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
        if @grayScale
            intensity = Math.round(s/3)
            txt = "Intensity = #{intensity}"
        else 
            rgb = "(#{c.r}, #{c.g}, #{c.b})"
    #        n = (Math.round(x/255*100)/100 for x in [c.r, c.g, c.b])
            #rgb = "(#{n[0]}, #{n[1]}, #{n[2]})"
            txt = "RGB = #{rgb}"
        "<span class='image-color' style='color: #{textCol}; background: #{hex}'>#{txt}</span>"
        
    rgbToHex: (r, g, b) -> ((r << 16) | (g << 8) | b).toString(16)
    
new Simulation

