FROM swift:3.1


RUN apt-get update \
    && apt-get install -y libpthread-stubs0-dev \
    && rm -r /var/lib/apt/lists/*

WORKDIR /code

COPY Package.swift Package.pins /code/

RUN swift build || true

COPY ./Sources /code/Sources
COPY ./Tests /code/Tests

CMD swift test