FROM node:12

RUN mkdir -p /server
WORKDIR /server

COPY package.json /server/
COPY package-lock.json /server/

RUN npm install

COPY . /server

EXPOSE 2000

VOLUME ["/server/config", "/server/logs"]

CMD [ "npm", "start" ]
