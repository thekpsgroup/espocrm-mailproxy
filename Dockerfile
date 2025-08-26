FROM node:20-slim

WORKDIR /app

COPY package.json ./
COPY src ./src

RUN npm install --production

CMD ["node", "src/index.js"]
