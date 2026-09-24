FROM tsl0922/ttyd:alpine

RUN apk add --no-cache openssh-client-default bash less nano \
 && adduser -D -s /bin/bash dev

COPY start.sh /usr/local/bin/start.sh
RUN sed -i 's/\r$//' /usr/local/bin/start.sh && chmod 755 /usr/local/bin/start.sh

# Miget derives the public port from EXPOSE; its ingress only reaches 5000
EXPOSE 5000

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start.sh"]
