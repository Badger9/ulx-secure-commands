function ulx.vanish( calling_ply, should_unvanish )
    if !IsValid( calling_ply ) then return end

	for _, ply in ipairs( player.GetAll() ) do
        if ply:IsAdmin() or ply == calling_ply then continue end
        calling_ply:SetPreventTransmit( ply, !should_unvanish )
    end

	for _, ent in ipairs( calling_ply:GetChildren() ) do
		for _, ply in ipairs( player.GetAll() ) do
			if ply:IsAdmin() or ply == calling_ply then continue end
			ent:SetPreventTransmit( ply, !should_unvanish )
		end
	end
	
	if !should_unvanish then
		ulx.fancyLogAdmin( calling_ply, "#A vanished #T", calling_ply )
	else
		ulx.fancyLogAdmin( calling_ply, "#A unvanished #T", calling_ply )
	end
end

local vanish = ulx.command( "Utility", "ulx vanish", ulx.vanish, "!vanish" )
vanish:addParam{ type=ULib.cmds.BoolArg, invisible=true }
vanish:defaultAccess( ULib.ACCESS_ADMIN )
vanish:help( "Vanish yourself, similar to cloak, however, it hides you from cheaters." )
vanish:setOpposite( "ulx unvanish", {_, true}, "!unvanish" )

function ulx.sspectate( calling_ply, target_ply ) -- basically just copied ulx's default spectate and added vanish to it
    if not calling_ply:IsValid() then
		Msg( "You can't spectate from dedicated server console.\n" )
		return
	end

	-- Check if player is already spectating. If so, stop spectating so we can start again
	local hookTable = hook.GetTable()["KeyPress"]
	if hookTable and hookTable["ulx_unspectate_" .. calling_ply:EntIndex()] then
		-- Simulate keypress to properly exit spectate.
		hook.Call( "KeyPress", _, calling_ply, IN_FORWARD )
	end

	if ulx.getExclusive( calling_ply, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( calling_ply, calling_ply ), true )
		return
	end

	ULib.getSpawnInfo( calling_ply )

	local pos = calling_ply:GetPos()
	local ang = calling_ply:GetAngles()
	
	local wasAlive = calling_ply:Alive()

	local function stopSpectate( player )
		if player ~= calling_ply then -- For the spawning, make sure it's them doing the spawning
			return
		end

		hook.Remove( "PlayerSpawn", "ulx_unspectatedspawn_" .. calling_ply:EntIndex() )
		hook.Remove( "KeyPress", "ulx_unspectate_" .. calling_ply:EntIndex() )
		hook.Remove( "PlayerDisconnected", "ulx_unspectatedisconnect_" .. calling_ply:EntIndex() )

		if player.ULXHasGod then player:GodEnable() end -- Restore if player had ulx god.
		player:UnSpectate() -- Need this for DarkRP for some reason, works fine without it in sbox
		ulx.fancyLogAdmin( calling_ply, true, "#A stopped spectating #T", target_ply )
		ulx.clearExclusive( calling_ply )
	end
	hook.Add( "PlayerSpawn", "ulx_unspectatedspawn_" .. calling_ply:EntIndex(), stopSpectate, HOOK_MONITOR_HIGH )

	local function unspectate( player, key )
		if calling_ply ~= player then return end -- Not the person we want
		if key ~= IN_FORWARD and key ~= IN_BACK and key ~= IN_MOVELEFT and key ~= IN_MOVERIGHT then return end -- Not a key we're interested in

		hook.Remove( "PlayerSpawn", "ulx_unspectatedspawn_" .. calling_ply:EntIndex() ) -- Otherwise spawn would cause infinite loop
		if wasAlive then -- We don't want to spawn them if they were already dead.
		    ULib.spawn( player, true ) -- Get out of spectate.
		end
		stopSpectate( player )
        ulx.vanish( calling_ply, true )
		player:SetPos( pos )
		player:SetAngles( ang )
	end
	hook.Add( "KeyPress", "ulx_unspectate_" .. calling_ply:EntIndex(), unspectate, HOOK_MONITOR_LOW )

	local function disconnect( player ) -- We want to watch for spectator or target disconnect
		if player == target_ply or player == calling_ply then -- Target or spectator disconnecting
			unspectate( calling_ply, IN_FORWARD )
		end
	end
	hook.Add( "PlayerDisconnected", "ulx_unspectatedisconnect_" .. calling_ply:EntIndex(), disconnect, HOOK_MONITOR_HIGH )

    ulx.vanish( calling_ply )

	calling_ply:Spectate( OBS_MODE_IN_EYE )
	calling_ply:SpectateEntity( target_ply )
	calling_ply:StripWeapons() -- Otherwise they can use weapons while spectating

	ULib.tsay( calling_ply, "To get out of spectate, move forward.", true )
	ulx.setExclusive( calling_ply, "spectating" )

	ulx.fancyLogAdmin( calling_ply, true, "#A began securely spectating #T", target_ply )
end

local sspectate = ulx.command( CATEGORY_NAME, "ulx sspectate", ulx.sspectate, "!sspectate", true )
sspectate:addParam{ type=ULib.cmds.PlayerArg, target="!^" }
sspectate:defaultAccess( ULib.ACCESS_ADMIN )
sspectate:help( "Securely spectate a target, invisible to cheaters." )

function ulx.snoclip( calling_ply )
    ulx.vanish( calling_ply, calling_ply:GetMoveType() == MOVETYPE_NOCLIP )
	ulx.noclip( calling_ply, { calling_ply } )
end

local snoclip = ulx.command( "Utility", "ulx snoclip", ulx.snoclip, "!snoclip" )
snoclip:defaultAccess( ULib.ACCESS_ADMIN )
snoclip:help( "Securely noclip, invisible to cheaters." )