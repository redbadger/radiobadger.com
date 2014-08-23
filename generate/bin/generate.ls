require! <[path commander ../lib/generate]>

default-config =
  prepare: -> it
  globals: -> {}

commander
  .usage('[options] <file ...>')
  .option('-c, --config [path]', 'Path to the config file [generate-config.ls]', 'generator-config')
  .option('-d, --docs [path]', 'Path to the documents directory [src/documents/]', 'src/documents/')
  .option('-f, --files [path]', 'Path to the files directory [src/files/]', 'src/files/')
  .option('-l, --layouts [path]', 'Path to the layouts directory [src/layouts/]', 'src/layouts/')
  .option('-o, --out [path]', 'Path to the output directory [out/]', 'out/')
  .parse process.argv

config = try
  config-file = path.resolve process.cwd!, commander.config
  require(config-file)
catch
  default-config

generate.run config, commander.docs, commander.files, commander.layouts, commander.out, commander.args
