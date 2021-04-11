FROM node:alpine

WORKDIR /usr/src/app

COPY . .

RUN npm ci --only=production

CMD [ "npm", "run", "start" ]