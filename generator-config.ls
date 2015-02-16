
require! <[ marked to-slug-case rss xml moment ]>

# configuration options

site-title = "Radio Badger"
cut-mark = /\nMore...\n/i

# internal helpers

document-name = split '/' >> last >> split '.' >> first

contains = (a, b) --> (b.index-of a) isnt -1
is-type = (a, item) --> contains a, item.path
is-post = is-type '/posts/'

# document indexes

documents-by-path = {}
posts = []
podcasts = []

make-post = ->
  post = {}
  mark = []

  # Check if we have cut mark
  if (cut-mark.test it.body) is true
    mark = lines (it.body.match cut-mark).0
    post-parts = split '\n' + mark.1 + '\n' it.body
    post.preview = marked post-parts.0
    post.body = marked join '\n' post-parts
    post.read-more = true
  else
    post.body = marked it.body
    post.preview = post.body
    post.read-more = false

  post.title = it.attributes.name
  post.url = it.attributes.url
  post.date = it.attributes.date
  post.postdate = format-date it.attributes.date


  post

format-date = ->
  moment it .format 'DD MMM YYYY'

export-feed = ->
  rssfeed = new rss do
    title: 'Radio Badger podcast'
    description: 'Episodes of the Radio Badger podcast'
    site_url: 'http://radiobadger.com/'
    feed_url: 'http://radiobadger.com/feed.xml'
    image_url: 'http://radiobadger.com/images/rss.png'
    copyright: 'Creative Commons Attribution 4.0 International (CC BY 4.0)'

  for post in it
    rssfeed.item {
      title: post.title
      url: "http://radiobadger.com#{post.url}"
      description: post.preview
      date: new Date post.date
    }

  rssfeed.xml!

#
# Might be a great idea to move this into a separate NPM
#
export-podcast-feed = ->
  console.log 'exporting podcast feed'
  cast-items = podcast-items it

  podcast-feed =
    rss: [
      {
        _attr:
          'xmlns:itunes': 'http://www.itunes.com/dtds/podcast-1.0.dtd'
          version: '2.0'
      }
      {
        channel: [
          { title: 'Radio Badger tech podcast' }
          { link: 'http://radiobadger.com/' }
          { language: 'en-us' }
          { copyright: '2014 Alexander Savin, Roisi Proven and Robbie McCorkell' }
          { pub-date: moment!.format 'ddd, D MMM YYYY HH:mm:ss ZZ' }
          { 'itunes:subtitle': 'Show on tech, art, games and life in London' }
          { 'itunes:author': 'Alexander Savin, Roisi Proven and Robbie McCorkell' }
          { 'itunes:summary': 'Radio Badger is a podcast on tech, art, games and life in London, broadcasted from the shed in the middle of Silicon Roundabout in Shoreditch.' }
          { description: 'Radio Badger is a podcast on tech, art, games and life in London, broadcasted from the shed in the middle of Silicon Roundabout in Shoreditch.' }
          { 'itunes:owner': [
            { 'itunes:name': 'Alexander Savin' }
            { 'itunes:email': 'alex.savin@red-badger.com' }
          ]}
          { 'itunes:image': [
            _attr:
              href: 'http://radiobadger.com/images/badger-radio-album-cover.png'
          ]}
          { 'itunes:explicit': 'yes' }
          { 'itunes:category': [
            _attr:
              text: 'Technology'
          ]}
          { 'itunes:category': [
            _attr:
              text: 'Gadgets'
          ]}
        ]
      }
    ]

  podcast-feed.rss.1.channel = union podcast-feed.rss.1.channel, cast-items

  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n#{xml podcast-feed, true}"

podcast-items = ->
  console.log 'Rendering podcast items...'
  items = []
  for cast in it
    items.push do
      item: [
        { title: cast.attributes.podcast-title }
        { author: cast.attributes.author }
        { 'itunes:author': cast.attributes.author }
        { 'itunes:subtitle': cast.attributes.subtitle }
        { 'itunes:summary': cast.attributes.summary }
        { 'itunes:duration': cast.attributes.duration }
        { 'itunes:image': [
          _attr:
            href: cast.attributes.album-cover
        ]}
        { description: cast.attributes.summary }
        { url: cast.attributes.enclosure }
        { guid: cast.attributes.guid }
        { pub-date: moment cast.attributes.date .format 'ddd, D MMM YYYY HH:mm:ss ZZ' }
        { enclosure: [
          _attr:
            url: cast.attributes.enclosure
            type: 'audio/mpeg'
            length: cast.attributes.length
        ]}
      ]

  items

module.exports =

  prepare: (items) ->
    console.log "Preparing items..."

    items |> each (item) ->
      | is-post item
        posts.push (make-post item)
        if item.attributes.podcast-title?
          podcasts.push item
      item.attributes.date = format-date item.attributes.date

      console.log item.path
      documents-by-path[item.path] = item

  globals: (items) ->
    console.log "Preparing globals..."

    fs.writeFile 'out/feed.xml', (export-feed posts), (err) ->
      throw err if err

    fs.writeFile 'out/podcast-feed.xml', (export-podcast-feed podcasts), (err) ->
        throw err if err

    title: ->
      if it.title  then "#{it.title} | #site-title" else site-title

    posts: reverse posts
