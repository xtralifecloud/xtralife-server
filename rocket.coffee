global.xlenv = require "xtralife-env"
os = require "os"
fs = require "fs"
http = require 'http'
http.globalAgent.maxSockets = 50;
util = require 'util'

env = process.env.NODE_ENV || 'dev'

xlenv.env = env
xlenv.override null, xlenv.Log
xlenv.override null, require './config/default.coffee'
xlenv.override null, require './config/' + env + '.coffee'

if env=='dev' && fs.existsSync(__dirname + '/config/' + os.hostname() + '.coffee')
	xlenv.override null, require './config/' + os.hostname() + '.coffee'

xlenv.version = require("./package.json").version

process.on 'uncaughtException', (err)->
	if xlenv.options.continueOnException
		logger.error 'UncaughtException'
		logger.error err, {stack: err.stack}
		console.error err
		console.log err.stack
	else
		console.error err
		console.log err.stack

		process.send({ cmd: 'uncaughtException', info: "uncaughtException :\n#{err}\nstack : #{err.stack}" })

		console.log "Rocket quitting because of uncaught exception"
		process.exit()

process.on "unhandledRejection", (reason, promise) ->
	logger.error "Unhandled promise rejection : #{reason}", {reason: util.inspect(reason), stack: reason.stack}
	logger.debug "promise: #{util.inspect promise}", promise # because I don't see what we could show in details...

global.logger = xlenv.createLogger xlenv.logs

xlenv.inject ['redisClient'], (err, redis)->
	if err? then return logger.error err.message, {stack: err.stack}
	xlenv.redis.client = redis

	logger.info "redisClient connected to #{xlenv.redis.host}:#{xlenv.redis.port}"
	require "xtralife-http"

	# Now that we're up and running, answer pings from our cluster master
	process.on 'message', (message)->
		if message.cmd is 'ping'
			process.send {cmd: 'pong', index: message.index}
