--[[----------------------------------------------------------------------------

 RoboTagger
 Copyright 2025 Anand's Photography

--------------------------------------------------------------------------------

Logger.lua

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces.
local LrLogger = import "LrLogger"

-- Create the logger and enable the print function.
local logger = LrLogger( "lr.tagimg.net" )
logger:enable( "logfile" )

-- Export logger to global namespace in a controlled way
-- This prevents accidental global pollution while maintaining accessibility
_G.logger = logger
