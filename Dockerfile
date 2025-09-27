FROM alpine:latest

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