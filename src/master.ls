{ promisify } = require \util
{ resolve } = require \path
{ watch } = require \chokidar
{ values, map } = require \prelude-ls
spawn = require \spawn-command
tree-kill = require \tree-kill |> promisify
death = require \death

BOTNET = process.env.BOTNET or \cultnet
BOTDIR = null
MASTER = resolve "#{__dirname}/.."

export Master = { start }

slaves = {}

function start botdir
  console.log "starting cultnet at #{botdir}"
  BOTDIR := resolve botdir
  doom-slaves!
  process.chdir MASTER
  patterns = ["#{BOTDIR}/**/*.slave.ls" "#{BOTDIR}/**/*.slave.ts" "#{BOTDIR}/**/*.slave.js"]
  watcher = watch patterns
  watcher.on \add add-slave
  watcher.on \unlink remove-slave

function add-slave path
  if not /\.slave\./.test path then return
  console.log "adding slave #{path}"
  cmd = "#{MASTER}/node_modules/@cultnet/slave-node/bin/cultnet-slave-node --respawn --no-notify #{path}"
  console.log "$ " + cmd
  slave =
    process: spawn cmd, { stdio: \inherit, +detached }
  slaves[path] = slave
  slave.process.on \exit ->
    console.log "slave died #{path}"
    delete slaves[path]

async function remove-slave path
  slave = slaves[path]
  if not slave then return
  console.log "removing slave #{path}"
  tree-kill slave.process.pid, \SIGKILL

function doom-slaves
  death ->
    slaves |> values
    |> map ({ process }) -> tree-kill process.pid, \SIGKILL
    |> Promise.all
      ..then -> process.exit!
