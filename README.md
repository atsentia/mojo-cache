# mojo-cache

Pure Mojo caching with LRU eviction and TTL expiration.

## Features

- **LRU Cache** - Least Recently Used eviction
- **TTL Cache** - Time-based expiration
- **Cache Stats** - Hit/miss tracking
- **Generic Types** - Works with any value type

## Installation

```bash
pixi add mojo-cache
```

## Quick Start

### LRU Cache

```mojo
from mojo_cache import LRUCache

var cache = LRUCache[String](max_size=100)

# Store values
cache.put("user:1", "Alice")
cache.put("user:2", "Bob")

# Retrieve
var value = cache.get("user:1")
if value:
    print(value.value())  # "Alice"

# Check existence
if cache.contains("user:2"):
    print("Found!")
```

### TTL Cache

```mojo
from mojo_cache import TTLCache

var cache = TTLCache[String](default_ttl_ms=60000)  # 1 minute TTL

cache.put("session:abc", "user_data")

# Value expires after 60 seconds
var value = cache.get("session:abc")
```

### Cache Statistics

```mojo
from mojo_cache import LRUCache

var cache = LRUCache[String](max_size=100)
# ... use cache ...

var stats = cache.stats()
print("Hits:", stats.hits)
print("Misses:", stats.misses)
print("Hit rate:", stats.hit_rate())
```

## API Reference

| Method | Description |
|--------|-------------|
| `put(key, value)` | Store a value |
| `get(key)` | Retrieve a value |
| `contains(key)` | Check if key exists |
| `remove(key)` | Remove a key |
| `clear()` | Remove all entries |
| `size()` | Current entry count |
| `stats()` | Get cache statistics |

## Testing

```bash
mojo run tests/test_cache.mojo
```

## License

MIT

## Part of mojo-contrib

This library is part of [mojo-contrib](https://github.com/atsentia/mojo-contrib), a collection of pure Mojo libraries.
