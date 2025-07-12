--[[----------------------------------------------------------------------------

 RoboTagger
 Copyright 2024 Anand Kumar Sankaran

--------------------------------------------------------------------------------

Logger.lua

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces.
local LrLogger = import "LrLogger"

-- Create the logger and enable the print function.
logger = LrLogger( "com.tjotala.lightroom.robotagger" )
logger:enable( "logfile" )
