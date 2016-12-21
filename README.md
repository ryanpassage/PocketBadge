# PocketBadge
Another try at unlocking doors with Bluetooth and magic.

This is 2016's attempt at using Bluetooth beacons to unlock doors for me (I am convinced this is a good idea).

This app is a lot simpler than Open Sesame, although I was able to play with some iOS techniques I hadn't used before (such as Notifications instead of KVO, and the actual Estimote Beacon SDK instead of CoreLocation).  It does rely on a private Flask API I wrote to communicate with the door lock system's developer API, but that probably won't be open sourced.

This app worked better than Open Sesame but still wasn't as reliable as I wanted it to be.  Beacon ranging/changes just weren't snappy enough.
