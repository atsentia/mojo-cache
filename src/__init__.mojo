"""
Mojo Cache Library

Pure Mojo caching with LRU eviction and TTL expiration.

LRU Cache:
    from mojo_cache import LRUCache

    var cache = LRUCache[String](max_size=100)
    cache.put("key", "value")
    var value = cache.get("key")

TTL Cache:
    from mojo_cache import TTLCache

    var cache = TTLCache[String](default_ttl_ms=60000)
    cache.put("key", "value")
"""

from .cache import LRUCache, TTLCache, CacheEntry, CacheStats
