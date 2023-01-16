# Nuage

### Lighter than Mastodon, duller than Pleroma

Nuage is a Mastodon fork that really cares about performance. It aims to improve Mastodon's performance by replacing individual building blocks with their optimized version, without any visible change in Mastodon's API and database schema.

Nuage is still very experimental. **Use at your own risk!**

## (Anti-)Features

* An alternative streaming server named [Mastoduck](https://github.com/nametoolong/mastoduck), written with [vibe.d](https://vibed.org/). The new server can handle over 1000 concurrent connections within a single process.

* [Blueprinter](https://github.com/blueprinter-ruby/blueprinter) instead of AMS for API serialization. The replacement reduced API response time by 20%.

* [Nokolexbor](https://github.com/serpapi/nokolexbor) instead of Nokogiri in Premailer processing.

* A record cache for status distribution. This slightly reduced database load when handling new statuses.

* A hellthread filter that rejects unexpected mentions.

* A bunch of micro optimizations in controllers and background workers.

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