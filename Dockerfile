FROM golang:1.13

WORKDIR /app
ADD app .

RUN go build -v -o /out/binary main.go

CMD ["/out/binary"]