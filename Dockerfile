ARG GO_VERSION="1.20"

# First stage: build the executable.
FROM golang:${GO_VERSION}-alpine AS builder
ARG GITHUB_PAT

RUN mkdir /user && \
    echo 'nobody:x:65534:65534:nobody:/:' > /user/passwd && \
    echo 'nobody:x:65534:' > /user/group

RUN apk add --update --no-cache ca-certificates git

WORKDIR /src

# Import the code from the context.
COPY ./ ./

RUN git config --global url."https://${GITHUB_PAT}:x-oauth-basic@github.com/".insteadOf "https://github.com/"
ENV GOPRIVATE=github.com/y16ra/*
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app ./main.go
RUN rm /root/.gitconfig

# Final stage: the running container.
FROM amd64/alpine:latest as final

# Import the user and group files from the first stage.
COPY --from=builder /user/group /user/passwd /etc/

COPY --from=builder /app /app

CMD ["/app"]
