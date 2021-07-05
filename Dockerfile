# Run using: docker build --tag=integer128-tests:$(date +%s) .
FROM swift:latest

COPY . /root/
WORKDIR /root
RUN echo "$CACHEBUST"
RUN swift test -v
