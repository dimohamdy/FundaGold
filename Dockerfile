# Start from the official Swift image
FROM swift:latest

# Declare BOT_TOKEN as a build argument
ARG BOT_TOKEN

# Set BOT_TOKEN as an environment variable
ENV BOT_TOKEN=$BOT_TOKEN

# Set the working directory in the container
WORKDIR /FundaGold

# Copy the entire contents of the current directory to the container
COPY . .

# Build your Swift app
RUN swift build

ENTRYPOINT ["swift", "run", "FundaGold"]
