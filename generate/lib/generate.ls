require! <[
  ./sass-compiler
  bluebird
  coffee-script
  commander
  crypto
  debug
  front-matter
  less
  marked
  path
  to-camel-case
]>
debug = debug 'generate'

io-concurrency = 256

bluebird.longStackTraces!

global <<< require \prelude-ls
global <<< (<[fs jade ncp]>
  |> map (-> [(to-camel-case it), bluebird.promisifyAll require it])
  |> pairs-to-obj)
global <<< (<[mkdirp recursive-readdir]>
  |> map (-> [(to-camel-case it), bluebird.promisify require it])
  |> pairs-to-obj)

jade-cache = {}
render-jade = (body, options) ->
  hash = crypto.create-hash 'sha1'
  hash.update body
  key = hash.digest 'hex'
  return that options if jade-cache[key]
  try
    (jade-cache[key] = jade.compile body, options) options
  catch e
    console.log e.message
    process.exit 1


chunks = (n, list) -->
  out = []
  rest = list
  until empty rest
    out.push(take n, rest)
    rest = drop n, rest
  out

# run an array of thunks that return a promise in groups of `concurrency`
# and return the list of results
p-comp = (concurrency, thunks) -->
  out = []

  (thunks
  |> chunks concurrency
  |> fold (a, b) ->
    a.then (results) ->
      bluebird.all(b |> map (-> it!))
      .then ->
        out.push results
        it
      .catch console.log
  , bluebird.resolve []
  ).then (results) ->
    out.push results
    flatten out
  .catch ->
    console.log "ERROR:", it

compilers =
  less: (body, doc-path) ->
    parser = bluebird.promisify-all new less.Parser do
      paths: [ path.dirname doc-path ]
      filename: doc-path
    parser.parse-async body
    .then -> it.toCSS compress: true

  jade: (body, doc-path, locals, globals) ->
    options = {}
    options <<< globals
    options <<< do
      filename: doc-path
      document: locals
    bluebird.resolve render-jade body, options

  coffee: (body) ->
    bluebird.resolve coffee-script.compile body

  md: (body) ->
    bluebird.resolve marked body

  sass: sass-compiler

select = <[css.less css.sass js.coffee html.jade html.md]>
regexes = select |> map -> new RegExp "\.#{it}$"

list-files = (docs-dir) ->
  recursive-readdir path.normalize path.join docs-dir, '.'
  .then ->
    it |> filter ((path) -> any (-> it.test path), regexes)

file-info = (file-path, docs-dir, out-dir) ->
  type = last (file-path / \.)

  dirname = ((path.dirname file-path) + '/').replace docs-dir, out-dir
  basename = path.basename file-path, ".#type"

  outpath = path.join dirname, basename

  url = outpath.replace out-dir, '/'

  [type, outpath, url]

index-files = (docs-dir, out-dir) ->
  ->
    it
    |> map (file-path) ->
      ->
        fs.read-file-async file-path, 'utf8'
        .then ->
          [type, outpath, url] = file-info file-path, docs-dir, out-dir

          try
            parsed = front-matter it
          catch e
            console.log "Cannot parse front matter of #file-path:"
            console.log e.stack
            process.exit 1


          parsed.attributes.path = file-path
          parsed.attributes.outpath = outpath
          parsed.attributes.url = url

          parsed = parsed <<< do
            path: file-path
            outpath: outpath
            type: type

          debug "Index (#type): #file-path -> #outpath (#url)"

          parsed
    |> p-comp io-concurrency

compile-files = ([items, config]) ->
  (items |> map (item) ->
    if item.type in <[md coffee less sass jade]>
      debug "Compile (#{item.type}): #{item.path}"
      compilers[item.type] item.body, item.path, item.attributes, config
      .then -> item.output = it; item
    else
      bluebird.resolve item
  |> (promises) ->  bluebird.all promises)
  .then -> [items, config]

render-layouts = (layouts-dir) ->
  ([items, config]) ->
    (items |> map (item) ->
      ->
        if item.attributes.layout
          layout-path = path.join layouts-dir, item.attributes.layout
          get-layout layout-path
          .then ->
            item.attributes.output = item.output
            debug "Layout (#{it.type}): #{item.path}"
            compilers[it.type] it.body, layout-path, item.attributes, config
            .then ->
              item.final-output = it; item
        else
          bluebird.resolve item
    |> fold ((a, b) -> a.then b), bluebird.resolve [])
    .then -> items

write-files = (items) ->
  items |> map (item) ->
    ->
      if item.final-output or item.output
        debug "Write #{item.outpath}"
        mkdirp path.dirname item.outpath
        .then -> fs.write-file-async item.outpath, (item.final-output or item.output)
      else
        debug "Skip #{item.outpath} (no output)"
        item
  |> p-comp io-concurrency

layout-cache = {}
get-layout = (path) ->
  return bluebird.resolve that if layout-cache[path]
  fs.read-file-async path, 'utf8'
  .then ->
    layout-cache[path] =
      body: it
      type: last (path / \.)

copy-files = (files-dir, out-dir) ->
  ncp.limit = 16
  ncp.ncp-async files-dir, out-dir

run = (config, docs-dir, files-dir, layouts-dir, out-dir, files) ->
  (if empty (files or []) then list-files docs-dir else bluebird.resolve files)
  .then index-files docs-dir, out-dir
  .then -> config.prepare it
  .then -> [it, config.globals(it)]
  .then compile-files
  .then render-layouts layouts-dir
  .then write-files
  .then copy-files files-dir, out-dir
  .catch (e) ->
    console.log e.stack
    process.exit 1

module.exports =
  run: run
