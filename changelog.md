#xtralife server changelog

## 4.2.3
xtralife-http: 4.1.3 </br>
xtralife-api: 4.2.6 </br>
xtralife-env : 4.0.1 </br>
xtralife-msg : 4.0.1 </br>
    
- change GCM to FCM for Android push notifications
- update APN service
- add timestamp to user device token
- remove user device token older than 1 month on login
- add token param for device token registration on login
- add message details on event route
- allow no hook definition in config
- prevent missing config for AWS

## 4.2.2
xtralife-http: 4.1.2 </br>
xtralife-api: 4.2.5 </br>
xtralife-env : 4.0.1 </br>

- modify config file for AWS S3 bucket configuration
- fix gamer VFS binary deletion route
- update aws-sdk

## 4.2.1
xtralife-http: 4.1.1 </br>
xtralife-api: 4.2.1 </br>
xtralife-env : 4.0.1 </br>

- add "credentials" key for external login

## 4.2.0
xtralife-http: 4.1.0 </br>
xtralife-api: 4.2.0 </br>
xtralife-env : 4.0.1 </br>

- add/update login and convert for email, steam, google, firebase, gamecenter, apple, facebook
- add "credentials" key for all login/convert routes (instead of "id"/"secret")
- update config files for network configuration

## 4.1.3
xtralife-http: 4.0.2 </br>
xtralife-api: 4.1.3 </br>
xtralife-env : 4.0.1 </br>

- add configurable redlock timeout via config and/or request params

## 4.1.2
xtralife-http: 4.0.2 </br>
xtralife-api: 4.1.1 </br>
xtralife-env : 4.0.1 </br>

- add business manager option for facebook login
- fix android in app 
- rename android in app config key to serviceAccount

## 4.1.1
xtralife-http: 4.0.2 </br>
xtralife-api: 4.1.1 </br>
xtralife-env : 4.0.1 </br>

- add count in find users response 
- fix binary data upload for VFS

## 4.0.2
xtralife-http: 4.0.1 </br>
xtralife-api: 4.0.2 </br>
xtralife-env : 4.0.1 </br>

- change base image in dockerfile (node 12 to node 16.14.0)
- add error handling for mongo 11000 error on user register

## 4.0.1
xtralife-http: 4.0.0 </br>
xtralife-api: 4.0.0 </br>
xtralife-env : 4.0.0 </br>

- update-npm dependencies
- switch npm install to npm ci in dockerfile

## 4.0.0
xtralife-http: 4.0.0-beta3 </br>
xtralife-api: 4.0.0-beta3 </br>
xtralife-msg : 4.0.0-alpha </br>
xtralife-env : 4.0.0-alpha </br>