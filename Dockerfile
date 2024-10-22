FROM ghcr.io/prefix-dev/pixi:latest

WORKDIR /app

# Running as non-root user.
RUN useradd -m -r user && \
    chown user /app

# Copying project settings.
COPY ./pyproject.toml ./
COPY ./setup.cfg ./

# Copying dependencies and installing them.
COPY ./pixi.toml ./
COPY ./pixi.lock ./
# RUN pixi run --environment dev install

# Copying everything that will be useful in ci: options for
# linters, formatters, test and other tools.
COPY ./pytest.ini ./
COPY ./mypy.ini ./

# Copying source and test files.
COPY ./src ./src
COPY ./tests/ ./tests

# Start of the command for any of the checks. Packages will be installed along the way.
ENTRYPOINT ["/usr/local/bin/pixi", "run", "--environment", "dev"]

# Stay running.
CMD ["sleep", "infinity"]
