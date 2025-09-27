FROM alpine:latest

LABEL org.opencontainers.image.title borg-ssh-server
LABEL org.opencontainers.image.description Simple borg ssh server
LABEL org.opencontainers.image.authors TheDraca
LABEL org.opencontainers.image.source https://github.com/TheDraca/borg-ssh-server

# Install OpenSSH and bash
RUN apk add --no-cache \
    openssh \
    bash \
    borgbackup

#Expose SSH port
EXPOSE 22

# Copy launch script
COPY run.sh /
RUN chmod a+x /run.sh

#Run launch script
CMD [ "/run.sh" ]