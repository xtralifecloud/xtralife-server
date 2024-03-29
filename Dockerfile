FROM node:18.13.0

RUN mkdir -p /server
WORKDIR /server

COPY package*.json /server/

RUN npm ci

COPY . /server

EXPOSE 2000
EXPOSE 10254

VOLUME ["/server/config", "/server/logs"]

CMD [ "npm", "start" ]
