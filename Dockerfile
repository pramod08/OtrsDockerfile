FROM ubuntu:14.04
MAINTAINER bizruntime
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get install -y wget nano apache2 supervisor libcrypt-ssleay-perl libencode-hanextra-perl libgd-gd2-perl \
 libgd-text-perl libgd-graph-perl libjson-xs-perl liblwp-useragent-determined-perl libmail-imapclient-perl libapache2-mod-perl2 \
 libnet-dns-perl libnet-ldap-perl libpdf-api2-perl libtext-csv-xs-perl libxml-parser-perl libyaml-perl libcrypt-eksblowfish-perl \
libyaml-libyaml-perl libnet-ldap-perl mysql-client

# Supervisor
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf


# OTRS
RUN wget http://ftp.otrs.org/pub/otrs/otrs-3.3.7.tar.bz2
RUN tar -C /opt -xjf otrs-3.3.7.tar.bz2 && rm otrs-3.3.7.tar.bz2 && mv /opt/otrs-3.3.7 /opt/otrs
RUN useradd -r -d /opt/otrs -c 'otrs' otrs
RUN usermod -G nogroup otrs
ADD Config.pm /opt/otrs/Kernel/Config.pm
RUN cd /opt/otrs/Kernel/Config && cp GenericAgent.pm.dist GenericAgent.pm
RUN cd /opt/otrs/var/cron && for foo in *.dist; do cp $foo `basename $foo .dist`; done
RUN cd /opt/otrs/bin && ./otrs.SetPermissions.pl /opt/otrs --otrs-user=otrs --otrs-group=nogroup --web-user=www-data --web-group=www-data
RUN ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/conf-enabled/otrs.conf


# ITSM without MySQL server
RUN cd /opt/otrs && wget http://ftp.otrs.org/pub/otrs/itsm/bundle33/ITSM-3.3.7.opm && chown otrs:nogroup /opt/otrs/ITSM-3.3.7.opm \
 && su otrs -c "/opt/otrs/bin/otrs.PackageManager.pl -a install -p /opt/otrs/ITSM-3.3.7.opm" && \
rm /opt/otrs/ITSM-3.3.7.opm && cd /opt/otrs/bin && ./otrs.SetPermissions.pl /opt/otrs --otrs-user=otrs --otrs-group=nogroup --web-user=www-data --web-group=www-data

# Set OTRS cron jobs
RUN su otrs -c "/opt/otrs/bin/Cron.sh start"


RUN apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

EXPOSE 22 80

CMD ["/usr/bin/supervisord"]
