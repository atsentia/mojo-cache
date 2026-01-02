"""
Cache Tests
"""

from mojo_cache import LRUCache, TTLCache


fn test_lru_basic() raises:
    """Test basic LRU cache operations."""
    var cache = LRUCache[String](max_size=3)

    cache.put("a", "1")
    cache.put("b", "2")
    cache.put("c", "3")

    var a = cache.get("a")
    if not a:
        raise Error("LRU: key 'a' should exist")
    if a.value() != "1":
        raise Error("LRU: wrong value for 'a'")

    print("✓ LRU basic operations work")


fn test_lru_eviction() raises:
    """Test LRU eviction."""
    var cache = LRUCache[String](max_size=3)

    cache.put("a", "1")
    cache.put("b", "2")
    cache.put("c", "3")

    # Access 'a' to make it recently used
    _ = cache.get("a")

    # Add 'd' - should evict 'b' (least recently used)
    cache.put("d", "4")

    if cache.contains("b"):
        raise Error("LRU: 'b' should have been evicted")

    if not cache.contains("a"):
        raise Error("LRU: 'a' should still exist")

    if not cache.contains("c"):
        raise Error("LRU: 'c' should still exist")

    if not cache.contains("d"):
        raise Error("LRU: 'd' should exist")

    print("✓ LRU eviction works")


fn test_lru_update() raises:
    """Test updating existing key."""
    var cache = LRUCache[String](max_size=3)

    cache.put("a", "1")
    cache.put("a", "updated")

    var a = cache.get("a")
    if not a or a.value() != "updated":
        raise Error("LRU: update should work")

    if cache.size() != 1:
        raise Error("LRU: size should be 1 after update")

    print("✓ LRU update works")


fn test_lru_remove() raises:
    """Test removing key."""
    var cache = LRUCache[String](max_size=3)

    cache.put("a", "1")
    cache.put("b", "2")

    if not cache.remove("a"):
        raise Error("LRU: remove should return True for existing key")

    if cache.remove("a"):
        raise Error("LRU: remove should return False for non-existing key")

    if cache.contains("a"):
        raise Error("LRU: 'a' should be removed")

    print("✓ LRU remove works")


fn test_lru_clear() raises:
    """Test clearing cache."""
    var cache = LRUCache[String](max_size=3)

    cache.put("a", "1")
    cache.put("b", "2")

    cache.clear()

    if cache.size() != 0:
        raise Error("LRU: size should be 0 after clear")

    print("✓ LRU clear works")


fn test_lru_hit_rate() raises:
    """Test hit rate calculation."""
    var cache = LRUCache[String](max_size=3)

    cache.put("a", "1")

    _ = cache.get("a")  # hit
    _ = cache.get("a")  # hit
    _ = cache.get("b")  # miss

    var rate = cache.hit_rate()
    # 2 hits, 1 miss = 2/3 = 0.666...
    if rate < 0.6 or rate > 0.7:
        raise Error("LRU: hit rate should be ~0.67, got " + str(rate))

    print("✓ LRU hit rate works")


fn test_ttl_basic() raises:
    """Test basic TTL cache operations."""
    var cache = TTLCache[String](default_ttl_ms=1000)
    cache.set_time(0)

    cache.put("a", "1")
    cache.put("b", "2")

    var a = cache.get("a")
    if not a or a.value() != "1":
        raise Error("TTL: key 'a' should exist with value '1'")

    print("✓ TTL basic operations work")


fn test_ttl_expiration() raises:
    """Test TTL expiration."""
    var cache = TTLCache[String](default_ttl_ms=1000)
    cache.set_time(0)

    cache.put("a", "1")

    # Time advances past TTL
    cache.advance_time(1500)

    var a = cache.get("a")
    if a:
        raise Error("TTL: 'a' should be expired")

    print("✓ TTL expiration works")


fn test_ttl_custom_ttl() raises:
    """Test custom TTL per entry."""
    var cache = TTLCache[String](default_ttl_ms=1000)
    cache.set_time(0)

    cache.put("short", "1", 500)
    cache.put("long", "2", 2000)

    cache.advance_time(750)

    var short = cache.get("short")
    if short:
        raise Error("TTL: 'short' should be expired at 750ms")

    var long = cache.get("long")
    if not long:
        raise Error("TTL: 'long' should still exist at 750ms")

    print("✓ TTL custom TTL works")


fn test_ttl_cleanup() raises:
    """Test cleanup of expired entries."""
    var cache = TTLCache[String](default_ttl_ms=1000, max_size=10)
    cache.set_time(0)

    for i in range(5):
        cache.put("key" + str(i), "value" + str(i))

    if cache.size() != 5:
        raise Error("TTL: should have 5 entries")

    cache.advance_time(1500)
    cache.cleanup()

    if cache.size() != 0:
        raise Error("TTL: all entries should be expired after cleanup")

    print("✓ TTL cleanup works")


fn test_ttl_capacity() raises:
    """Test TTL cache capacity handling."""
    var cache = TTLCache[String](default_ttl_ms=10000, max_size=3)
    cache.set_time(0)

    cache.put("a", "1")
    cache.put("b", "2")
    cache.put("c", "3")
    cache.put("d", "4")  # Should evict oldest

    if cache.size() != 3:
        raise Error("TTL: size should be capped at 3")

    print("✓ TTL capacity handling works")


fn main() raises:
    print("Running Cache tests...\n")

    test_lru_basic()
    test_lru_eviction()
    test_lru_update()
    test_lru_remove()
    test_lru_clear()
    test_lru_hit_rate()
    test_ttl_basic()
    test_ttl_expiration()
    test_ttl_custom_ttl()
    test_ttl_cleanup()
    test_ttl_capacity()

    print("\n✅ All Cache tests passed!")
