# Questions for senior dev

## Threaded downloading

At the moment we use a set number of threads downloading tiles (50 for the first try, 25 for the second). This seems to work most of the time, but on slow connections there are often residual timeouts. I imagine that there's a way to adjust the number of threads and timeout delays to optimize for grabbing all tiles depending on the Internet connection and the capacity of the tileserver. Perhaps moving away from the threaded batching and using something like asyncio?

## Imports
Fuuuck


