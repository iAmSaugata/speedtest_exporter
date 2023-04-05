# Copyright (C) 2016-2019 Nicolas Lamirault <nicolas.lamirault@gmail.com>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM golang:alpine as builder

ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=arm64
ENV GO111MODULE=on

RUN apk update \
    && apk add --no-cache git ca-certificates tzdata \
    && update-ca-certificates

RUN adduser -D -g '' appuser

ADD . ${GOPATH}/src/app/
WORKDIR ${GOPATH}/src/app

RUN go mod download github.com/showwin/speedtest-go
RUN go build -a -installsuffix cgo -ldflags="-w -s" -o /speedtest_exporter ./cmd/speedtest_exporter/main.go

# --------------------------------------------------------------------------------

FROM alpine

LABEL summary="Speedtest Prometheus exporter" \
      description="A Prometheus exporter for speedtest" \
      name="olqs/speedtest_exporter" \
      url="https://github.com/olqs/speedtest_exporter" 

COPY --from=builder /speedtest_exporter /usr/bin/speedtest_exporter

#COPY --from=builder /etc/passwd /etc/passwd

EXPOSE 9090

ENV LISTEN_PORT=""
ENV FALLBACK=""
ENV SERVER_ID=""

ENTRYPOINT [ "/usr/bin/speedtest_exporter", "-port ${LISTEN_PORT:-9090}", "-server_id ${SERVER_ID:--1}", "${FALLBACK:--server_fallback}" ]
#ENTRYPOINT [ "/usr/bin/speedtest_exporter" ]
