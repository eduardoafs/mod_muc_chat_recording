-- Module for chat recording on Jitsi Meet rooms
module:log('info', 'Loaded chat history plugin');

-- History store, to shared values
local historystore = module:open_store('chat-history', 'map');
-- Folder in which history will be stored
local chatHistoryDir = module:get_option('chatHistoryDir', '/var/log/prosody/chat/');
chatHistoryDir = chatHistoryDir .. (chatHistoryDir:sub(-1)=='/'? : '' : '/') -- ensure that chatHistoryDir ends with a /

-- Time format used to generate file names and infos
local timeFormat = "%Y-%m-%d %H-%M-%S"; 

-- Print history to file
-- Warning: only works on linux, since I'm using os.execute mkdir and echo
-- PS.: io.open and write was not working, so that was my solution for now
local function printHistory(msg, jid) 
	local fileName, filePath = getFileName(jid);

	local command = 'echo \''..msg..'\' >> '.. '\''.. fileName .. '\'';
	-- just to be sure, try to create dirs in the path
	os.execute("mkdir -p "..filePath);
	local ok, err = os.execute(command);
	if ok then
		return;
	else
		module:log('error', 'Error executing command: '..command);
	end
end

local function getFileName(jid) 
	local filePath = historystore:get(jid, 'filePath') or 'undef';
	local fileName = filePath .. '/' .. historystore:get(jid, 'createdAt') .. '.log';
	return fileName, filePath;
end

-- Extracts the message from a stanza
local function extractMessage(stanza)
	local userName =  tostring(stanza[2][1]);
	local userId = stanza.attr.from;
	local message = tostring(stanza[1][1]);
	local timestamp = os.time();
	local room = stanza.attr.to

	return (userId..'- ['..timestamp..']'..' '..userName..': '..message);
end

-- Hook to room created, which will create the chat history file
module:hook("muc-room-created", function(event)
	local room = event.room;
	module:log('info', 'Captured room creation, id: '..room.jid);
	-- create file to store the chat
	local time = os.date(timeFormat);
	local filePath = chatHistoryDir .. room.jid;

	historystore:set(room.jid, 'createdAt', time);
	historystore:set(room.jid, 'filePath', filePath);
	
	printHistory('Created at '..time, room.jid);
end);

-- Finish the chat history file
module:hook("muc-room-destroyed", function(event)
	module:log('info', 'Captured room destruction, id: '..event.room.jid);

	local fileName, filePath = getFileName(jid);
	local time = os.date(timeFormat);

	printHistory("Ended at "..time.." >> "..fileName, event.room.jid);
	-- some post-processing
end);

-- hook messages and store it to the chat history
module:hook("message/bare", function(event)
	local stanza = event.stanza;
	if (stanza.name == "message" and tostring(stanza.attr.type) == "groupchat") then 
		--local file = historystore:get(stanza.attr.to, 'file');
		--file:write(extractMessage(stanza)..'\n');
		printHistory(extractMessage(stanza), stanza.attr.to);
	end
end);