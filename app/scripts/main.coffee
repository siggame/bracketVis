    
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
        bracket1 = {lastmatch: null, matches: {}}
        bracket2 = {lastmatch: null, matches: {}}
        bracket3 = {lastmatch: null, matches: {}}
        champBracket = {lastmatch: null, matches: {}}
      
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
        
        for id, match of @tourneyData
            if match.previous_matches.length > 0
                prevMatch1id = match.previous_matches[0].toString()
                prevMatch2id = match.previous_matches[1].toString()
                prevMatch1 = @tourneyData[prevMatch1id]
                prevMatch2 = @tourneyData[prevMatch2id]
                
                if prevMatch1.winner == prevMatch1.player_1
                    loser1 = prevMatch1.player_2
                else
                    loser1 = prevMatch1.player_1
                    
                if prevMatch2.winner == prevMatch2.player_1
                    loser2 = prevMatch2.player_2
                else
                    loser2 = prevMatch2.player_1           
                    
                matchHasTwoLosersFromBrack1 = 
                (bracket1.matches[prevMatch1id]? and
                (match.player_1 == loser1 or
                match.player_2 == loser1)) and
                (bracket1.matches[prevMatch2id]? and
                (match.player_1 == loser2 or
                match.player_2 == loser2))
                    
                if (matchHasTwoLosersFromBrack1)
                    bracket2.matches[id] = match
        
        insertionMade = (true)
        while insertionMade
            insertionMade = false
            for id, match of @tourneyData
                if match.previous_matches.length > 0 and !bracket2.matches[id]?
                    prevMatch1id = match.previous_matches[0].toString()
                    prevMatch2id = match.previous_matches[1].toString()
                    prevMatch1 = @tourneyData[prevMatch1id]
                    prevMatch2 = @tourneyData[prevMatch2id]
                    
                    if prevMatch1.winner == prevMatch1.player_1
                        loser1 = prevMatch1.player_2
                    else
                        loser1 = prevMatch1.player_1
                        
                    if prevMatch2.winner == prevMatch2.player_1
                        loser2 = prevMatch2.player_2
                    else
                        loser2 = prevMatch2.player_1           
                        
                    matchHasLoserFromBrack1 = 
                    (bracket1.matches[prevMatch1id]? and
                    (match.player_1 == loser1 or
                    match.player_2 == loser1)) or
                    (bracket1.matches[prevMatch2id]? and
                    (match.player_1 == loser2 or
                    match.player_2 == loser2))
                    
                    matchHasWinnerFromBrack2 = 
                    (bracket2.matches[prevMatch1id]? and
                    (match.player_1 == prevMatch1.winner or
                    match.player_2 == prevMatch1.winner)) or
                    (bracket2.matches[prevMatch2id]? and
                    (match.player_1 == prevMatch2.winner or
                    match.player_2 == prevMatch2.winner))
                    
                    matchHasTwoWinnersFromBrack2 = 
                    (bracket2.matches[prevMatch1id]? and
                    (match.player_1 == prevMatch1.winner or
                    match.player_2 == prevMatch1.winner)) and
                    (bracket2.matches[prevMatch2id]? and
                    (match.player_1 == prevMatch2.winner or
                    match.player_2 == prevMatch2.winner))
                    
                    if matchHasLoserFromBrack1 and matchHasWinnerFromBrack2 or
                    matchHasTwoWinnersFromBrack2
                        insertionMade = (true)
                        bracket2.matches[id] = match

        for id, match of @tourneyData
            if match.previous_matches.length > 0
                prevMatch1id = match.previous_matches[0].toString()
                prevMatch2id = match.previous_matches[1].toString()
                prevMatch1 = @tourneyData[prevMatch1id]
                prevMatch2 = @tourneyData[prevMatch2id]
                
                if prevMatch1.winner == prevMatch1.player_1
                    loser1 = prevMatch1.player_2
                else
                    loser1 = prevMatch1.player_1
                    
                if prevMatch2.winner == prevMatch2.player_1
                    loser2 = prevMatch2.player_2
                else
                    loser2 = prevMatch2.player_1           
                    
                matchHasTwoLosersFromBrack2 = 
                (bracket2.matches[prevMatch1id]? and
                (match.player_1 == loser1 or
                match.player_2 == loser1)) and
                (bracket2.matches[prevMatch2id]? and
                (match.player_1 == loser2 or
                match.player_2 == loser2))
                    
                if (matchHasTwoLosersFromBrack2)
                    bracket3.matches[id] = match
        
        insertionMade = (true)
        while insertionMade
            insertionMade = (false)
            for id, match of @tourneyData
                if match.previous_matches.length > 0 and !bracket3.matches[id]?
                    prevMatch1id = match.previous_matches[0].toString()
                    prevMatch2id = match.previous_matches[1].toString()
                    prevMatch1 = @tourneyData[prevMatch1id]
                    prevMatch2 = @tourneyData[prevMatch2id]
                    
                    if prevMatch1.winner == prevMatch1.player_1
                        loser1 = prevMatch1.player_2
                    else
                        loser1 = prevMatch1.player_1
                        
                    if prevMatch2.winner == prevMatch2.player_1
                        loser2 = prevMatch2.player_2
                    else
                        loser2 = prevMatch2.player_1           
                        
                    matchHasLoserFromBrack2 = 
                    (bracket2.matches[prevMatch1id]? and
                    (match.player_1 == loser1 or
                    match.player_2 == loser1)) or
                    (bracket2.matches[prevMatch2id]? and
                    (match.player_1 == loser2 or
                    match.player_2 == loser2))
                    
                    matchHasWinnerFromBrack3 = 
                    (bracket3.matches[prevMatch1id]? and
                    (match.player_1 == prevMatch1.winner or
                    match.player_2 == prevMatch1.winner)) or
                    (bracket3.matches[prevMatch2id]? and
                    (match.player_1 == prevMatch2.winner or
                    match.player_2 == prevMatch2.winner))
                    
                    matchHasTwoWinnersFromBrack3 = 
                    (bracket3.matches[prevMatch1id]? and
                    (match.player_1 == prevMatch1.winner or
                    match.player_2 == prevMatch1.winner)) and
                    (bracket3.matches[prevMatch2id]? and
                    (match.player_1 == prevMatch2.winner or
                    match.player_2 == prevMatch2.winner))
                    
                    if matchHasLoserFromBrack2 and matchHasWinnerFromBrack3 or
                    matchHasTwoWinnersFromBrack3
                        insertionMade = true
                        bracket3.matches[id] = match
        
        for id, match of @tourneyData
            if !bracket1.matches[id]? and 
            !bracket2.matches[id]? and 
            !bracket3.matches[id]?
                champBracket[id] = match
        
        console.log "here"
                    
                
                
    resize: () ->
        @canvas.width = window.innerWidth
        @canvas.height = window.innerHeight
        @redraw()
    
    redraw: () ->
        
        
b = new BracketViewer