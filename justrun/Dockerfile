#Just run ngrok server 
FROM ubuntu:14.04

MAINTAINER Felix Fu <dukerider2015@gmail.com>
RUN apt-get update && apt-get install -y git 
RUN git clone https://github.com/dukerider2015/ngrokd.git /ngrok
RUN cd /ngrok/justrun


EXPOSE 40005 4443 10022

ENTRYPOINT ["./ngrokd"]
