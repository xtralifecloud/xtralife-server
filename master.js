/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const cluster = require('cluster');
global.xlenv = require("xtralife-env");
const os = require("os");
const fs = require("fs");
const nodemailer = require("nodemailer");
const sendgrid = require("nodemailer-sendgrid-transport");
const moment = require("moment");

const env = process.env.NODE_ENV || 'dev';

xlenv.env = env;

xlenv.override(null, require('./config/default.js'));
xlenv.override(null, require('./config/' + env + '.js'));

if ((env === 'dev') && fs.existsSync(__dirname + '/config/' + os.hostname() + '.js')) {
	xlenv.override(null, require('./config/' + os.hostname() + '.js'));
}

global.logger = xlenv.createLogger(xlenv.logs);

let lastTimeMailSent = 0;
const mailer = nodemailer.createTransport(sendgrid({
	auth: {
		api_user: xlenv.mailer.user,
		api_key: xlenv.mailer.password
	}
}));

const _runningBatches = {};
const _addRunningBatch = function (process, batch) {
	if (_runningBatches[process] == null) { _runningBatches[process] = {}; }
	if (_runningBatches[process][batch] == null) {
		return _runningBatches[process][batch] = 1;
	} else {
		return _runningBatches[process][batch]++;
	}
};

const _removeRunningBatch = (process, batch) => _runningBatches[process][batch]--;

const _allRunningBatches = process => (() => {
	const result = [];
	for (let each in _runningBatches[process]) {
		const count = _runningBatches[process][each];
		if (count !== 0) {
			result.push(each);
		}
	}
	return result;
})();

const handleMessage = function (mess) {
	if (mess.cmd === 'batch') { // we've received a batch enter/exit message
		const { proc, batch, enter } = mess;

		if (enter) {
			_addRunningBatch(proc, batch);
		} else { _removeRunningBatch(proc, batch); }

		return;
	}

	if (mess.cmd === 'pong') { // we've received a pong
		const worker = cluster.workers[mess.index];
		worker.pongReceived = true;
		worker.lastPong = Date.now();
		worker.initialPongReceived = true; // we must know if the worker was previously up and running...
		return;
	}

	if (mess.cmd === "uncaughtException") { logger.fatal(mess.info); }
	if ((mess.cmd === "uncaughtException") && (['dev', 'vagrant'].indexOf(env) === -1)) {
		const now = moment();
		if (now.diff(lastTimeMailSent, 'seconds') > 120) {
			lastTimeMailSent = now;
			return mailer.sendMail({
				from: "Clan of the Cloud <noreply@clanofthecloud.com>",
				to: "roland@clanofthecloud.com",
				cc: "chris@clanofthecloud.com",
				subject: `[${env}] uncaught Exception`,
				text: mess.info
			}
				, function (err) {
					if (err != null) { return logger.error(`Can't send mail! ${err}`); }
				});
		}
	}
};



const numCPUs = os.cpus().length;

if (xlenv.nbworkers === 0) { xlenv.nbworkers = numCPUs; }

for (let i = 1, end = xlenv.nbworkers, asc = 1 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) { cluster.fork().on("message", handleMessage); }

cluster.on('exit', function (worker, code, signal) {
	logger.fatal(`Rocket worker ${worker.process.pid} died, fork a new one...`);
	if (['dev', 'vagrant'].indexOf(env) === -1) {
		const now = moment();
		if (now.diff(lastTimeMailSent, 'seconds') > 120) {
			lastTimeMailSent = now;
			mailer.sendMail({
				from: "Clan of the Cloud <noreply@clanofthecloud.com>",
				to: "roland@clanofthecloud.com",
				cc: "chris@clanofthecloud.com",
				subject: "rocket died!",
				text: `[${env}] rocket exit at ${moment().format()}`
			}
				, function (err) {
					if (err != null) { return logger.error(`Can't send mail! ${err}`); }
				});
		}
	}
	return cluster.fork().on("message", handleMessage);
});


// we can't use that anymore... looks like redis is also listening sometimes, causing logs garbage
//cluster.on 'listening', (worker, address)->
//	logger.info "A Rocket worker is now connected to " + address.address + ":" + address.port

cluster.on('online', worker => logger.info(`Rocket worker ${worker.process.pid} starts`));


process.on('uncaughtException', err => logger.fatal(`Master uncaughtException : ${err.message}`, { stack: err.stack }, err => process.exit(1)));

const ping = function (worker, index) {
	worker.pongReceived = false; // reset pongReceived
	worker.send({ cmd: 'ping', index }); // and send a ping
	return worker.lastPing = Date.now();
};

setInterval(function () {
	// we take into account only workers which replied "pong" at least once (initialPongReceived is true)
	// every worker which forgot to reply with pong is kill -9'ed...
	let index, each;
	const deadWorkers = ((() => {
		const result = [];
		for (index in cluster.workers) {
			each = cluster.workers[index];
			if (each.initialPongReceived && !each.pongReceived) {
				result.push(each);
			}
		}
		return result;
	})());
	if (deadWorkers.length > 0) {
		try {
			for (let worker of Array.from(deadWorkers)) {
				logger.fatal(`Cluster master killing ${worker.process.pid}, the following batches were running: ${_allRunningBatches(worker.process.pid).join(',')}`);
				logger.debug(`Last ping sent ${Date.now() - worker.lastPing}ms ago, last pong received ${Date.now() - worker.lastPong}ms ago`);
				process.kill(worker.process.pid, 'SIGKILL');
			}
		} catch (err) {
			logger.debug("Error when killing", err);
		}
	}
	// do nothing

	return (() => {
		const result1 = [];
		for (index in cluster.workers) {
			each = cluster.workers[index];
			if (each.state === 'listening') {
				result1.push(ping(each, index));
			}
		}
		return result1;
	})();
}
	, 10000);
