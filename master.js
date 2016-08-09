#!/usr/bin/env node

require('coffee-script/register');

var cluster = require('cluster')

if (cluster.isMaster) {
	process.title = 'rocket.master'
	require('./master.coffee')
} else {
	process.title = 'rocket.slave'
	require('./rocket.coffee')	
}


