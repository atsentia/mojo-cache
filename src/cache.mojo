"""
Cache Implementation

Pure Mojo caching with LRU eviction and TTL expiration.
"""


# =============================================================================
# Cache Entry
# =============================================================================

struct CacheEntry[V: CollectionElement]:
    """
    A cache entry with value and metadata.
    """
    var value: V
    var created_at: Int64
    var last_accessed: Int64
    var ttl_ms: Int64  # 0 = no TTL
    var access_count: Int

    fn __init__(out self, value: V, ttl_ms: Int64 = 0):
        """Create cache entry."""
        self.value = value
        self.created_at = 0  # Would use time API when available
        self.last_accessed = 0
        self.ttl_ms = ttl_ms
        self.access_count = 0

    fn is_expired(self, current_time: Int64) -> Bool:
        """Check if entry is expired."""
        if self.ttl_ms == 0:
            return False
        return (current_time - self.created_at) > self.ttl_ms


# =============================================================================
# LRU Cache
# =============================================================================

struct LRUCache[V: CollectionElement]:
    """
    Least Recently Used (LRU) cache.

    Evicts least recently accessed items when capacity is reached.

    Example:
        var cache = LRUCache[String](max_size=100)
        cache.put("key1", "value1")
        var value = cache.get("key1")  # Returns Optional[String]
    """
    var keys: List[String]
    var values: List[V]
    var access_order: List[Int]  # Tracks access order for LRU
    var max_size: Int
    var hits: Int
    var misses: Int

    fn __init__(out self, max_size: Int = 128):
        """Create LRU cache with max size."""
        self.keys = List[String]()
        self.values = List[V]()
        self.access_order = List[Int]()
        self.max_size = max_size
        self.hits = 0
        self.misses = 0

    fn put(inout self, key: String, value: V):
        """Put value in cache."""
        # Check if key exists
        var idx = self._find_key(key)
        if idx >= 0:
            # Update existing
            self.values[idx] = value
            self._update_access(idx)
            return

        # Evict if at capacity
        if len(self.keys) >= self.max_size:
            self._evict_lru()

        # Add new entry
        self.keys.append(key)
        self.values.append(value)
        self.access_order.append(len(self.keys) - 1)

    fn get(inout self, key: String) -> Optional[V]:
        """Get value from cache."""
        var idx = self._find_key(key)
        if idx < 0:
            self.misses += 1
            return None

        self.hits += 1
        self._update_access(idx)
        return self.values[idx]

    fn contains(self, key: String) -> Bool:
        """Check if key exists in cache."""
        return self._find_key(key) >= 0

    fn remove(inout self, key: String) -> Bool:
        """Remove key from cache. Returns True if key existed."""
        var idx = self._find_key(key)
        if idx < 0:
            return False

        self._remove_at(idx)
        return True

    fn clear(inout self):
        """Clear all entries."""
        self.keys = List[String]()
        self.values = List[V]()
        self.access_order = List[Int]()

    fn size(self) -> Int:
        """Get current size."""
        return len(self.keys)

    fn hit_rate(self) -> Float64:
        """Get cache hit rate (0.0 to 1.0)."""
        var total = self.hits + self.misses
        if total == 0:
            return 0.0
        return Float64(self.hits) / Float64(total)

    fn _find_key(self, key: String) -> Int:
        """Find index of key, or -1 if not found."""
        for i in range(len(self.keys)):
            if self.keys[i] == key:
                return i
        return -1

    fn _update_access(inout self, idx: Int):
        """Update access order for LRU."""
        # Move to end of access order
        var new_order = List[Int]()
        for i in range(len(self.access_order)):
            if self.access_order[i] != idx:
                new_order.append(self.access_order[i])
        new_order.append(idx)
        self.access_order = new_order

    fn _evict_lru(inout self):
        """Evict least recently used entry."""
        if len(self.access_order) == 0:
            return

        var lru_idx = self.access_order[0]
        self._remove_at(lru_idx)

    fn _remove_at(inout self, idx: Int):
        """Remove entry at index."""
        # Remove from keys and values
        var new_keys = List[String]()
        var new_values = List[V]()
        for i in range(len(self.keys)):
            if i != idx:
                new_keys.append(self.keys[i])
                new_values.append(self.values[i])
        self.keys = new_keys
        self.values = new_values

        # Update access order (remove and adjust indices)
        var new_order = List[Int]()
        for i in range(len(self.access_order)):
            var order_idx = self.access_order[i]
            if order_idx != idx:
                if order_idx > idx:
                    new_order.append(order_idx - 1)
                else:
                    new_order.append(order_idx)
        self.access_order = new_order


# =============================================================================
# TTL Cache
# =============================================================================

struct TTLCache[V: CollectionElement]:
    """
    Time-To-Live (TTL) cache.

    Entries expire after a configurable duration.

    Example:
        var cache = TTLCache[String](default_ttl_ms=60000)  # 60 seconds
        cache.put("key1", "value1")
        var value = cache.get("key1")  # Returns None after TTL expires
    """
    var keys: List[String]
    var values: List[V]
    var expiry_times: List[Int64]  # Timestamp when entry expires
    var default_ttl_ms: Int64
    var max_size: Int
    var current_time: Int64  # Simulated time (increment manually or use real time)

    fn __init__(out self, default_ttl_ms: Int64 = 300000, max_size: Int = 1024):
        """Create TTL cache with default TTL in milliseconds."""
        self.keys = List[String]()
        self.values = List[V]()
        self.expiry_times = List[Int64]()
        self.default_ttl_ms = default_ttl_ms
        self.max_size = max_size
        self.current_time = 0

    fn set_time(inout self, time_ms: Int64):
        """Set current time (for testing or when no system time available)."""
        self.current_time = time_ms

    fn advance_time(inout self, delta_ms: Int64):
        """Advance current time by delta."""
        self.current_time += delta_ms

    fn put(inout self, key: String, value: V, ttl_ms: Int64 = -1):
        """Put value with optional custom TTL (-1 = use default)."""
        var actual_ttl = ttl_ms if ttl_ms >= 0 else self.default_ttl_ms
        var expiry = self.current_time + actual_ttl

        # Check if key exists
        var idx = self._find_key(key)
        if idx >= 0:
            self.values[idx] = value
            self.expiry_times[idx] = expiry
            return

        # Cleanup expired entries if at capacity
        if len(self.keys) >= self.max_size:
            self._cleanup_expired()

        # Still at capacity? Remove oldest
        if len(self.keys) >= self.max_size:
            self._remove_oldest()

        self.keys.append(key)
        self.values.append(value)
        self.expiry_times.append(expiry)

    fn get(inout self, key: String) -> Optional[V]:
        """Get value if not expired."""
        var idx = self._find_key(key)
        if idx < 0:
            return None

        # Check expiry
        if self.expiry_times[idx] <= self.current_time:
            self._remove_at(idx)
            return None

        return self.values[idx]

    fn contains(self, key: String) -> Bool:
        """Check if key exists and is not expired."""
        var idx = self._find_key(key)
        if idx < 0:
            return False
        return self.expiry_times[idx] > self.current_time

    fn remove(inout self, key: String) -> Bool:
        """Remove key from cache."""
        var idx = self._find_key(key)
        if idx < 0:
            return False
        self._remove_at(idx)
        return True

    fn clear(inout self):
        """Clear all entries."""
        self.keys = List[String]()
        self.values = List[V]()
        self.expiry_times = List[Int64]()

    fn size(self) -> Int:
        """Get current size (includes expired entries)."""
        return len(self.keys)

    fn cleanup(inout self):
        """Remove all expired entries."""
        self._cleanup_expired()

    fn _find_key(self, key: String) -> Int:
        """Find index of key."""
        for i in range(len(self.keys)):
            if self.keys[i] == key:
                return i
        return -1

    fn _cleanup_expired(inout self):
        """Remove expired entries."""
        var new_keys = List[String]()
        var new_values = List[V]()
        var new_expiry = List[Int64]()

        for i in range(len(self.keys)):
            if self.expiry_times[i] > self.current_time:
                new_keys.append(self.keys[i])
                new_values.append(self.values[i])
                new_expiry.append(self.expiry_times[i])

        self.keys = new_keys
        self.values = new_values
        self.expiry_times = new_expiry

    fn _remove_oldest(inout self):
        """Remove entry with earliest expiry."""
        if len(self.keys) == 0:
            return

        var min_idx = 0
        var min_expiry = self.expiry_times[0]
        for i in range(1, len(self.expiry_times)):
            if self.expiry_times[i] < min_expiry:
                min_expiry = self.expiry_times[i]
                min_idx = i

        self._remove_at(min_idx)

    fn _remove_at(inout self, idx: Int):
        """Remove entry at index."""
        var new_keys = List[String]()
        var new_values = List[V]()
        var new_expiry = List[Int64]()

        for i in range(len(self.keys)):
            if i != idx:
                new_keys.append(self.keys[i])
                new_values.append(self.values[i])
                new_expiry.append(self.expiry_times[i])

        self.keys = new_keys
        self.values = new_values
        self.expiry_times = new_expiry


# =============================================================================
# Cache Statistics
# =============================================================================

struct CacheStats:
    """Cache statistics."""
    var hits: Int
    var misses: Int
    var evictions: Int
    var size: Int
    var max_size: Int

    fn __init__(out self):
        self.hits = 0
        self.misses = 0
        self.evictions = 0
        self.size = 0
        self.max_size = 0

    fn hit_rate(self) -> Float64:
        """Calculate hit rate."""
        var total = self.hits + self.misses
        if total == 0:
            return 0.0
        return Float64(self.hits) / Float64(total)

    fn __str__(self) -> String:
        return (
            "CacheStats(hits=" + str(self.hits) +
            ", misses=" + str(self.misses) +
            ", evictions=" + str(self.evictions) +
            ", size=" + str(self.size) +
            ", hit_rate=" + str(self.hit_rate()) + ")"
        )
