#Build ngrok server and client
FROM buildpack-deps:wheezy-scm

MAINTAINER Felix Fu <dukerider2015@gmail.com>

# gcc for cgo
RUN apt-get update && apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
	&& rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION 1.6beta1
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA1 5c02222a5ab348ae0f9244df95dea71781953749

RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
	&& echo "$GOLANG_DOWNLOAD_SHA1  golang.tar.gz" | sha1sum -c - \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

ENV NGROK_GIT https://github.com/inconshreveable/ngrok.git
ENV NGROK_BASE_DOMAIN ngrokd.t0.daoapp.io
ENV NGROK_DIR /ngrok
ENV NGROK_TMP /tmp/ngrok

ENV NGROK_CA_KEY assets/client/tls/ngrokroot.key
ENV NGROK_CA_CRT assets/client/tls/ngrokroot.crt
ENV NGROK_SERVER_KEY assets/server/tls/snakeoil.key
ENV NGROK_SERVER_CSR assets/server/tls/snakeoil.csr
ENV NGROK_SERVER_CRT assets/server/tls/snakeoil.crt

WORKDIR $NGROK_DIR

RUN apt-get update \
    && apt-get install -y build-essential \
                          curl \
                          git \
                          golang \
                          mercurial \
    && git clone ${NGROK_GIT} ${NGROK_TMP} \
    && cd ${NGROK_TMP} \
    && openssl genrsa -out ${NGROK_CA_KEY} 2048 \
    && openssl req -new -x509 -nodes -key ${NGROK_CA_KEY} -subj "/CN=${NGROK_BASE_DOMAIN}" -days 5000 -out ${NGROK_CA_CRT} \
    && openssl genrsa -out ${NGROK_SERVER_KEY} 2048 \
    && openssl req -new -key ${NGROK_SERVER_KEY} -subj "/CN=${NGROK_BASE_DOMAIN}" -out ${NGROK_SERVER_CSR} \
    && openssl x509 -req -in ${NGROK_SERVER_CSR} -CA ${NGROK_CA_CRT} -CAkey ${NGROK_CA_KEY} -CAcreateserial -days 5000 -out ${NGROK_SERVER_CRT} \
    && for GOOS in windows linux; \
       do \
         for GOARCH in 386 amd64 arm; \
         do \
           echo "=== $GOOS-$GOARCH ==="; \
           export GOOS GOARCH; \
           make release-all; \
           echo "=== done ==="; \
         done \
       done \
    && mv ${NGROK_CA_KEY} \
          ${NGROK_CA_CRT} \
          ${NGROK_SERVER_KEY} \
          ${NGROK_SERVER_CSR} \
          ${NGROK_SERVER_CRT} \
          ./bin/* \
          ${NGROK_DIR} \
    && apt-get purge --auto-remove -y build-essential \
                                      curl \
                                      git \
                                      golang \
                                      mercurial \
    && cd / \
    && cp -rf ${NGROK_DIR} /var/ngrok \
    && cd ${NGROK_DIR} \
    && rm -rf ${NGROK_TMP}

EXPOSE 40005 4443 10022

ENTRYPOINT ["./ngrokd"]
