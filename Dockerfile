# Use official Swift image with Ubuntu
FROM swift:6.0-jammy

# Install ALSA development libraries and other dependencies
RUN apt-get update && apt-get install -y \
    libasound2-dev \
    alsa-utils \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /app

# Copy the package files
COPY . .

# Initialize git submodules (for portaudio)
RUN git submodule update --init --recursive

# Build the package
RUN swift build

# Run tests
CMD ["swift", "test"]