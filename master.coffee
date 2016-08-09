cluster = require 'cluster'
global.xlenv = require "xtralife-env"
os = require "os"
fs = require "fs"
extend = require "extend"
nodemailer = require "nodemailer"
sendgrid = require "nodemailer-sendgrid-transport"
moment = require "moment"

env = process.env.NODE_ENV || 'dev'

xlenv.env = env

xlenv.override null, require './config/default.coffee'
xlenv.override null, require './config/' + env + '.coffee'

if env=='dev' && fs.existsSync(__dirname + '/config/' + os.hostname() + '.coffee')
	xlenv.override null, require './config/' + os.hostname() + '.coffee'

global.logger = xlenv.createLogger xlenv.logs

lastTimeMailSent = 0
mailer = nodemailer.createTransport(sendgrid(
	auth:
		api_user : xlenv.mailer.user
		api_key : xlenv.mailer.password 
))

_runningBatches = {}
_addRunningBatch = (process, batch)->
	unless _runningBatches[process]? then _runningBatches[process]={}
	unless _runningBatches[process][batch]?
		_runningBatches[process][batch] = 1
	else
		_runningBatches[process][batch]++

_removeRunningBatch = (process, batch)->
	_runningBatches[process][batch]--

_allRunningBatches = (process)->
	(each for each, count of _runningBatches[process] when count isnt 0)

handleMessage = (mess)->
	if mess.cmd is 'batch' # we've received a batch enter/exit message
		{proc, batch, enter} = mess

		if enter then _addRunningBatch(proc, batch)
		else _removeRunningBatch(proc, batch)

		return

	if mess.cmd is 'pong' # we've received a pong
		worker = cluster.workers[mess.index]
		worker.pongReceived = true
		worker.lastPong = Date.now()
		worker.initialPongReceived = true # we must know if the worker was previously up and running...
		return

	if mess.cmd is "uncaughtException" then logger.fatal mess.info
	if mess.cmd is "uncaughtException" and ['dev', 'vagrant'].indexOf(env) is -1
		now = moment()
		if now.diff(lastTimeMailSent, 'seconds') > 120
			lastTimeMailSent = now
			mailer.sendMail
				from: "Clan of the Cloud <noreply@clanofthecloud.com>"
				to: "roland@clanofthecloud.com"
				cc: "chris@clanofthecloud.com"
				subject: "[#{env}] uncaught Exception"
				text: mess.info
			, (err) ->
				logger.error "Can't send mail! #{err}" if err?



numCPUs = os.cpus().length;

if xlenv.nbworkers==0 then xlenv.nbworkers = numCPUs

cluster.fork().on("message", handleMessage) for i in [1..xlenv.nbworkers]

cluster.on 'exit', (worker, code, signal)->
	logger.fatal "Rocket worker #{worker.process.pid} died, fork a new one..."
	if ['dev', 'vagrant'].indexOf(env)==-1
		now = moment()
		if now.diff(lastTimeMailSent, 'seconds') > 120
			lastTimeMailSent = now
			mailer.sendMail
				from: "Clan of the Cloud <noreply@clanofthecloud.com>"
				to: "roland@clanofthecloud.com"
				cc: "chris@clanofthecloud.com"
				subject: "rocket died!"
				text: "[#{env}] rocket exit at #{moment().format()}"
			, (err) ->
				logger.error "Can't send mail! #{err}" if err?
	cluster.fork().on("message", handleMessage)


# we can't use that anymore... looks like redis is also listening sometimes, causing logs garbage
#cluster.on 'listening', (worker, address)->
#	logger.info "A Rocket worker is now connected to " + address.address + ":" + address.port

cluster.on 'online', (worker)->
	logger.info "Rocket worker #{worker.process.pid} starts"


process.on 'uncaughtException', (err)->
    logger.fatal "Master uncaughtException : #{err.message}", {stack: err.stack}, (err)->
        process.exit 1

ping = (worker, index)->
	worker.pongReceived = false # reset pongReceived
	worker.send {cmd: 'ping', index: index} # and send a ping
	worker.lastPing = Date.now()

setInterval ()->
	# we take into account only workers which replied "pong" at least once (initialPongReceived is true)
	# every worker which forgot to reply with pong is kill -9'ed...
	deadWorkers = (each for index, each of cluster.workers when each.initialPongReceived and not each.pongReceived)
	if deadWorkers.length > 0
		try
			for worker in deadWorkers
				logger.fatal "Cluster master killing #{worker.process.pid}, the following batches were running: #{_allRunningBatches(worker.process.pid).join(',')}"
				logger.debug "Last ping sent #{Date.now() - worker.lastPing}ms ago, last pong received #{Date.now() - worker.lastPong}ms ago"
				process.kill(worker.process.pid, 'SIGKILL')
		catch err
			logger.debug "Error when killing", err
			# do nothing

	ping(each, index) for index, each of cluster.workers when each.state is 'listening'
, 10000
