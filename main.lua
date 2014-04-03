if love == nil then
	love = {}
end

function love.load()
	BGCOLOR = {183, 166, 151, 255}
	TEXTCOLOR = {{120, 110, 100}, {249,246,242}}
	COLORS = {}
	COLORS[0]  = {205, 192, 180}
	COLORS[2]  = {236, 224, 212}
	COLORS[4]  = {231, 218, 193}
	COLORS[8]  = {242, 177, 121}
	COLORS[16] = {245, 149, 99 }
	COLORS[32] = {246, 124, 99 }
	COLORS[64] = {246, 94,  59 }
	COLORS[128] = {237, 207, 114 }
	COLORS[256] = {237, 204, 97 }
	COLORS[512] = {237, 200, 80 }
	COLORS[1024] = {237, 197, 63 }
	COLORS[2048] = {237, 194, 46 }

	ntiles = {4,4}
	windowsize = 640
	screen = {windowsize*ntiles[1]/ntiles[2], windowsize}
	if love.window ~= nil then -- love >= 0.9
		screen = {love.window.getDimensions()}
	else
		love.graphics.setIcon(love.graphics.newImage("icon.png"))
		screen = {love.graphics.getMode()}
	end
	tilesize = math.min(screen[1]/ntiles[1], screen[2]/ntiles[2])
	grid = {}
	for i=1,ntiles[1] do
		local lin = {}
		for j=1,ntiles[2] do
			table.insert(lin,0)
		end
		table.insert(grid,lin)
	end
	for i=1,2 do addrandomtile() end
	msg_font = love.graphics.newFont("JosefinSans.ttf", 40 )
	font = love.graphics.newFont("PT Sans Caption.ttf", tilesize*0.3 )
	love.graphics.setFont( font )
	margin = 2
	game_end = "no" -- "won", "lost", or "no"
	history.grids={} -- initialize game history
	history:save()
end

function isgameover ()
	for i=1,ntiles[1] do
		for j=1,ntiles[2] do
			if grid[i][j] == 0 or
				(j+1<=ntiles[2] and grid[i][j] == grid[i][j+1]) or
				(i+1<=ntiles[1] and grid[i][j] == grid[i+1][j]) then
				return false
			end
		end
	end
	return true
end

function addrandomtile ()
	local freecells = {}
	for i=1,ntiles[1] do
		for j=1,ntiles[2] do
			if grid[i][j] == 0 then
				table.insert(freecells, {i,j})
			end
		end
	end
	if #freecells == 0 then return false end
	local cell = freecells[1 + math.floor(math.random() * #freecells)]
	grid[cell[1]][cell[2]] = 2 + 2*math.floor(math.random()/0.9)
	return true
end


function playline (line)
	-- plays just one line
	local write=1
	local canmerge = true
	local changed = false
	-- push the numbers
	for i=1,#line do
		if line[i] ~= 0 then
			line[write] = line[i]
			if canmerge and write>1 and line[write] == line[write-1] then
				line[write-1] = line[write-1]*2
				if line[write-1] == 2048 then game_end = "won" end
				line[write] = 0
				canmerge = false
				changed = true
			else
				canmerge = true
				write = write+1
			end
		end
		if i>=write and line[i] ~= 0 then
			changed = true
			line[i] = 0
		end
	end
	return changed
end

function play (direction)
	local changed = false
	local axis = direction % 2
	local reverse = math.floor((direction%4)/2)
	local step = -1 + 2*reverse
	local len = ntiles[2-axis]
	local start = len - reverse*(len-1)
	for n=1,ntiles[1+axis] do
		local line = {}
		for i=start,len-start+1,step do
			table.insert(line,grid[ n*(1-axis) + i*axis ][ i*(1-axis) + n*axis ])
		end
		changed = playline(line) or changed
		for i=1,#line do
			grid[ n*(1-axis) + i*axis ][ i*(1-axis) + n*axis ] = line[start + step*(i-1)]
		end
	end
	return changed
end

function drawgrid()
	-- background
	love.graphics.setColor(BGCOLOR)
	love.graphics.rectangle("fill", 0, 0, tilesize*ntiles[1], tilesize*ntiles[2] )

	love.graphics.setFont(font)
	for i=1,ntiles[1] do
		for j=1,ntiles[2] do
			local x = (i-1)*tilesize
			local y= (j-1)*tilesize
			local num = grid[i][j]

			local color = COLORS[num]
			if color == nil then color = COLORS[128] end
			love.graphics.setColor(color)
			love.graphics.rectangle("fill", x, y, tilesize-2*margin, tilesize-2*margin )

			if num > 0 then
				local w = font:getWidth(num)
				local h = font:getHeight()
				local color = TEXTCOLOR[2]
				if num <= 4 then color = TEXTCOLOR[1] end
				love.graphics.setColor(color)
				love.graphics.print(num, x + (tilesize-w)/2, y + (tilesize-h)/2)
			end
		end
	end
end

function love.draw()
	drawgrid()
	if game_end ~= "no" then
		love.graphics.setColor({246, 94,  59, 50})
		love.graphics.rectangle("fill", 0, 0, screen[1], screen[2])
		love.graphics.setColor(TEXTCOLOR[1])
		local msg_txt = "You lost ! (Press r to try again)"
		if game_end == "won" then msg_txt = "You won !" end
		local w = msg_font:getWidth(msg_txt)
		local h = msg_font:getHeight()
		love.graphics.setFont(msg_font)
		love.graphics.print(msg_txt, (screen[1]-w)/2, (screen[2]-h)/2)
	end
end

history = {grids={}, maxsize=5}
function history:save ()
	local oldgrid = {}
	for i=1,ntiles[1] do
		oldgrid[i] = {}
		for j=1,ntiles[2] do
			oldgrid[i][j] = grid[i][j]
		end
	end
	table.insert(self.grids, oldgrid)
	if #self.grids > self.maxsize then
		table.remove(self.grids,1)
	end
end
function history:revert()
	if #self.grids > 0 then
		grid = table.remove(self.grids)
	end
end

function love.keypressed(key)
	local changed = false

	history:save()

	if key == "left" then changed = play(3)
	elseif key == "up" then changed = play (2)
	elseif key == "right" then changed = play (1)
	elseif key == "down" then changed = play(0)
	elseif key== "backspace" then -- cancel the last move
		history:revert()
		game_end = "no"
	elseif key == "r" then -- retry
		love.load()
	end

	if changed then
		addrandomtile()
		if isgameover() then game_end = "lost" end
	else
		history:revert()
	end
end
