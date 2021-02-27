# Tileserver URLs

TileHuria downloads tiles from servers; many of these may be commercial and subject to terms of service which do not permit downloading for every type of endeavor. Please see the [TileHuria Appropriate Use policy](https://github.com/HumanitarianStuff/tilehuria#appropriate-use-dos-and-donts) for more details. The bottom line is: we can't provide you with a bunch of URLs that link directly to commercial tile servers. You'll have to enter your own. 

A good source of tileserver URLs is [JOSM](https://josm.openstreetmap.de/). Install JOSM, go to the Imagery Preferences, and a number of tile URLs appropriate for humanitarian mapping use are visible.

The URL_formats.txt file in the app/tilehuria/tilehuria/ directory) contains two links, both to OpenStreetMap tileservers. **Please do not abuse these; they are a public service provided by the non-profit OpenStreetMap, and should be used sparingly.** The URLs are formatted as in the following examples:

```
myservername https://mytileserver.com/{zoom}/{x}/{y}.png?access_token=mytoken
anotherservername http://{switch:a,b,c,d}.tiles.atmyserver.org/{zoom}/{x}/{y}
```

This is a flat text file with no formatting, headers, or anything. Note that on each line there is a name, a space, then a URL (the name will be used to populate the dropdown for each user's available tileservers). Each URL contains variables contained in {curly braces}; these are replaced for each individual tile with the appropriate values. TileHuria will work with almost any SlippyMap compliant tileserver, it's just a matter of getting the URL right.

If you are doing work with humanitarian mapping and need help with this, get in touch with Ivan Gayton at the Humanitarian OpenStreetMap Team; if your cause is worthy and we're confident that you aren't going to abuse the trust of imagery providers we may be able to assist you.

