#!/usr/bin/env node

var cluster = require('cluster')

if (cluster.isMaster) {
	process.title = 'xtralife.master'
	require('./master.js')
} else {
	process.title = 'xtralife.slave'
	require('./rocket.js')
}
