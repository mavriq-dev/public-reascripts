-- @metapackage
-- @description Mavriq Lua Sockets
-- @version 1.0.0pre1
-- @author Mavirq
-- @about
--   # Allows use of Lua Sockets in 'REAPER'
--   Reaper is missing Lua Auxlib in it's embedded version of Lua. As such things such as the luasockets library etc will not work. If loaded they will throw an error for missing symbols when the library tries to access those in the missing AuxLib.
--   
--   Until the REAPER devs fix this, we have to work around the issue. This project does that for all all three REAPER platforms.
--   
--   This package is used by other scripts and doesn't do anything on its own.
-- @donation: https://www.paypal.com/paypalme/mavriqdev
-- @links
--   Forum Thread https://github.com/available_soon
--   GitHub repository https://github.com/mavriq-dev/mavriq-lua-sockets
-- @changelog
--   initial version
-- @provides
--   /Various/Mavriq-Lua-Sockets/*.lua
--   [win64] /Various/Mavriq-Lua-Sockets/Socket/core.dll
--   [darwin64] /Various/Mavriq-Lua-Sockets/Socket/core.so
--   [linux64] /Various/Mavriq-Lua-Sockets/Socket/core.so.linux > /Various/Mavriq-Lua-Sockets/Socket/core.so
