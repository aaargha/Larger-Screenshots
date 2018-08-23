require "util"

--[[
	Worker function for large screenshot feature. See bottom of file for interface.
--]]
local function _large_screenshot(_player, _by_player, _surface, _position, _size, _zoom, _path_prefix, _show_gui, _show_entity_info, _anti_alias)
	
	local pix_per_tile = 32 * _zoom

	local max_dist = settings.get_player_settings(_player)["LargerScreenshots_max_res"].value / pix_per_tile --512 is hard upper limit
	if _anti_alias then
		max_dist = settings.get_player_settings(_player)["LargerScreenshots_max_res_aa"].value / pix_per_tile --256 is hard upper limit
	end
	
	local width = _size.x or _size[1]
	local height = _size.y or _size[2]

	--ensure minimum size
	if width * pix_per_tile < 1 or height * pix_per_tile < 1 then
		return
	end

	--too large to fit in one picture
	if width > max_dist or height > max_dist then
		local r_lim = _position.x + width / 2
		local b_lim = _position.y + height / 2
		local top = _position.y - height / 2
		local ii = 1
		local jj = 1

		--cut area into rows
		while top < b_lim do
			jj = 1
			local left = _position.x - width / 2
			local bottom = math.min(top + max_dist, b_lim)

			--cut rows into pictures
			while left < r_lim do
				local right = math.min(left + max_dist, r_lim)
				local pos = {x = (left + right) / 2, y = (top + bottom) / 2}
				local w = (right - left) * pix_per_tile --x res
				local h = (bottom - top) * pix_per_tile --y res

				--ensure minimum size
				if w >= 1 and h >= 1 then
					game.take_screenshot{
						player = _player, 
						by_player = _by_player, 
						surface = _surface,
						position = pos, 
						resolution = {x = w, y = h}, 
						zoom = _zoom, 
						path = _path_prefix .. "_" .. ii .. "_" .. jj ..".png", 
						show_gui = _show_gui, 
						show_entity_info = _show_entity_info,
						anti_alias = _anti_alias
					}
				end

				jj = jj + 1
				left = left + max_dist
			end

			ii = ii + 1
			top = top + max_dist
		end

	--fits in one screenshot
	else
		game.take_screenshot{
			player = _player, 
			by_player = _by_player, 
			surface = _surface, 
			position = _position, 
			resolution = {x = width * pix_per_tile, y = height * pix_per_tile}, 
			zoom = _zoom, 
			path = _path_prefix .. ".png", 
			show_gui = _show_gui, 
			show_entity_info = _show_entity_info,
			anti_alias = _anti_alias
		}
	end
end

--[[
	Wrapper to handle arguments
--]]
local function large_screenshot(args)
	--make sure that player is a LuaPlayer
	local _player = game.player or args.player or game.players[1]
	if type(_player) ~= "table" then
		_player = game.players[_player]
	end

	--make sure that position is of format {x=,y=}
	local _position = args.position or _player.position
	if not _position.x then
		_position = {x = _position[1], y = _position[2]}
	end

	for a,v in pairs(args) do
		--_player.print(a .. " " .. v)
	end

	--if no custom size just take a regular screenshot
	if not args.size then
		--add file ending if needed
		local _path = args.path_prefix
		if _path then
			_path = _path .. ".png"
		end

		game.take_screenshot{
			player = args.player or _player, 
			by_player = args.by_player or _player,
			surface = args.surface,  
			position = _position, 
			zoom = args.zoom, 
			path = _path, 
			show_gui = args.show_gui, 
			show_entity_info = args.show_entity_info,
			anti_alias = args.anti_alias
		}

		_player.print("Screenshot taken")
		return
	end

	_player.print("Processing...")

	--call worker with usable arguments
	_large_screenshot(
		args.player or _player, --player
		args.by_player or _player, --by_player
		args.surface, --surface
		_position, --position
		args.size, --size
		args.zoom or 1, --zoom
		args.path_prefix or "screenshot", --path_prefix
		args.show_gui or false, --show_gui
		args.show_entity_info or false, --show_entity_info
		args.anti_alias or false --aa
	)

	_player.print("Screenshot taken")
end

--[[
	WARNING: The resulting screenshots may be very large: a 1024x1024 (explored) tiles shot at zoom 1 is about 1.6GB
	WARNING: Taking large screenshots may take a long time: a 1024x1024 tiles shot at zoom 1 froze the game for about 30 sec, and it took another 30 or so before all the pictures were finished being written to disk. Larger shots may take minutes
	Warning: Taking large screenshots will cause RAM usage to spike heavily: a 1024x1024 tiles shot at zoom 1 peaked at about 5GB of additional ram usage while processing

	To call from a mod:
	remote.call("LargerScreenshots","screenshot", {player=…, by_player=…, surface=…, position=…, size=…, zoom=…, path_prefix=…, show_gui=…, show_entity_info=…, anti_alias=…})
	To call from console as a player:
	/c remote.call("LargerScreenshots","screenshot", {player=…, by_player=…, surface=…, position=…, size=…, zoom=…, path_prefix=…, show_gui=…, show_entity_info=…, anti_alias=…})

	If called from the console only the person typing will get the screenshot, this is to prevent filling other players haddrives.

	Take a screenshot and save it to file, multiple files will be created if needed. Size limit of each piece is 8192 (4096 with aa) to reduce memory usage (it's still a few GB extra while working)(can be changed in mod options)

	Parameters
	Table with the following fields:

		player :: string or LuaPlayer or uint (optional) : Center of screenshot (unless position is supplied) and who to print info to. Defaults to the one using the console or, if called by a mod, player 1 
		by_player :: string or LuaPlayer or uint (optional): If defined, the screenshot will only be taken for this player.
		surface :: SurfaceSpecification (optional): IF defined, the screenshot will be take on this surface unless player is also given.
		position :: Position (optional): Coordinates to center of screenshot, defaults to player position
		size :: Position (optional): size of screenshot in __TILES__, defaults to visible area at selected zoom
		zoom :: double (optional): Default 1
		path_prefix :: string (optional): Path to save the screenshot in, should not include file type. Suffix will be added as necessary ex: if 4 pictures are required for a square shot they will get the endings: _1_1.png, _1_2.png, _2_1.png and _2_2.png
		show_gui :: boolean (optional): Include game GUI in the screenshot? false
		show_entity_info :: boolean (optional): Include entity info (alt-mode)? false
		anti_alias :: boolean (optional): Render in double resolution and scale down (including GUI)? false
--]]
remote.add_interface("LargerScreenshots", {screenshot = large_screenshot})
