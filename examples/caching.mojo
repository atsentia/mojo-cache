"""
Example: In-Memory Caching (LRU + TTL)

Demonstrates:
- LRU cache with max size limit
- TTL cache with time-based expiration
- Cache statistics
"""

from mojo_cache import LRUCache, TTLCache, CacheStats


fn lru_cache_example():
    """LRU (Least Recently Used) cache example."""
    print("=== LRU Cache Example ===")

    # Create cache with max 3 items
    var cache = LRUCache[String](max_size=3)

    # Add items
    cache.put("user:1", "Alice")
    cache.put("user:2", "Bob")
    cache.put("user:3", "Charlie")
    print("Added 3 users to cache")

    # Access user:1 (marks it as recently used)
    var user1 = cache.get("user:1")
    if user1:
        print("Retrieved: user:1 = " + user1.value())

    # Add a 4th item - this evicts the LRU item (user:2)
    cache.put("user:4", "Diana")
    print("Added user:4 (cache full, evicted LRU)")

    # Check eviction
    var user2 = cache.get("user:2")
    if not user2:
        print("user:2 was evicted (LRU)")

    # Get stats
    var stats = cache.stats()
    print("Cache stats: hits=" + String(stats.hits) + ", misses=" + String(stats.misses))
    print("")


fn ttl_cache_example():
    """TTL (Time To Live) cache example."""
    print("=== TTL Cache Example ===")

    # Create cache with 5 second TTL
    var cache = TTLCache[String](default_ttl_ms=5000)

    # Add items
    cache.put("session:abc", "user_data")
    cache.put("session:xyz", "other_data")
    print("Added 2 sessions with 5s TTL")

    # Retrieve immediately (should work)
    var session = cache.get("session:abc")
    if session:
        print("Retrieved session: " + session.value())

    # Custom TTL for specific items
    cache.put_with_ttl("temp_token", "secret123", 1000)  # 1 second
    print("Added temp_token with 1s TTL")

    print("\nNote: After TTL expires, cache.get() returns None")
    print("")


fn cache_patterns_example():
    """Common caching patterns."""
    print("=== Cache Patterns ===")

    var cache = LRUCache[String](max_size=100)

    # Pattern 1: Cache-aside (read-through)
    fn get_user_cached(cache: LRUCache[String], user_id: String) -> String:
        var cached = cache.get(user_id)
        if cached:
            return cached.value()  # Cache hit
        # Cache miss - fetch from database
        var user = "User_" + user_id  # Simulated DB fetch
        cache.put(user_id, user)
        return user

    var user = get_user_cached(cache, "42")
    print("First call (miss): " + user)
    user = get_user_cached(cache, "42")
    print("Second call (hit): " + user)

    # Pattern 2: Write-through
    fn save_user(cache: LRUCache[String], user_id: String, data: String):
        # Save to database first
        print("Saved to DB: " + user_id)
        # Then update cache
        cache.put(user_id, data)

    save_user(cache, "100", "New User Data")
    print("")


fn main():
    print("mojo-cache: Pure Mojo In-Memory Caching\n")

    lru_cache_example()
    ttl_cache_example()
    cache_patterns_example()

    print("=" * 50)
    print("Cache types:")
    print("  LRUCache - Size-limited, evicts least recently used")
    print("  TTLCache - Time-limited, expires after TTL")
