# Based on node 10.X base image
FROM node:10
# Update NPM
RUN npm i -g npm
# In the folder /app
WORKDIR /app
# Copy package.json
COPY package.json .
# Install node_modules
RUN npm i
# Copy sources
COPY src/ src/
COPY public/ public/

# Run the app in dev mode, listening on port localhost:3000
CMD ["npm", "start"]