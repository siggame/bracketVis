
class Rectangle
    constructor: (@x, @y, @w, @h) ->
        if !@x?
            @x = (null)
        if !@x?
            @x = (null)
        if !@x?
            @x = (null)
        if !@x?
            @x = (null)
    
class Player
    constructor: (@name, @health) ->
        if !@name?
            @name = (null)
        if !@health?
            @health = (null)
    
class PlayerSlot
    constructor: () ->
        @rect = new Rectangle
        @player = (null)
        
class Bracket
    constructor: () ->
        @lastmatch = (null)
        @matches = {}
        
###
 # Every Bracket has a list of matches
 # Every match has two PlayerSlots
 # A PlayerSlot can contain a Player or be null
 # A PlayerSlot contains a rectangle which denotes it's size
 # a Player has a name, and some amount of health
 # (in a triple elim, the health for all starts at 3)
###
    
class BracketViewer
    constructor: () ->
        @canvas = document.getElementById "tourneyViewer"
        @tourneyData = (null)
        @bracket1 = new Bracket
        @bracket2 = new Bracket
        @bracket3 = new Bracket
        @champBracket = new Bracket
        
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
            console.info "File loaded"
            @createBrackets()
        
        reader.readAsText file
    
    createBrackets: () ->
        ###
         # Add list of subsequent games to each match. Also add an 
         # attribute player_slots and add the number of PlayerSlot objects 
         # for each preivous game.
        ###
        for id, match of @tourneyData
            match.player_slots = []
            if match.previous_matches.length > 0
                if match.previous_matches[0] != match.previous_matches[1]
                    match.player_slots.push new PlayerSlot
                    match.player_slots.push new PlayerSlot

            if !match.subsequent_matches?
                match.subsequent_matches = []
                
            if match.previous_matches.length > 0
                prevMatch1id = match.previous_matches[0].toString()
                prevMatch2id = match.previous_matches[1].toString()
                prevMatch1 = @tourneyData[prevMatch1id]
                prevMatch2 = @tourneyData[prevMatch2id]
                
                if !prevMatch1.subsequent_matches?
                    prevMatch1.subsequent_matches = []
                
                if !prevMatch2.subsequent_matches?
                    prevMatch2.subsequent_matches = []
                    
                prevMatch1.subsequent_matches.push id
                prevMatch2.subsequent_matches.push id
      
        ###
         # Start filling the first bracket. This will place references to 
         # all the games that are leaves of the overall tree in an array.
         # These matches are the bottom of the first bracket.
        ###
        tier = {}
        for id, match of @tourneyData
            if match.previous_matches.length == 0
                @bracket1.matches[id] = match
                tier[id] = match
        
        ###
         # Find matches that use the winner of one of those games in the
         # bottom rung and add it to the next rung. Then swap the next
         # rung for the old rung. Do this until there is only one game
         # in the rung, which will be the final game in the first bracket.
        ###
        newtier = {}
        while Object.keys(tier).length > 1
            for id, match of @tourneyData
                if match.previous_matches.length > 0
                    prevMatch1id = match.previous_matches[0].toString()
                    prevMatch2id = match.previous_matches[1].toString()
                    prevMatch1 = @tourneyData[prevMatch1id]
                    prevMatch2 = @tourneyData[prevMatch2id]
                    for tierid, tiermatch of tier
                        if ((prevMatch1id == tierid and
                        (match.player_1 == tiermatch.winner or
                        match.player_2 == tiermatch.winner)) or  
                        (prevMatch2id == tierid and
                        (match.player_1 == tiermatch.winner or
                        match.player_2 == tiermatch.winner)))
                            @bracket1.matches[id] = match
                            newtier[id] = match
            tier = newtier
            newtier = {}
       
        ###
         # Since we have the final match already left in the current
         # tier array just initialize it as the last match of the bracket.
        ###
        for id, match of tier
            @bracket1.lastmatch = id
        
        ###
         # Now start building the second bracket. To do this, we first find
         # all the game in the entire list that contain two losers from the
         # first bracket. These will be the bottom rung matches in bracket 2.
        ###
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
                (@bracket1.matches[prevMatch1id]? and
                (match.player_1 == loser1 or
                match.player_2 == loser1)) and
                (@bracket1.matches[prevMatch2id]? and
                (match.player_1 == loser2 or
                match.player_2 == loser2))
                    
                if (matchHasTwoLosersFromBrack1)
                    @bracket2.matches[id] = match
        
        ###
         # Then we fill out the rest of bracket two. Here you will insert all
         # game that either have one winner from bracket2 and one loser from
         # bracket1 or two winners from bracket2. This needs to be run until
         # nothing is inserted because a check to see if a bracket2 game exists
         # may not have been inserted into bracket2 yet. Once no insertion has
         # been made, bracket2 will be complete.
        ###
        insertionMade = (true)
        while insertionMade
            insertionMade = (false)
            for id, match of @tourneyData
                if match.previous_matches.length > 0 and !@bracket2.matches[id]?
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
                    (@bracket1.matches[prevMatch1id]? and
                    (match.player_1 == loser1 or
                    match.player_2 == loser1)) or
                    (@bracket1.matches[prevMatch2id]? and
                    (match.player_1 == loser2 or
                    match.player_2 == loser2))
                    
                    matchHasWinnerFromBrack2 = 
                    (@bracket2.matches[prevMatch1id]? and
                    (match.player_1 == prevMatch1.winner or
                    match.player_2 == prevMatch1.winner)) or
                    (@bracket2.matches[prevMatch2id]? and
                    (match.player_1 == prevMatch2.winner or
                    match.player_2 == prevMatch2.winner))
                    
                    matchHasTwoWinnersFromBrack2 = 
                    (@bracket2.matches[prevMatch1id]? and
                    (match.player_1 == prevMatch1.winner or
                    match.player_2 == prevMatch1.winner)) and
                    (@bracket2.matches[prevMatch2id]? and
                    (match.player_1 == prevMatch2.winner or
                    match.player_2 == prevMatch2.winner))
                    
                    if matchHasLoserFromBrack1 and matchHasWinnerFromBrack2 or
                    matchHasTwoWinnersFromBrack2
                        insertionMade = (true)
                        @bracket2.matches[id] = match

        ###
         # Here we find the last match in bracket 2. This can be found by
         # grabbing any match in the object, (which is only possible via
         # a javascript for, in loop) I use the loop to grab the first match
         # in the bracket, iterate up the subsequent games within bracket 2,
         # until I can't either subsequent matches in this bracket, 
         # and that will be the top of tier 2.
        ### 
        for id, match of @bracket2.matches
            nextId = id
            nextMatch = match
            
            subMatch1id = id
            subMatch2id = id
            subMatch1 = match
            subMatch2 = match
            
            while @bracket2.matches[subMatch1id]? or
            @bracket2.matches[subMatch2id]?
                if @bracket2.matches[subMatch1id]?
                    nextId = subMatch1id
                    nextMatch = subMatch1
                else if @bracket2.matches[subMatch2id]?
                    nextId = subMatch2id
                    nextMatch = subMatch2
                else
                    break

                subMatch1id = nextMatch.subsequent_matches[0].toString()
                subMatch2id = nextMatch.subsequent_matches[1].toString()
                subMatch1 = @tourneyData[subMatch1id]
                subMatch2 = @tourneyData[subMatch2id]
            
            @bracket2.lastmatch = nextId
            break
        
        ###
         # Here find bracket3 the same way we found bracket2. First find
         # all games that have two losers from the now complete bracket2.
        ###
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
                (@bracket2.matches[prevMatch1id]? and
                (match.player_1 == loser1 or
                match.player_2 == loser1)) and
                (@bracket2.matches[prevMatch2id]? and
                (match.player_1 == loser2 or
                match.player_2 == loser2))
                    
                if (matchHasTwoLosersFromBrack2)
                    @bracket3.matches[id] = match
        
        ###
         # The we find all the games that have a loser from bracket 2 and
         # a winner from bracket 3, and all games that have two winners
         # from brack 3.
        ###
        insertionMade = (true)
        while insertionMade
            insertionMade = (false)
            for id, match of @tourneyData
                if match.previous_matches.length > 0 and !@bracket3.matches[id]?
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
                    (@bracket2.matches[prevMatch1id]? and
                    (match.player_1 == loser1 or
                    match.player_2 == loser1)) or
                    (@bracket2.matches[prevMatch2id]? and
                    (match.player_1 == loser2 or
                    match.player_2 == loser2))
                    
                    matchHasWinnerFromBrack3 = 
                    (@bracket3.matches[prevMatch1id]? and
                    (match.player_1 == prevMatch1.winner or
                    match.player_2 == prevMatch1.winner)) or
                    (@bracket3.matches[prevMatch2id]? and
                    (match.player_1 == prevMatch2.winner or
                    match.player_2 == prevMatch2.winner))
                    
                    matchHasTwoWinnersFromBrack3 = 
                    (@bracket3.matches[prevMatch1id]? and
                    (match.player_1 == prevMatch1.winner or
                    match.player_2 == prevMatch1.winner)) and
                    (@bracket3.matches[prevMatch2id]? and
                    (match.player_1 == prevMatch2.winner or
                    match.player_2 == prevMatch2.winner))
                    
                    if matchHasLoserFromBrack2 and matchHasWinnerFromBrack3 or
                    matchHasTwoWinnersFromBrack3
                        insertionMade = (true)
                        @bracket3.matches[id] = match
        
        ###
         # We find the last match in bracket3 just as we found it in bracket2
        ### 
        for id, match of @bracket3.matches
            nextId = id
            nextMatch = match
            
            subMatch1id = id
            subMatch2id = id
            subMatch1 = match
            subMatch2 = match
            
            while @bracket3.matches[subMatch1id]? or
            @bracket3.matches[subMatch2id]?
                if @bracket3.matches[subMatch1id]?
                    nextId = subMatch1id
                    nextMatch = subMatch1
                else if @bracket3.matches[subMatch2id]?
                    nextId = subMatch2id
                    nextMatch = subMatch2
                else
                    break

                subMatch1id = nextMatch.subsequent_matches[0].toString()
                subMatch1 = @tourneyData[subMatch1id]
                if nextMatch.subsequent_matches.length == 2
                    subMatch2id = nextMatch.subsequent_matches[1].toString()
                    subMatch2 = @tourneyData[subMatch2id]
                else
                    subMatch2id = subMatch1id
                    subMatch2 = subMatch1
            
            @bracket3.lastmatch = nextId
            break
        
        ###
         # All the games that do no exist in the other brackets are 
         # the championship games
        ###
        for id, match of @tourneyData
            if !@bracket1.matches[id]? and 
            !@bracket2.matches[id]? and 
            !@bracket3.matches[id]?
                @champBracket.matches[id] = match
                
        ###
         # Since the last match in the champ bracket has no subsequent games,
         # it's very easy to just look through them and find the one with no
         # subsequent matches.
        ###
        for id, match of @champBracket.matches
            if match.subsequent_matches.length == 0
                @champBracket.lastmatch = id
                break
        
        console.log "Finished reading file."
                    
                
                
    resize: () ->
        @canvas.width = window.innerWidth
        @canvas.height = window.innerHeight
        @redraw()
    
    redraw: () ->
        
        
b = new BracketViewer