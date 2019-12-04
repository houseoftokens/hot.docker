FROM ubuntu:18.04 as builder

RUN apt-get update && apt-get install -y git

WORKDIR /root
RUN git clone https://github.com/houseoftokens/hot.git

WORKDIR /root/hot/scripts
RUN ./hot_build_install.sh

FROM ubuntu:18.04

RUN apt-get update && apt-get install -y libssl1.1 libusb-1.0-0 libcurl4-gnutls-dev

RUN mkdir -p /hot/bin /hot/conf /hot/data

COPY --from=builder /root/eosio/1.8/bin/nodehot /hot/bin
COPY --from=builder /root/eosio/1.8/bin/clhot /hot/bin
COPY --from=builder /root/eosio/1.8/bin/khotd /hot/bin

COPY entry.sh /hot/bin
COPY logrotate.sh /hot/bin
COPY genesis.json /hot/conf
COPY logrotate.conf /hot/conf

EXPOSE 8011/tcp
EXPOSE 9011/tcp

CMD ["/hot/bin/entry.sh"]