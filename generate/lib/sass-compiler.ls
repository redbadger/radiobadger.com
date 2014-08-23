require! <[
  bluebird
  path
  safeps
]>

spawn = bluebird.promisify safeps.spawn

module.exports = (body, doc-path, locals, globals) ->
  exec-path = safeps.get-exec-path 'sass'
  unless exec-path
    throw new Error "sass is not installed"
  load-path = path.dirname doc-path
  spawn do
    "sass --compass --no-cache --stdin --load-path #load-path"
    stdin: body
  .then ([stdout, stderr, code, signal]) ->
    bluebird.resolve stdout
