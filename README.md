# Nuage

### Lighter than Mastodon, duller than Pleroma

Nuage is a Mastodon fork that really cares about performance. It aims to improve Mastodon's performance by replacing individual building blocks with their optimized version, without any visible change in Mastodon's API and database schema. In other words, Nuage optimizes what Mastodon is unwilling to optimize, but retains the ability to migrate back seamlessly.

Nuage is still very experimental. **Use at your own risk!**

## (Anti-)Features

* An alternative streaming server named [Mastoduck](https://github.com/nametoolong/mastoduck), written with [vibe.d](https://vibed.org/). The new server can handle over 1000 concurrent connections within a single process.

* [Blueprinter](https://github.com/blueprinter-ruby/blueprinter) instead of AMS for API serialization. The replacement reduced API response time by 20%.

* [Cache Crispies](https://github.com/codenoble/cache-crispies) instead of AMS for ActivityPub serialization.

* [Nokolexbor](https://github.com/serpapi/nokolexbor) instead of Nokogiri in Premailer processing.

* A record cache for status distribution. This slightly reduced database load when handling new statuses.

* A hellthread filter that rejects unexpected mentions.

* A bunch of micro optimizations in controllers and background workers.

## Benchmark

Here are some completely unscientific benchmark results.

```
Document Path:          /api/v1/timelines/home

Nuage Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.3      0       5
Processing:   184  382  82.2    358     964
Waiting:      184  378  83.8    355     964
Total:        184  383  82.3    358     964

Stock Mastodon Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.0      0       0
Processing:   275  570  95.1    545    1044
Waiting:      274  566  95.6    542    1044
Total:        275  570  95.1    545    1044

Document Path:          /api/v1/notifications

Nuage Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.1      0       0
Processing:   123  269  60.1    261     599
Waiting:      123  269  60.1    261     599
Total:        124  269  60.1    261     599

Stock Mastodon Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.1      0       1
Processing:   114  318  81.5    294     756
Waiting:      113  318  81.5    293     756
Total:        114  318  81.5    294     756
```

## Deployment

### Tech stack:

- **Ruby on Rails** powers the REST API and other web pages
- **React.js** and Redux are used for the dynamic parts of the interface
- **Vibe.d** powers the streaming API

### Requirements:

- **PostgreSQL** 9.5+
- **Redis** 7+
- **Ruby** 3+
- **Node.js** 14+
- **DMD** 2.98+

Please note that Nuage works best with a dedicated Redis database. It is possible for multiple Nuage instances to share one Redis database, but they will flush each other's cache keys and slow down each other even when namespaced.