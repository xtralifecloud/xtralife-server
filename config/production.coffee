os = require 'os'
nodemailer = require "nodemailer"
sendgrid = require "nodemailer-sendgrid-transport"

xlenv = require "xtralife-env"

# required to support Redis Sentinel HA
Q = require 'bluebird'
Sentinel = require 'redis-sentinel'
Redis = require 'redis'
Q.promisifyAll(Redis.RedisClient.prototype)
Q.promisifyAll(Redis.Multi.prototype)

Sentinel.redis = Redis

module.exports =

	nbworkers: 0 # start only one worker, regardless of cpu count
	logs:
		level: 'debug'

	sentinel:
		endpoints: [{host:"ip-172-31-42-215.eu-west-3.compute.internal", port:26379},{host:"ip-172-31-35-200.eu-west-3.compute.internal", port:26379}, {host:"ip-172-31-43-24.eu-west-3.compute.internal", port:26379}]

	redisClient: (cb)->
		client = Sentinel.createClient(xlenv.sentinel.endpoints, "mymaster",{})
		client.info (err)->
			cb err, client

	redisChannel: (cb)->
		client = Sentinel.createClient(xlenv.sentinel.endpoints, "mymaster",{})
		client.info (err)->
			cb err, client

	redisStats: (cb)->
		client = Sentinel.createClient(xlenv.sentinel.endpoints, "mymaster",{})
		client.info (err)->
			client.select 10
			cb err, client

	mongodb:
		url: "mongodb://ip-172-31-42-215.eu-west-3.compute.internal,ip-172-31-35-200.eu-west-3.compute.internal/?replicaSet=backend&maxPoolSize=25"
		options: # see http://mongodb.github.io/node-mongodb-native/driver-articles/mongoclient.html
			db:
				w: 1
				readPreference: "primary"

			server:
				auto_reconnect: true

			replSet:
				rs_name: "backend"

			mongos: {}
			promiseLibrary: require 'bluebird'

	elastic: (cb)->
		elastic = require("elasticsearch")
		client = new elastic.Client
			hosts: [{host: "ip-172-31-42-215.eu-west-3.compute.internal", port:9200}, {host: "ip-172-31-35-200.eu-west-3.compute.internal", port:9200}, {host: "ip-172-31-47-156.eu-west-1.compute.internal", port:9200}]
			keepAlive: true
			maxSockets: 50
			sniffInterval: 5*1000
		cb null, client


	mailer: nodemailer.createTransport(sendgrid(
		auth: # CONFIGURE ACCESS TO SENDGRID
			api_user: "CONFIGURE"
			api_key: "CONFIGURE"
	))

	privateKey: "KFhbLpzzy0cNN31im3vrrvWbNPiUbj"

	AWS: # CONFIGURE ACCESS TO YOUR AWS S3 BUCKET
		S3:
			bucket: null
			credentials:
				region: "eu-west-3"
				accessKeyId: null
				secretAccessKey: null
				
	xtralife:
		games:
			"com.clanofthecloud.testgame": 
				apikey:"testgame-key"
				apisecret:"testgame-secret"
				config:
					enable:true
					domains:[]
					eventedDomains:[]
					certs:
						android:
							enable: false
							senderID: '' # CONFIGURE
							apikey: '' # CONFIGURE
						ios:
							enable: false
							cert: '' # CONFIGURE
							key: '' # CONFIGURE
						macos:
							enable: false
							cert: '' #CONFIGURE
							key: '' #CONFIGURE
					socialSettings:
						facebookAppToken : '' # CONFIGURE

			"com.clanofthecloud.cloudbuilder": 
				apikey:"cloudbuilder-key"
				apisecret:"azerty"
				config:
					enable:true
					domains:["com.clanofthecloud.cloudbuilder.m3Nsd85GNQd3","com.clanofthecloud.cloudbuilder.test"]
					eventedDomains:["com.clanofthecloud.cloudbuilder.m3Nsd85GNQd3"]
					certs:
						certs:
							android:
								enable: false
								senderID: '' # CONFIGURE
								apikey: '' # CONFIGURE
							ios:
								enable: false
								cert: '' # CONFIGURE
								key: '' # CONFIGURE
							macos:
								enable: false
								cert: '' # CONFIGURE
								key: '' # CONFIGURE

					socialSettings:
						facebookAppToken : '' # CONFIGURE


	hooks:
		definitions: null

		functions: # CONFIGURE YOUR BATCHES / HOOKS for each domain
			"com.yourdomain.domainName": require './batches/yourdomain.js'
			"com.clanofthecloud.cloudbuilder.azerty": require('./batches/integrationTests.js')["com.clanofthecloud.cloudbuilder.azerty"]
			"com.clanofthecloud.cloudbuilder.m3Nsd85GNQd3": require('./batches/integrationTests.js')["com.clanofthecloud.cloudbuilder.m3Nsd85GNQd3"]
