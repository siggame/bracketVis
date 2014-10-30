    
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
            @createBrackets()
        
        reader.readAsText file
    
    createBrackets: () ->
        bracket1 = {lastmatch:null, matches: {}}
        bracket2 = {lastmatch: null, matches: {}}

        tier = {}
        for id, match of @tourneyData
            if match.previous_matches.length == 0
                bracket1.matches[id] = match
                tier[id] = match
        
        newtier = {}
        while Object.keys(tier).length > 1
            for id, match of @tourneyData
                if match.previous_matches.length > 0
                    prevMatch1id = match.previous_matches[0].toString()
                    prevMatch2id = match.previous_matches[1].toString()
                    prevMatch1 = @tourneyData[prevMatch1id]
                    prevMatch2 = @tourneyData[prevMatch2id]
                    for tierid, tiermatch of tier
                        if prevMatch2id == tierid
                            console.log "first true"
                            
                        if match.player1 == tiermatch.winner
                            console.log "second true" 
                            
                        if match.player2 == tiermatch.winner
                            console.log "third true"
                    
                        if ((prevMatch1id == tierid and
                        (match.player_1 == tiermatch.winner or
                        match.player_2 == tiermatch.winner)) or  
                        (prevMatch2id == tierid and
                        (match.player_1 == tiermatch.winner or
                        match.player_2 == tiermatch.winner)))
                            bracket1.matches[id] = match
                            newtier[id] = match
            tier = newtier
            newtier = {}
       
        for id, match of tier
            bracket1.lastmatch = id
        
        tier = {}
        for id, match of @tourneyData
            if match.previous_matches.length != 0
                for brackid, brackmatch of bracket1.matches
                    if((match.previous_matches[0] == parseInt(brackid) and 
                    !bracket1.matches[id]?) or
                    (match.previous_matches[1] == parseInt(brackid) and
                    !bracket1.matches[id]?))
                        bracket2.matches[id] = match
                        tier[id] = match

        while Object.keys(tier).length > 1
            for id, match of @tourneyData
                if match.previous_matches.length > 0
                    prevMatch1id = match.previous_matches[0].toString()
                    prevMatch2id = match.previous_matches[1].toString()
                    prevMatch1 = @tourneyData[prevMatch1id]
                    prevMatch2 = @tourneyData[prevMatch2id]
                    for tierid, tiermatch of tier
                        if prevMatch1id == tierid
                            console.log "zero true"
                    
                        if prevMatch2id == tierid
                            console.log "first true"
                        
                        if match.player1 == tiermatch.winner
                            console.log "second true" 
                            
                        if match.player2 == tiermatch.winner
                            console.log "third true"
                    
                        if((prevMatch1id == tierid and
                        (match.player_1 == tiermatch.winner or
                        match.player_2 == tiermatch.winner)) or
                        (prevMatch2id == tierid and
                        (match.player_1 == tiermatch.winner or
                        match.player_2 == tiermatch.winner)))
                            bracket2.matches[id] = match
                            newtier[id] = match
            tier = newtier
            newtier = {}
    
        for id, match of tier
            bracket2.lastmatch = id
    
    resize: () ->
        @canvas.width = window.innerWidth
        @canvas.height = window.innerHeight
        @redraw()
    
    redraw: () ->
        
        
b = new BracketViewer