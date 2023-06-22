FROM golang:alpine AS builder

RUN apk --no-cache add make
WORKDIR /app
COPY . .
RUN ls

FROM alpine
RUN ls
WORKDIR /
RUN ls
COPY --from=builder /app/grpcsocket ./grpcsocket
RUN ls
# CMD ["/grpcsocket", "-socket=/hello.sock"]
CMD ["sh", "/grpcsocket"]
