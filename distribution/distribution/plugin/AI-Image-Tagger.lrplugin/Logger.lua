--[[----------------------------------------------------------------------------

 RoboTagger
 Copyright 2025 Anand's Photography

--------------------------------------------------------------------------------

Logger.lua

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces.
local LrLogger = import "LrLogger"

-- Create the logger and enable the print function.
logger = LrLogger( "lr.tagimg.net" )
logger:enable( "logfile" )
