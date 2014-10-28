    
class BracketViewer
    constructor: () ->
        @canvas = document.getElementById "tourneyViewer"
        @tourneyData = null
        
        try
            @context = @canvas.getContext "2d"
        catch
            throw Message: "Failure to get canvas context."
        
        mainDiv = document.getElementById "mainContent"
        
        $(mainDiv).bind 'dragover', (event) ->
            event.stopPropagation()
            event.preventDefault()
            
        $(mainDiv).bind 'drop', @drop
            
            
    drop: (event) =>
        console.log "wakka"
        
        event.stopPropagation()
        event.preventDefault()
        
        files = event.originalEvent.dataTransfer.files
        
        if files.length != 1
            throw Message: "Multiple files dropped"
            
        file = files[0]
        filename = escape file.name
        
        if not /\.json$/.test(filename)
            throw Message: "Needs to be a JSON file"
        
        reader = new FileReader()
        
        reader.onload = (event) =>
            @tourneyData = JSON.parse event.target.result
            console.info "file loaded"
        
        reader.readAsText file
    
    resize: () ->
        @canvas.width = window.innerWidth
        @canvas.height = window.innerHeight
        @redraw()
    
    redraw: () ->
        
        
b = new BracketViewer