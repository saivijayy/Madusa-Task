FROM node:20

WORKDIR /app

COPY . .

# Install dependencies and Medusa CLI locally
RUN npm install

EXPOSE 9000

# Run the server directly from node_modules
CMD ["node_modules/.bin/medusa", "start", "--port", "9000"]
