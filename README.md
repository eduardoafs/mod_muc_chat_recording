Chat Recording Module to be used with Jitsi Meet.
- Saves all chats, in all rooms, to filesystem.

[Installation]
- 1. cp mod_muc_chat_recording.lua /usr/share/jitsi-meet/prosody-plugins
- 2. Edit /etc/prosody/conf.d/[something].cfg.lua
- 2.1 Add in conference muc component:
    modules_enable { ... "muc_chat_recording"; }
- 2.2 It is possible to specify the path to save the chats, defining chatHistoryDir=path/to/folder in the component
- 3. sudo service prosody restart
