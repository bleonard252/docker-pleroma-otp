FROM debian

RUN apt update
#go ahead and update the package indices before we begin

# The steps in the Pleroma OTP installer docs,
# adapted to work as a reproducible Docker server
RUN adduser --system --shell  /bin/false --home /opt/pleroma pleroma
RUN echo 'arch="$(uname -m)";if [ "$arch" = "x86_64" ];then arch="amd64";elif [ "$arch" = "armv7l" ];then arch="arm";elif [ "$arch" = "aarch64" ];then arch="arm64";else echo "Unsupported arch: $arch">&2;fi;if getconf GNU_LIBC_VERSION>/dev/null;then libc_postfix="";elif [ "$(ldd 2>&1|head -c 9)" = "musl libc" ];then libc_postfix="-musl";elif [ "$(find /lib/libc.musl*|wc -l)" ];then libc_postfix="-musl";else echo "Unsupported libc">&2;fi;echo "$arch$libc_postfix"' > flavor.sh
RUN chmod +x flavor.sh && (./flavor.sh > flavor.txt) && cat flavor.txt
#Install dependencies
RUN apt install curl unzip libncurses5 postgresql postgresql-contrib systemd -y
RUN export FLAVOUR="$flavor"
#Download Pleroma
RUN curl "https://git.pleroma.social/api/v4/projects/2/jobs/artifacts/stable/download?job=$(cat flavor.txt)" -o /tmp/pleroma.zip 
RUN unzip /tmp/pleroma.zip -d /tmp/
#Install Pleroma to /opt/pleroma (this will be static for the build)
RUN mv /tmp/release/* /opt/pleroma && rmdir /tmp/release && rm /tmp/pleroma.zip
#Add the /var/lib/pleroma folders: uploads, static;
#and the /etc/pleroma config folder
RUN mkdir -p /var/lib/pleroma/uploads && chown -R pleroma /var/lib/pleroma && mkdir -p /var/lib/pleroma/static && chown -R pleroma /var/lib/pleroma && mkdir -p /etc/pleroma && chown -R pleroma /etc/pleroma

RUN apt install sudo -y
RUN chown -R pleroma /opt/pleroma
# Copy in the custom entrypoint script
COPY ./entrypoint.sh /entrypoint.sh
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 777 /entrypoint.sh
RUN chmod 777 /docker-entrypoint.sh
# Set the entrypoint
ENTRYPOINT /docker-entrypoint.sh

RUN usermod -aG sudo pleroma && chmod u+s /etc/init.d/postgresql
COPY ./sudoers /etc/sudoers

# What's necessary to volume
#Config
VOLUME /etc/pleroma
#Uploads, static, etc.
VOLUME /var/lib/pleroma/uploads
VOLUME /var/lib/pleroma/static
#Database
VOLUME /var/lib/postgresql

# Expose the Pleroma WebUI port
EXPOSE 4000

# Set the user
USER root
