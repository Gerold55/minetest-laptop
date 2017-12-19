-- Based on https://github.com/minetest-mods/homedecor_modpack/blob/master/computer/tetris.lua

local shapes = {
   {  { x = {0, 1, 0, 1}, y = {0, 0, 1, 1} } },

   {  { x = {1, 1, 1, 1}, y = {0, 1, 2, 3} },
      { x = {0, 1, 2, 3}, y = {1, 1, 1, 1} } },

   {  { x = {0, 0, 1, 1}, y = {0, 1, 1, 2} },
      { x = {1, 2, 0, 1}, y = {0, 0, 1, 1} } },

   {  { x = {1, 0, 1, 0}, y = {0, 1, 1, 2} },
      { x = {0, 1, 1, 2}, y = {0, 0, 1, 1} } },

   {  { x = {1, 2, 1, 1}, y = {0, 0, 1, 2} },
      { x = {0, 1, 2, 2}, y = {1, 1, 1, 2} },
      { x = {1, 1, 0, 1}, y = {0, 1, 2, 2} },
      { x = {0, 0, 1, 2}, y = {0, 1, 1, 1} } },

   {  { x = {1, 1, 1, 2}, y = {0, 1, 2, 2} },
      { x = {0, 1, 2, 0}, y = {1, 1, 1, 2} },
      { x = {0, 1, 1, 1}, y = {0, 0, 1, 2} },
      { x = {0, 1, 2, 2}, y = {1, 1, 1, 0} } },

   {  { x = {1, 0, 1, 2}, y = {0, 1, 1, 1} },
      { x = {1, 1, 1, 2}, y = {0, 1, 2, 1} },
      { x = {0, 1, 2, 1}, y = {1, 1, 1, 2} },
      { x = {0, 1, 1, 1}, y = {1, 0, 1, 2} } } }

local colors = { "wool_cyan.png", "wool_magenta.png", "wool_red.png",
		"wool_blue.png", "wool_green.png", "wool_orange.png", "wool_yellow.png" }

local boardx, boardy = 0, 0
local sizex, sizey, size = 0.29, 0.29, 0.31

local comma = ","
local semi = ";"
local close = "]"

local concat = table.concat
local insert = table.insert



local draw_shape = function(id, x, y, rot, posx, posy)
	local d = shapes[id][rot]
	local scr = {}
	local ins = #scr
	for i=1,4 do
		local tmp = { "image[",
			(d.x[i]+x)*sizex+posx, comma,
			(d.y[i]+y)*sizey+posy, semi,
			size, comma, size, semi,
			colors[id], close }

		ins = ins + 1
		scr[ins] = concat(tmp)
	end
	return concat(scr)
end


local tetris_class = {}
tetris_class.__index = tetris_class

function get_tetris(app, data)
	local self = setmetatable({}, tetris_class)
	self.data = data
	self.app = app
	return self
end


function tetris_class:new_game()
	local nex = math.random(7)
	self.data.t = {
			board = {},
			boardstring = "",
			previewstring = draw_shape(nex, 0, 0, 1, 4, 1),
			score = 0,
			cur = math.random(7),
			nex = nex,
			x=4, y=0, rot=1
		}
	self.app:get_timer():start(0.3)
end


function tetris_class:update_boardstring()
	local scr = {}
	local ins = #scr
	for i, line in pairs(self.data.t.board) do
		for _, tile in pairs(line) do
			local tmp = { "image[",
				tile[1]*sizex+boardx, comma,
				i*sizey+boardy, semi,
				size, comma, size, semi,
				colors[tile[2]], close }

			ins = ins + 1
			scr[ins] = concat(tmp)
		end
	end
	self.data.t.boardstring = concat(scr)
end


function tetris_class:add()
	local t = self.data.t
	local d = shapes[t.cur][t.rot]
	for i=1,4 do
		local l = d.y[i] + t.y
		if not t.board[l] then t.board[l] = {} end
		insert(t.board[l], {d.x[i] + t.x, t.cur})
	end
end

function tetris_class:scroll(l)
	for i=l, 1, -1 do
		self.data.t.board[i] = self.data.t.board[i-1] or {}
	end
end

function tetris_class:check_lines()
	for i, line in pairs(self.data.t.board) do
		if #line >= 10 then
			self:scroll(i)
			self.data.t.score = self.data.t.score + 20
		end
	end
end

function tetris_class:check_position(x, y, rot)
	local d = shapes[self.data.t.cur][rot]
	for i=1,4 do
		local cx, cy = d.x[i]+x, d.y[i]+y
		if cx < 0 or cx > 9 or cy < 0 or cy > 19 then
			return false
		end
		for _, tile in pairs(self.data.t.board[ cy ] or {}) do
			if tile[1] == cx then return false end
		end
	end
	return true
end

function tetris_class:stuck()
	local t = self.data.t
	if self:check_position(t.x, t.y+1, t.rot) then
		return false
	else
		return true
	end
end

function tetris_class:tick()
	local t = self.data.t
	if self:stuck() then
		if t.y <= 0 then
			return false
		end
		self:add()
		self:check_lines()
		self:update_boardstring()
		t.cur, t.nex = t.nex, math.random(7)
		t.x, t.y, t.rot = 4, 0, 1
		t.previewstring = draw_shape(t.nex, 0, 0, 1, 4.1, 0.6)
	else
		t.y = t.y + 1
	end
	return true
end

function tetris_class:move(dx, dy)
	local t = self.data.t
	local newx, newy = t.x+dx, t.y+dy
	if not self:check_position(newx, newy, t.rot) then
		return
	end
	t.x, t.y = newx, newy
end

function tetris_class:rotate(dr)
	local t = self.data.t
	local no = #(shapes[t.cur])
	local newrot = (t.rot+dr) % no

	if newrot<1 then newrot = newrot+no end
	if not self:check_position(t.x, t.y, newrot) then
		return
	end
	t.rot = newrot
end

function tetris_class:key(fields)
	local t = self.data.t
	if fields.left then
		self:move(-1, 0)
	end
	if fields.rotateleft then
		self:rotate(-1)
	end
	if fields.down then
		t.score = t.score + 1
		self:move(0, 1)
	end
	if fields.drop then
	   while not self:stuck() do
			t.score = t.score + 2
			self:move(0, 1)
	   end
	end
	if fields.rotateright then
		self:rotate(1)
	end
	if fields.right then
		self:move(1, 0)
	end
end


laptop.register_app("tetris", {
	app_name = "Tetris",
--	app_icon = "",
	app_info = "Arcade tetris emulator",

	formspec_func = function(app, mtos)
		local data = mtos.bdev:get_app_storage('ram', 'tetris')
		local tetris = get_tetris(app, data)
		local timer = minetest.get_node_timer(mtos.pos)
		if not data.t then
			return mtos.theme:get_button('2,4;2,2', 'major', 'new', 'New Game', 'Start a new game')
		end

		local buttons = mtos.theme:get_button('3,4.5;0.6,0.6', 'minor', 'left', '<')..
						mtos.theme:get_button('3.6,4.5;0.6,0.6', 'minor', 'rotateleft', 'L')..
						mtos.theme:get_button('4.2,4.5;0.6,0.6', 'minor', 'down', 'v')..
						mtos.theme:get_button('4.2,5.3;0.6,0.6', 'minor', 'drop', 'V')..
						mtos.theme:get_button('4.8,4.5;0.6,0.6', 'minor', 'rotateright', 'R')..
						mtos.theme:get_button('5.4,4.5;0.6,0.6', 'minor', 'right', '>')..
						mtos.theme:get_button('3.6,3.5;2,0.6', 'major', 'new', 'New Game', 'Start a new game')

		local t = tetris.data.t
		return 'container[3,2]background[0,0;3,6;'.. mtos.theme.contrast_bg .. ']' ..
			t.boardstring .. t.previewstring ..
			draw_shape(t.cur, t.x, t.y, t.rot, boardx, boardy) ..
			mtos.theme:get_label('3.8,0.1', 'Next...') ..
			mtos.theme:get_label('3.8,2.7', 'Score:...'..t.score) ..
			buttons .. 'container_end[]'
	end,

	receive_fields_func = function(app, mtos, sender, fields)
		local data = mtos.bdev:get_app_storage('ram', 'tetris')
		local tetris = get_tetris(app, data)
		if fields.new then
			tetris:new_game()
		elseif fields.continue then
			app:get_timer():start(0.3)
		else
			tetris:key(fields)
		end
	end,

	on_timer = function(app, mtos)
		local data = mtos.bdev:get_app_storage('ram', 'tetris')
		if not data.t then
			return false
		else
			return get_tetris(app, data):tick()
		end
	end,
})

