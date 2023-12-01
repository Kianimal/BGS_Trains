# BGS_Trains
An ambient train script for RedM servers.

This script is a resurrection of tr_trains, rebuilt in lua.
Credits go to the author of ts_trains, as well as @Wartype and @t3chman for their help/info on track junctions and hashes.
Credit also goes to @Hobbs for the Christmas train help and the random junctions feature!

This script will add ambient trains to your server.

Each train can be configured to be used, or turned off.
There is a train for the west, a train for the east, and a tram in Saint Denis.

All of them will stop at the native stops in the game. I will likely not add the ability for custom stops for this free release, but feel free to alter the open source code!

The tram goes with the direction of traffic in Saint Denis at all times, so as long as wagons are not stuck in its path they should sense and avoid it natively.
Same goes for the trains, though these have been tested less than the trams have, particularly the western line.

There are blips for the trains that can be renamed in the config.

Junctions are configurable but I recommend not messing with them unless you know what you're doing.
