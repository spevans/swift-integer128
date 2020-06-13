# Run using: docker build --tag=integer128-tests:$(date +%s) .
FROM swift:5.1.2

COPY . /root/
WORKDIR /root
RUN swift test -v
