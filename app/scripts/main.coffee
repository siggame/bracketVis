    
class Player
    constructor: (@name, @health) ->
        if !@name?
            @name = (null)
        if !@health?
            @health = (null)
    
class PlayerSlot
    constructor: (@player) ->
        @is_slot = () -> true
        @visible = (false)
        @isVisible = () -> @visible
        
class Bracket
    constructor: () ->
        @lastmatch = (null)
        @matches = {}

class Rect
    constructor: () ->
        @x = 0
        @y = 0
        @w = 0
        @h = 0

class Button
    constructor: () ->
        @pos = new Rect
        @text = "Reveal"
        @color = "#000000"
        @func = null
        
    ifClick: (x, y) ->
        if x > @pos.x and
        x < @pos.x + @pos.w and
        y > @pos.y and
        y < @pos.y + @pos.h and
        @func != null
            @func()
            
    click: () ->
        if @func != (null)
            @func()
            
    draw: (context) ->
        context.beginPath() 
        context.rect(@pos.x, @pos.y,
        @pos.w, @pos.h)
        context.fillStyle = @color
        context.strokeStyle = "#000000"
        context.fill()
        context.stroke()
        
        context.font = '18px Verdana'
        context.textAlign = 'left'
        context.fillStyle = '#000000'
        textWidth = context.measureText(@text).width
        textx = @pos.x + (@pos.w/2) - (textWidth/2)
        texty = @pos.y + (@pos.h/2) + 8
        context.fillText(@text, textx, texty)  
        
###
 # Every Bracket has a list of matches and playerslots
 # Every Match has a list of previous matches and a winner
 # A PlayerSlot can contain a Player or be null
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
        @rectStroke = "#000000"
        @rectFill = "#AAAAAA"
        @rectWidth = 110
        @rectHeight = 40
        @textHeight = "14px"
        @fileLoaded = (false)
        @currentDrawFunction = (null)
        @currentBracket = null
        
        @brackButtons = []
        @brackButtons.push new Button
        @brackButtons.push new Button
        @brackButtons.push new Button
        
        try
            @context = @canvas.getContext "2d"
        catch
            throw Message: "Failure to get canvas context."
        
        mainDiv = document.getElementById "mainContent"
        
        $(mainDiv).bind 'dragover', (event) ->
            event.stopPropagation()
            event.preventDefault()
            
        $(mainDiv).bind 'drop', @drop
        
        $(window).resize @resize
        $(@canvas).on 'click', @onclick
        @resize()
            
    drawMatchPageFunc: (id, match) =>
        revealBtn = new Button
        revealBtn.pos.w = 120
        revealBtn.pos.h = 60
        revealBtn.pos.x = (0.5 * @canvas.width) - (revealBtn.pos.w/2)
        revealBtn.pos.y = (0.90 * @canvas.height) - (revealBtn.pos.h/2)
        revealBtn.text = "Reveal"
        revealBtn.color = "#AAAAAA"
        revealBtn.func = () =>
            @tourneyData[id].visible = (true)
            if @bracket2.matches[id]?
                @bracket2.matches[id].visible = (true)
            if @bracket3.matches[id]?
                @bracket3.matches[id].visible = (true)
            
            revealPreviousMatches = (nextid, nextMatch) =>
                nextMatch.visible = (true)
                if @bracket2.matches[nextid]?
                    @bracket2.matches[nextid].visible = (true)
                if @bracket3.matches[nextid]?
                    @bracket3.matches[nextid].visible = (true)

                if nextMatch.previous_matches.length == 0    
                    return
                    
                prevMatch1id = nextMatch.previous_matches[0].toString()
                prevMatch2id = nextMatch.previous_matches[1].toString()
                prevMatch1 = @tourneyData[prevMatch1id]
                prevMatch2 = @tourneyData[prevMatch2id]
                
                revealPreviousMatches(prevMatch1id, prevMatch1)
                revealPreviousMatches(prevMatch2id, prevMatch2)
            
            revealPreviousMatches(id, match)
            @redraw()
       
        previousBracket = @currentBracket
        
        backBtn = new Button
        backBtn.pos.w = 60
        backBtn.pos.h = 40
        backBtn.pos.x = (0.15 * @canvas.width) - (backBtn.pos.w/2)
        backBtn.pos.y = (0.15 * @canvas.height) - (backBtn.pos.h/2)
        backBtn.text = "Back"
        backBtn.color = "#AAAAAA"
        backBtn.func = () =>
            @currentDrawFunction = @drawBracketFunc(previousBracket)
            $(@canvas).off 'click'
            $(@canvas).on 'click', @onclick
            @redraw()
        
        matchPageClick = (event) =>
            offset = $(@canvas).offset()
            x = event.clientX - offset.left
            y = event.clientY - offset.top
            
            revealBtn.ifClick(x, y)
            backBtn.ifClick(x, y)
            
        $(@canvas).off 'click'
        $(@canvas).on 'click', matchPageClick
        
        drawFunc = () =>
            backBtn.draw(@context)            
            revealBtn.draw(@context)
            
            player1 = match.player_1
            player2 = match.player_2
            
            @context.font = '30px Verdana'
            @context.textAlign = 'left'
            @context.fillStyle = '#000000'
            textx = (0.20 * @canvas.width)
            texty = (0.5 * @canvas.height)
            maxWidth = (0.45 * @canvas.width) - (0.2 * @canvas.width)
            @context.fillText(player1, textx, texty, maxWidth)
            textx = (0.80 * @canvas.width)
            texty = (0.5 * @canvas.height)
            @context.textAlign = 'right'
            @context.fillText(player2, textx, texty, maxWidth)
            
            if match.isVisible()
                @context.font = '30px Verdana'
                @context.textAlign = 'center'
                @context.fillStyle = '#000000'
                textx = (0.5 * @canvas.width)
                texty = (0.7 * @canvas.height)
                @context.fillText("Winner:", textx, texty)
                
                @context.font = '30px Verdana'
                @context.textAlign = 'center'
                @context.fillStyle = '#000000'
                texty += 33
                @context.fillText(match.winner, textx, texty)
            else
                @context.font = '30px Verdana'
                @context.textAlign = 'center'
                @context.fillStyle = '#000000'
                textx = (0.5 * @canvas.width)
                texty = (0.7 * @canvas.height)
                @context.fillText("Log Location:", textx, texty)
                
                @context.font = '30px Verdana'
                @context.textAlign = 'center'
                @context.fillStyle = '#000000'
                texty += 33
                @context.fillText(match.log_location, textx, texty)
           
            @context.textAlign = 'center' 
            @context.fillStyle = '#ff0000'
            textx = (0.5 * @canvas.width)
            texty = (0.5 * @canvas.height)
            @context.fillText(".vs", textx, texty)
            
            
    drawBracketFunc: (bracket) =>
        $(@canvas).off 'click'
        $(@canvas).on 'click', @onclick
        drawFunc = () =>
            @drawBracket(bracket)
            
    onclick: (event) =>
        if @fileLoaded
            for id, match of @tourneyData
                offset = $(@canvas).offset()
                x = event.clientX - offset.left
                y = event.clientY - offset.top
                
                if x > match.click_field.x and 
                x < match.click_field.x + match.click_field.w and
                y > match.click_field.y and
                y < match.click_field.y + match.click_field.h
                    @currentDrawFunction = @drawMatchPageFunc(id, match)
                    @redraw()
            
            for btn in @brackButtons
                btn.ifClick x,y
                
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
         # for each previous game.
        ###
        for id, match of @tourneyData
            match.is_slot = () -> (false)
            
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
      
            match.click_field = new Rect
            
            match.visible = (false)
            match.isVisible = () -> @visible 
      
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
        
        ###
         # For all the matches that have previous games in other brackets,
         # add a player slot to the bracket in it's place. They are always
         # losers in the case of all the games in bracket 2 and 3.
        ###
        for id, match of @bracket2.matches
            if match.previous_matches.length > 0
                prevMatch1id = match.previous_matches[0].toString()
                prevMatch2id = match.previous_matches[1].toString()
                prevMatch1 = @tourneyData[prevMatch1id]
                prevMatch2 = @tourneyData[prevMatch2id]
                
                if !@bracket2.matches[prevMatch1id]?
                    if prevMatch1.winner == prevMatch1.player_1 
                        @bracket2.matches[prevMatch1id] = new PlayerSlot(prevMatch1.player_2)
                    else
                        @bracket2.matches[prevMatch1id] = new PlayerSlot(prevMatch1.player_1)
                if !@bracket2.matches[prevMatch2id]?
                    if prevMatch2.winner == prevMatch2.player_1
                        @bracket2.matches[prevMatch2id] = new PlayerSlot(prevMatch2.player_2)
                    else
                        @bracket2.matches[prevMatch2id] = new PlayerSlot(prevMatch2.player_1)
        
        ###
         # Same for bracket 3; put player slots where games do not exist
         # in the bracket.
        ###
        for id, match of @bracket3.matches
            if match.previous_matches.length > 0
                prevMatch1id = match.previous_matches[0].toString()
                prevMatch2id = match.previous_matches[1].toString()
                prevMatch1 = @tourneyData[prevMatch1id]
                prevMatch2 = @tourneyData[prevMatch2id]
                
                if !@bracket3.matches[prevMatch1id]?
                    if prevMatch1.winner == prevMatch1.player_1 
                        @bracket3.matches[prevMatch1id] = new PlayerSlot(prevMatch1.player_2)
                    else
                        @bracket3.matches[prevMatch1id] = new PlayerSlot(prevMatch1.player_1)
                if !@bracket3.matches[prevMatch2id]?
                    if prevMatch2.winner == prevMatch2.player_1
                        @bracket3.matches[prevMatch2id] = new PlayerSlot(prevMatch2.player_2)
                    else
                        @bracket3.matches[prevMatch2id] = new PlayerSlot(prevMatch2.player_1)
        
        @currentDrawFunction = @drawBracketFunc(@bracket1)
        @currentBracket = @bracket1
        @fileLoaded = (true)
        @redraw()
                
    drawPlayerSlot : (bracket, slot, x1, x2, y1, y2, goLeft) =>
        width = x2 - x1
        height = y2 - y1
        
        rectx = ((width/2) * @canvas.width) - (@rectWidth/2)
        recty = ((height/2) * @canvas.height) - (@rectHeight/2)
        
        @context.beginPath()    
        @context.rect( (x1 * @canvas.width) + rectx, 
        (y1 * @canvas.height)+ recty,
        @rectWidth,
        @rectHeight)
        @context.fillStyle = @rectFill
        @context.strokeStyle = @rectStroke
        @context.lineWidth = 1
        @context.fill()
        @context.stroke()
        
        if !goLeft
            linex1 = parseInt(x1 * @canvas.width) + 0.5
            linex2 = linex1 + parseInt(rectx)
        else
            linex1 = parseInt((x1 * @canvas.width) + 
            rectx + @rectWidth) + 0.5
            linex2 = parseInt(x2 * @canvas.width) + 0.5
        liney = parseInt((y1 * @canvas.height) + recty + 
        (@rectHeight/2)) + 0.5
        @context.beginPath()                
        @context.moveTo(linex1, liney)
        @context.lineTo(linex2, liney)
        @context.strokeStyle = "#000000"
        @context.lineWidth = 1
        @context.stroke()
        
        if slot.isVisible()
            text = slot.player
            #line 1
            i = 0
            j = 0
            while @context.measureText(text.substring(0, i+1)).width < @rectWidth
                if text.substring(0, i) == text
                    break;
                i++
            
            #line 2
            if text.substring(0, i) != text
                j = i
                while @context.measureText(text.substring(i, j + 1)).width < @rectWidth
                    if j >= text.length
                        break;
                    j++
            
            @context.font = @textHeight + ' Verdana'
            @context.textAlign = 'center'
            @context.fillStyle = '#000000'
            if j == 0
                @context.fillText(text.substring(0, i), 
                (x1 * @canvas.width) + rectx + (@rectWidth/2), 
                (y1 * @canvas.height) + recty + (@rectHeight/2) + (parseInt(@textHeight)/2) - 1)                  
            else
                @context.fillText(text.substring(0, i),
                (x1 * @canvas.width) + rectx + (@rectWidth/2),
                (y1 * @canvas.height) + recty + (@rectHeight/2) - 3)
                @context.textAlign = 'left'
                @context.fillText(text.substring(i, j)
                (x1 * @canvas.width) + rectx,
                (y1 * @canvas.height) + recty + @rectHeight - 3)
                    
    drawMatch : (bracket, match, x1, x2, y1, y2, xinc, goLeft, alignment) =>   
        width = x2 - x1
        height = y2 - y1    
        
        switch alignment
            when "middle"
                rectx = (width/2) * @canvas.width - (@rectWidth/2)
                recty = (height/2) * @canvas.height - (@rectHeight/2)
            when "bottom"
                rectx = (width/2) * @canvas.width - (@rectWidth/2)
                recty = height * @canvas.height - (@rectHeight) - 5
            
        @context.beginPath()    
        @context.rect( (x1 * @canvas.width) + rectx, 
        (y1 * @canvas.height)+ recty,
        @rectWidth,
        @rectHeight)
        @context.fillStyle = @rectFill
        @context.strokeStyle = @rectStroke
        @context.lineWidth = 1
        @context.fill()
        @context.stroke()
        
        match.click_field.x = (x1 * @canvas.width) + rectx
        match.click_field.y = (y1 * @canvas.height) + recty
        match.click_field.w = @rectWidth
        match.click_field.h = @rectHeight
        
        linex1 = parseInt(x1 * @canvas.width) + 0.5
        linex2 = linex1 + parseInt(rectx)
        linex3 = linex2 + parseInt(@rectWidth)
        linex4 = parseInt(x2 * @canvas.width) + 0.5
        liney = parseInt((y1 * @canvas.height) + recty +                
        (@rectHeight/2)) + 0.5
        @context.moveTo(linex1, liney)
        @context.lineTo(linex2, liney)
        @context.moveTo(linex3, liney)
        @context.lineTo(linex4, liney)
        @context.lineTo(linex4, liney2)
        @context.strokeStyle = "#000000"
        @context.lineWidth = 1
        @context.stroke()
        
        if match.isVisible()
            if match.is_slot()
                text = match.player
            else
                text = match.winner
            
            @context.font = @textHeight + ' Verdana'
            @context.textAlign = 'center'
            @context.fillStyle = '#000000'
            #line 1
            i = 0
            j = 0
            while @context.measureText(text.substring(0, i+1)).width < @rectWidth
                if text.substring(0, i) == text
                    break;
                i++
            
            #line 2
            if text.substring(0, i) != text
                j = i
                while @context.measureText(text.substring(i, j + 1)).width < @rectWidth
                    if j >= text.length
                        break;
                    j++                
            
            if j == 0
                @context.fillText(text.substring(0, i), 
                (x1 * @canvas.width) + rectx + (@rectWidth/2), 
                (y1 * @canvas.height) + recty + (@rectHeight/2) + (parseInt(@textHeight)/2) - 1)                  
            else
                @context.fillText(text.substring(0, i),
                (x1 * @canvas.width) + rectx + (@rectWidth/2),
                (y1 * @canvas.height) + recty + (@rectHeight/2) - 3)
                @context.textAlign = 'left'
                @context.fillText(text.substring(i, j)
                (x1 * @canvas.width) + rectx,
                (y1 * @canvas.height) + recty + @rectHeight - 3)
        
        if match.previous_matches.length == 0
            slot1y1 = y1
            slot1y2 = y1 + (height/2)
            slot2y1 = slot1y2
            slot2y2 = y2
            
            slot1 = new PlayerSlot match.player_1
            slot1.visible = true
            slot2 = new PlayerSlot match.player_2
            slot2.visible = true
            
            @context.beginPath()
            if goLeft
                linex = (x1 * @canvas.width)
            else
                linex = (x2 * @canvas.width)
            liney1 = ((slot1y1 * @canvas.height) + 
            (((slot1y2 - slot1y1)/2) * @canvas.height))
            liney2 = ((slot2y1 * @canvas.height) +
            (((slot2y2 - slot2y1)/2) * @canvas.height))
            @context.moveTo(linex, liney1)
            @context.lineTo(linex, liney2)
            @context.strokeStyle = "#000000"
            @context.lineWidth = 1
            @context.stroke()                    
            
            if goLeft
                @drawPlayerSlot(bracket, slot1, x1 - xinc, x1,
                slot1y1, slot1y2, goLeft)
                @drawPlayerSlot(bracket, slot2, x1 - xinc, x1,
                slot2y1, slot2y2, goLeft)
            else
                @drawPlayerSlot(bracket, slot1, x2, x2 + xinc,
                slot1y1, slot1y2, goLeft)
                @drawPlayerSlot(bracket, slot2, x2, x2 + xinc,
                slot2y1, slot2y2, goLeft)
            return
            
        prevMatch1id = match.previous_matches[0]
        prevMatch2id = match.previous_matches[1]
        prevMatch1 = bracket.matches[prevMatch1id]
        prevMatch2 = bracket.matches[prevMatch2id]
        
        prevMatch1y1 = y1
        if prevMatch1.is_slot() && !prevMatch2.is_slot()
            prevMatch1y2 = y1 + @rectHeight/@canvas.height + 10/@canvas.height
            prevMatch2y1 = y1
        else if !prevMatch1.is_slot() && prevMatch2.is_slot()
            prevMatch1y2 = y2
            prevMatch2y1 = y2 - @rectHeight/@canvas.height - 10/@canvas.height
        else
            prevMatch1y2 = y1 + (height/2)
            prevMatch2y1 = prevMatch1y2
        prevMatch2y2 = y2#prevMatch2y1 + (prevMatch2Value * (height/divisor))
        
        @context.beginPath()
        if goLeft
            linex = (x1 * @canvas.width)
        else
            linex = (x2 * @canvas.width)
        

        liney1 = ((prevMatch1y1 * @canvas.height) + 
        (((prevMatch1y2 - prevMatch1y1)/2) * @canvas.height))
        liney2 = liney = parseInt((y1 * @canvas.height) + recty +                
        (@rectHeight/2)) + 0.5
        if (@rectHeight >
        ((height/2) * @canvas.height) - (@rectHeight/2))
            if !prevMatch1.is_slot() and prevMatch2.is_slot()
                liney3 = (prevMatch1y2 * @canvas.height) -
                (@rectHeight/2) - 5
            else if prevMatch1.is_slot() and !prevMatch2.is_slot()
                liney3 = (prevMatch2y2 * @canvas.height) -
                (@rectHeight/2) - 5
            else
                liney3 = ((prevMatch2y1 * @canvas.height) +
                (((prevMatch2y2 - prevMatch2y1)/2) * @canvas.height))
        else
            liney3 = ((prevMatch2y1 * @canvas.height) +
            (((prevMatch2y2 - prevMatch2y1)/2) * @canvas.height))

        @context.moveTo(linex, liney1)
        @context.lineTo(linex, liney2)
        @context.lineTo(linex, liney3)
        @context.strokeStyle = "#000000"
        @context.lineWidth = 1
        @context.stroke()

        
        if (@rectHeight >
        ((height/2) * @canvas.height) - (@rectHeight/2))
            a = "bottom"
        else
            a = "middle"
            
        if goLeft
            if prevMatch1.is_slot()
                @drawPlayerSlot(bracket, prevMatch1, x1-xinc, x1,
                prevMatch1y1, prevMatch1y2, goLeft)
            else
                @drawMatch(bracket, prevMatch1, x1-xinc, x1, prevMatch1y1, 
                prevMatch1y2, xinc, goLeft, a)
            if prevMatch2.is_slot()    
                @drawPlayerSlot(bracket, prevMatch2, x1-xinc, x1,
                prevMatch2y1, prevMatch2y2, goLeft)
            else
                @drawMatch(bracket, prevMatch2, x1-xinc, x1, prevMatch2y1,
                prevMatch2y2, xinc, goLeft, a)
        else
            if prevMatch1.is_slot()
                @drawPlayerSlot(bracket, prevMatch1, x2, x2+xinc,
                prevMatch1y1, prevMatch1y2, goLeft)
            else
                @drawMatch(bracket, prevMatch1, x2, x2+xinc, prevMatch1y1,
                prevMatch1y2, xinc, goLeft, a)
            if prevMatch2.is_slot()
                @drawPlayerSlot(bracket, prevMatch2, x2, x2+xinc,
                prevMatch2y1, prevMatch2y2, goLeft)
            else
                @drawMatch(bracket, prevMatch2, x2, x2+xinc, prevMatch2y1,
                prevMatch2y2, xinc, goLeft, a)
    
    drawBracket : (bracket) =>
        match = bracket.matches[bracket.lastmatch]
        prevMatch1id = match.previous_matches[0].toString()
        prevMatch2id = match.previous_matches[1].toString()
        prevMatch1 = bracket.matches[prevMatch1id]
        prevMatch2 = bracket.matches[prevMatch2id]
                
        d1 = @depthRecurse(bracket, 0, prevMatch1)
        d2 = @depthRecurse(bracket, 0, prevMatch2)
    
        if d1 == d2
            xDivisions = d1 + d2 + 1
        else
            xDivisions = (if d1 > d2 then d1 else d2) + 1

        if d1 == d2
            initialx1 = (1/xDivisions) * d1
            initialx2 = initialx1 + (1/xDivisions)
        else
            initialx1 = 0
            initialx2 = initialx1 + (1/xDivisions)
        
        initwidth = initialx2 - initialx1
        initheight = 1    
        
        initrectx = ((initwidth/2) * @canvas.width) - (@rectWidth/2)
        initrecty = ((initheight/2) * @canvas.height) - (@rectHeight/2)
            
        @context.beginPath()
        @context.rect( (initialx1 * @canvas.width) + initrectx, 
        initrecty,
        @rectWidth,
        @rectHeight)
        @context.fillStyle = @rectFill
        @context.strokeStyle = @rectStroke
        @context.lineWidth = 1
        @context.fill()
        @context.stroke()
        
        match.click_field.x = (initialx1 * @canvas.width) + initrectx
        match.click_field.y = initrecty
        match.click_field.w = @rectWidth
        match.click_field.h = @rectHeight
        
        linex1 = parseInt(initialx1 * @canvas.width) + 0.5
        linex2 = linex1 + parseInt(initrectx)
        linex3 = linex2 + parseInt(@rectWidth)
        linex4 = parseInt(initialx2 * @canvas.width) + 0.5
        liney = parseInt(initrecty + (@rectHeight/2)) + 0.5
        @context.beginPath()
        if d1 == d2
            @context.moveTo(linex1, liney)
            @context.lineTo(linex2, liney)
        @context.moveTo(linex3, liney)
        @context.lineTo(linex4, liney)
        @context.strokeStyle = "#000000"
        @context.lineWidth = 1
        @context.stroke()
        
        @context.font = @textHeight + ' Verdana'
        @context.textAlign = 'center'
        @context.fillStyle = '#000000'
        if match.isVisible()
            text = match.winner
            #line 1
            i = 0
            j = 0
            while @context.measureText(text.substring(0, i+1)).width < @rectWidth
                if text.substring(0, i) == text
                    break;
                i++
            
            #line 2
            if text.substring(0, i) != text
                j = i
                while @context.measureText(text.substring(i, j + 1)).width < @rectWidth
                    if j >= text.length
                        break;
                    j++
            
            if j == 0
                @context.fillText(text.substring(0, i), 
                (initialx1 * @canvas.width) + initrectx + (@rectWidth/2), 
                initrecty + (@rectHeight/2) + (parseInt(@textHeight)/2) - 1)                  
            else
                @context.fillText(text.substring(0, i),
                (initialx1 * @canvas.width) + initrectx + (@rectWidth/2),
                initrecty + (@rectHeight/2) - 3)
                @context.textAlign = 'left'
                @context.fillText(text.substring(i, j)
                (initialx1 * @canvas.width) + initrectx,
                initrecty + @rectHeight - 3)
        
        if d1 == d2
            if prevMatch1.is_slot()
                @drawPlayerSlot(bracket, prevMatch1, initialx1 - (1/xDivisions), initialx1,
                0, 1, (1/xDivisions), (true))
            else
                @drawMatch(bracket, prevMatch1, initialx1 - (1/xDivisions), initialx1, 
                0, 1, (1/xDivisions), (true), "middle")
            if prevMatch2.is_slot()
                @drawPlayerSlot(bracket, prevMatch2, initialx2, initialx2 + (1/xDivisions),
                0, 1, (1/xDivisions), (false))
            else
                @drawMatch(bracket, prevMatch2, initialx2, initialx2 + (1/xDivisions),
                0, 1, (1/xDivisions), (false), "middle")
        else
            if prevMatch1.is_slot() and !prevMatch2.is_slot()
                @context.beginPath()
                liney = parseInt((((@rectHeight/@canvas.height) + (10/@canvas.height))/2) *
                @canvas.height) + 0.5
                @context.moveTo(initialx2 * @canvas.width, liney)
                @context.lineTo(initialx2 * @canvas.width, parseInt((1/2) * @canvas.height) + 0.5)
                @context.stroke()
                @drawPlayerSlot(bracket, prevMatch1, initialx2, initialx2 + (1/xDivisions),
                0, (@rectHeight/@canvas.height) + (10/@canvas.height), false)
                @drawMatch(bracket, prevMatch2, initialx2, initialx2 + (1/xDivisions),
                0, 1, (1/xDivisions), false, "middle")
            else if !prevMatch1.is_slot() and prevMatch2.is_slot()
                @context.beginPath()
                liney = parseInt((((@rectHeight/@canvas.height) + (10/@canvas.height))/2) *
                @canvas.height) + 0.5
                @context.moveTo(initialx2 * @canvas.width, liney)
                @context.lineTo(initialx2 * @canvas.width, parseInt((1/2) * @canvas.height) + 0.5)
                @context.stroke()
                @drawMatch(bracket, prevMatch1, initialx2, initialx2 + (1/xDivisions),
                0, 1, (1/xDivisions), false, "middle")
                @drawPlayerSlot(bracket, prevMatch2, initialx2, initialx2 + (1/xDivisions),
                0, (@rectHeight/@canvas.height) + (10/@canvas.height), false)
        @drawBracketSwitcher()

    drawBracketSwitcher: () ->
        w = (30)
        h = (30)
        x = (0.5 * @canvas.width) - (w/2)
        y = (0.95 * @canvas.height) - (h/2)

        @brackButtons[1].pos.w = w
        @brackButtons[1].pos.h = h
        @brackButtons[1].pos.x = x
        @brackButtons[1].pos.y = y
        @brackButtons[1].text = "2"
        @brackButtons[1].color = "#FFFFFF"
        @brackButtons[1].func = () =>
            @currentDrawFunction = @drawBracketFunc(@bracket2)
            @currentBracket = @bracket2
            @redraw()
        
        @brackButtons[0].pos.w = w
        @brackButtons[0].pos.h = h
        @brackButtons[0].pos.x = x - (w + 5)
        @brackButtons[0].pos.y = y
        @brackButtons[0].text = "1"
        @brackButtons[0].color = "#FFFFFF"
        @brackButtons[0].func = () =>
            @currentDrawFunction = @drawBracketFunc(@bracket1)
            @currentBracket = @bracket1
            @redraw()
            
        @brackButtons[2].pos.w = w
        @brackButtons[2].pos.h = h
        @brackButtons[2].pos.x = x + (w + 5)
        @brackButtons[2].pos.y = y
        @brackButtons[2].text = "3"
        @brackButtons[2].color = "#FFFFFF"
        @brackButtons[2].func = () =>
            @currentDrawFunction = @drawBracketFunc(@bracket3)
            @currentBracket = @bracket3
            @redraw()
        
        for btn in @brackButtons
            btn.draw(@context) 
        
        
    depthRecurse : (bracket, depth, match) =>
        if match.is_slot()
            return depth + 1
        if match.previous_matches.length == 0
            return depth + 2
    
        prev1id = match.previous_matches[0].toString()
        prev2id = match.previous_matches[1].toString()
        prev1 = bracket.matches[prev1id]
        prev2 = bracket.matches[prev2id]
    
        v1 = 0
        v2 = 0
        if prev1?
            v1 = @depthRecurse(bracket, depth+1, prev1)
        if prev2?
            v2 = @depthRecurse(bracket, depth+1, prev2)
        return if v1 > v2 then v1 else v2
    
    resize: () =>
        @canvas.width = $(window).width() - 5
        @canvas.height = $(window).height() - 5
        @redraw()
        console.log "resized"
    
    redraw: () =>
        @canvas.width = @canvas.width
        if @currentDrawFunction != (null)
            @currentDrawFunction()
        console.log "redrawn"
        
b = new BracketViewer