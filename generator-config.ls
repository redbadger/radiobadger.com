
require! <[ marked to-slug-case rss moment ]>

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


  post

export-feed = ->


  rssfeed = new rss do
    title: 'Radio Badger podcast'
    description: 'Episodes of the Radio Badger podcast'
    site_url: 'http://radiobadger.com/'
    feed_url: 'http://radiobadger.com/feed.xml'
    image_url: 'http://radiobadger.com/images/rss.png'
    copyright: 'Creative Commons Attribution 4.0 International (CC BY 4.0)'
    #author: 'Alexander Savin'

  for post in it
    rssfeed.item {
      title: post.title
      url: "http://radiobadger.com#{post.url}"
      description: post.preview
      date: new Date post.date
    }

  rssfeed.xml!

module.exports =

  prepare: (items) ->
    console.log "Preparing items..."

    items |> each (item) ->
      | is-post item
        posts.push (make-post item)

      console.log item.path
      documents-by-path[item.path] = item

  globals: (items) ->
    console.log "Preparing globals..."

    fs.writeFile 'out/feed.xml', (export-feed posts), (err) ->
      throw err if err

    title: ->
      if it.title  then "#{it.title} | #site-title" else site-title

    posts: reverse posts
