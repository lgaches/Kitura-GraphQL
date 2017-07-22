FROM swift:3.1


WORKDIR /code

COPY Package.swift Package.pins /code/

RUN swift build || true

COPY ./Sources /code/Sources
COPY ./Tests /code/Tests

CMD swift test