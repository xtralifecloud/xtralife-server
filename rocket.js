/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
global.xlenv = require("xtralife-env");
const os = require("os");
const fs = require("fs");
const http = require('http');
http.globalAgent.maxSockets = 50;
const util = require('util');

const env = process.env.NODE_ENV || 'dev';

xlenv.env = env;
xlenv.override(null, xlenv.Log);
xlenv.override(null, require('./config/default.js'));
xlenv.override(null, require('./config/' + env + '.js'));

if ((env === 'dev') && fs.existsSync(__dirname + '/config/' + os.hostname() + '.js')) {
	xlenv.override(null, require('./config/' + os.hostname() + '.js'));
}

xlenv.version = require("./package.json").version;

process.on('uncaughtException', function (err) {
	if (xlenv.options.continueOnException) {
		logger.error('UncaughtException');
		logger.error(err, { stack: err.stack });
		console.error(err);
		return console.log(err.stack);
	} else {
		console.error(err);
		console.log(err.stack);

		process.send({ cmd: 'uncaughtException', info: `uncaughtException :\n${err}\nstack : ${err.stack}` });

		console.log("Rocket quitting because of uncaught exception");
		return process.exit(1);
	}
});

process.on("unhandledRejection", function (reason, promise) {
	logger.error(`Unhandled promise rejection : ${reason}`, { reason: util.inspect(reason), stack: reason.stack });
	return logger.debug(`promise: ${util.inspect(promise)}`, promise);
}); // because I don't see what we could show in details...

global.logger = xlenv.createLogger(xlenv.logs);

xlenv.inject(['redisClient'], function (err, redis) {
	if (err != null) { return logger.error(err.message, { stack: err.stack }); }
	xlenv.redis.client = redis;

	logger.info(`redisClient connected to ${xlenv.redis.host}:${xlenv.redis.port}`);
	require("xtralife-http");

	// Now that we're up and running, answer pings from our cluster master
	return process.on('message', function (message) {
		if (message.cmd === 'ping') {
			return process.send({ cmd: 'pong', index: message.index });
		}
	});
});
