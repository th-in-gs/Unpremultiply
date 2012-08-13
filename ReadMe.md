Unpremultiply
-------------

A simple OS X service that will read PNGs containing premultiplied alpha and
resave them as regular PNGs with regular alpha. Doesn't try to do anything very
smart, just uses CoreGrahics to read a PNG, interprets it as having
premultiplied alpha, then re-saves it as a regular PNG.

To use, just ctrl-click on a file in Finder and choose
"Services" -> "Unpremultiply".