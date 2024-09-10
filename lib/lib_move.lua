-- lib_move.lua (/lib/lib_move.lua)

-- This lib overrides turtle move functions in _G (global namespace)
-- Orig functions will be availible at turtle._<function>

-- If Modem / GPS availble position will be set on init
-- If Modem / GPS not availible position will be set as 0,0,0 on init
-- If Modem / blockd is availible facing will be set on init
-- If Modem / blockd are not availible facing will be set as North
-- adding variables
--  - turtle.relPosition (bool)
--  - turtle.position (list (x,y,z))
--  - turtle.relFacing (bool) 
--  - turtle.facing ()
-- If turtle.relFacing and gpsIsAvailible turtle.facing & turtle.relFacing will be updated on first move
-- path / file /data/.position will be created if not exists (content: x = <value>, y = <value>, z = <value>, rP = <value>)
-- path / file /data/.facing will be created if not exists (content: f = <value>, rF = <value>)
-- .position / .facing will be updated on move
-- if files exist on init then their content will be copied to /data/.travel.log and then updated with new values

-- Functions:
--  - gpsIsAvailible (get/set)
--  - blockdIsAvailbile (get/set)
--  - destructiveMove (get/set) default true
--  - whitelist (get/set) default: tbd
--  - blacklist (get/set) default: tbd

-- Requires /lib/lib_path.lua if availible
