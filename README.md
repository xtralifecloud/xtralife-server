# Xtralife-server

Xtralife-server is a full-blown backend server for games.

This module only bootstraps the system: its goal is to help with configuration, then start a cluster of server processes.

## Dependencies

Redis, Mongodb and Elasticsearch are all required to run Xtralife-server.

### Use docker to supply all the necessary database services

```
docker run --name redis -d -p 6378:6379 redis
docker run --name mongo -d -p 27018:27017 mongo
docker run --name elastic -d -p 9200:9200 elasticsearch:2
```

The default TCP ports specified in `config/dev.coffee` are non-standard for redis and mongodb, to avoid any confusion between dev and production environments.

## Configuration

This module contains all the configuration of your server in the `./config` folder.
We provide a `./config/dev.coffee` conf file for the standard docker developement environment.
 
We also provide a `./config/production.coffee` conf file for the standard docker-compose xtralife-server.

The configuration file is chosen according to `process.NODE_ENV` and defaults to `dev`. It overrides `./config/default.coffee` settings.

note: Batches/hooks are just normal node modules required in the configuration files, to help with source code management.

`docker build -t xtralife/xtralife-server .` to build the Docker image

To run the server with links to the above containers :

`docker run --rm -it --link redis:redis --link mongo:mongodb --link elastic:elastic -e NODE_ENV=production -p 2000:2000 -v ~/logs:/server/logs -v ~/config:/server/config xtralife/xtralife-server`

`~/config` must contain a copy (customized) of `./config` for this command to run. 
`~/logs` will contain log files
