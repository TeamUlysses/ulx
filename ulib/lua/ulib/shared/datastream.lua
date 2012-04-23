--[[
Datastream Module
By Janorkie and Deco da Man
An actually working version by Megiddo (as far as I can tell, anyways)
  I pared datastream down to just sending data from the server to the client,
  all relevant hooks are prepended with 'ULib' and I increased effeciency wherever
  I could that wouldn't break compatibility with the original datastream behavior.
  The module name itself is prepended by ulib_, so ulib_datastream.
]]--

require "glon"

function string.split(str,d)
	local t = {}
	local len = str:len()
	local i = 0
	while i*d < len do
		t[i+1] = str:sub(i*d+1,(i+1)*d)
		i=i+1
	end
	return t
end

if SERVER then

umsg.PoolString "ULStart"
umsg.PoolString "ULPacket"
umsg.PoolString "ULEnd"

local table = table
local string = string
local umsg = umsg
local hook = hook
local type = type
local pairs = pairs
local RecipientFilter = RecipientFilter
local pcall = pcall
local error = error
local glon = glon
local iterations = CreateConVar( "gmod_datastream_iterations", "1", { FCVAR_ARCHIVE } )
local ErrorNoHalt = ErrorNoHalt
local IsValid = IsValid

module "ulib_datastream"
local _outgoing = {}

local SteamTick
function StreamToClients( rcp, h, d, cb )
	local o = {}
	-- Recipient information
	local rt = type(rcp)
	if rt == "CRecipientFilter" then
		o.rf = rcp
	elseif rt == "table" then
		o.rf = RecipientFilter()
		for k,v in pairs(rcp) do
			o.rf:AddPlayer(v)
		end
	elseif rt == "Player" then
		o.rf = rcp
	else
		error(("Invalid type %q given to ulib_datastream.StreamToClients for recipients!"):format(type(rcp)))
	end

	-- Data information
	o.decdata = d
	o.encdata = ""
	o.sent = 0
	o.size = 0
	-- Operation state
	o.block = 1
	o.state = 1
	-- Operation handlers
	o.handler = h
	o.callback = cb
	-- Put the operation into the queue and finish up
	o.id = table.insert(_outgoing,o)

	hook.Add("Tick","ULibDatastreamTick",StreamTick)

	return o.id
end

function DownstreamActive() return #_incoming > 0 end

function GetProgress(id)
	if _outgoing[id] then return _outgoing[id].sent end
end

StreamTick = function(rep)
	if not rep and iterations:GetInt() > 0 then
		for i=1,iterations:GetInt() do
			StreamTick(true)
		end
	end
	for id,o in pairs(_outgoing) do
		if type(o.rf) != "CRecipientFilter" and !IsValid(o.rf) then
			-- Player disconnected
			table.remove( _outgoing, id )
			return
		end
		if o.state == 1 then -- Processing stage.
			if o.decdata then
				local enc = ""
				local b,err = pcall(glon.encode, o.decdata)
				if b then enc = err else ErrorNoHalt(("ULibDataStreamServer Encoding Error: %s (operation %s)"):format(err, id)) _outgoing[o.id] = nil return end
				o.encdata = string.split(enc,228)
				o.state = 2
			else
				o.state = 3
			end
			umsg.Start("ULStart",o.rf)
				umsg.Long(o.id)
				umsg.String(o.handler)
				umsg.Bool(type(o.encdata) == "table" and #o.encdata <= 1)
				if type(o.encdata) == "table" and #o.encdata <= 1 then
					umsg.String(o.encdata[1] or "")
					if o.callback then o.callback(o.id) end
					table.remove( _outgoing, id )
				end
			umsg.End()
			return
		elseif o.state == 2 then -- Sending stage.
			umsg.Start("ULPacket",o.rf)
				umsg.Long(o.id)
				umsg.String(o.encdata[o.block])
			umsg.End()
			o.block = o.block+1
			if o.block > #o.encdata then o.state = 3 end
			return
		elseif o.state == 3 then -- Ending stage
			umsg.Start("ULEnd",o.rf)
				umsg.Long(o.id)
			umsg.End()
			if o.callback then o.callback(o.id) end
			table.remove( _outgoing, id )
			return
		end
	end

	-- If we get here it means that there's no data to process
	hook.Remove("Tick","ULibDatastreamTick")
end

elseif CLIENT then
local usermessage = usermessage
local hook = hook
local pcall = pcall
local error = error
local glon = glon
local ErrorNoHalt = ErrorNoHalt

module "ulib_datastream"

local _incoming = {}
local _hooks = {}

function Hook(h,f)
	local hk = {}
	hk.handler = h
	hk.func = f
	_hooks[h] = hk
end

function DownstreamActive() return #_incoming > 0 end

local function CallStreamHook(h,id,encdat,decdat)
	if not _hooks[h] then
		ErrorNoHalt("ULibDataStreamClient: Unhandled stream "..h.."!")
	return end
	hook.Call("ULibCompletedIncomingStream",GAMEMODE,h,id,encdat,decdat)
	_hooks[h].func(h,id,encdat,decdat)
end

-- Usermessages from the server
local function ULStart(data)
	local id = data:ReadLong()
	local handler = data:ReadString()
	local o = {
	id = id,
	handler = handler,
	buffer = "",
	}
	_incoming[id] = o
	if data:ReadBool() then
		local encdat = data:ReadString()
		local decdat = ""
		local b,err = pcall(glon.decode,encdat)
		if b then decdat=err else ErrorNoHalt("ULibDataStreamClient Decoding Error: "..err.." (operation "..id..")\n") return end
		CallStreamHook(_incoming[id].handler,id,encdat,decdat)
		_incoming[id] = nil
	end
end
usermessage.Hook("ULStart",ULStart)

local function ULPacket(data)
	local id = data:ReadLong()
	if not _incoming[id] then return end
	local data = data:ReadString()
	_incoming[id].buffer = _incoming[id].buffer..data
end
usermessage.Hook("ULPacket",ULPacket)

local function ULEnd(data)
	local id = data:ReadLong()
	if not _incoming[id] then return end
	local encdat = _incoming[id].buffer
	local decdat = ""
	local b,err = pcall(glon.decode,encdat)
	if b then decdat=err else ErrorNoHalt("ULibDataStreamClient Decoding Error: "..err.." (operation "..id..")\n") return end
	CallStreamHook(_incoming[id].handler,id,encdat,decdat)
	_incoming[id] = nil
end
usermessage.Hook("ULEnd",ULEnd)

end
