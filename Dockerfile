FROM benjaminrosner/isle-tomcat:latest

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date="2018-08-05T17:13:02Z" \
      org.label-schema.name="ISLE Image Services" \
      org.label-schema.description="Serving all your images needs." \
      org.label-schema.url="https://islandora-collaboration-group.github.io" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/Islandora-Collaboration-Group/isle-solr" \
      org.label-schema.vendor="Islandora Collaboration Group (ICG) - islandora-consortium-group@googlegroups.com" \
      org.label-schema.version="RC-20180805T171302Z" \
      org.label-schema.schema-version="1.0" \
      traefik.enable="true" \
      traefik.port="8080" \
      traefik.backend="isle-images"
      # traefik.frontend.rule="Host:images.isle.localdomain;"

###
# Dependencies 
RUN GEN_DEP_PACKS="libimage-exiftool-perl \
    libtool \
    libpng-dev \
    libjpeg-dev \
    libopenjp2-7-dev \
    libtiff-dev \
    libgif-dev \
    liblqr-1-0 \
    libdjvulibre-dev \
    libwmf0.2-7 \
    libopenexr22 \
    libwebp-dev \
    giflib-tools \
    ffmpeg \
    ffmpeg2theora \
    libavcodec-extra \
    x264 \
    lame \
    ghostscript \
    xpdf \
    poppler-utils" && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
    apt-get install -y --no-install-recommends $GEN_DEP_PACKS && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

###
# ImageMagick and OpenJPG
RUN SOURCE_PACKS="imagemagick" && \
    BUILD_DEPS="cmake" && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    cp /etc/apt/sources.list /etc/apt/sources.list.bak && \
    sed -i '/^# deb-src.*bionic.[mus]/ s/^# //' /etc/apt/sources.list && \
    apt-get update && \
    apt-get build-dep -y -o APT::Get::Build-Dep-Automatic=true $SOURCE_PACKS && \
    apt-get install -y --no-install-recommends $BUILD_DEPS && \
    apt-mark auto cmake && \
    cd /tmp && \
    git clone https://github.com/uclouvain/openjpeg && \
    cd openjpeg && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make && \
    make install && \
    cd /tmp && \
    wget https://www.imagemagick.org/download/ImageMagick.tar.gz && \
    tar xf ImageMagick.tar.gz && \
    cd ImageMagick-* && \
    ./configure --without-x --without-magick-plus-plus --without-perl && \
    make && \
    make install && \
    ldconfig && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm /etc/apt/sources.list && mv /etc/apt/sources.list.bak /etc/apt/sources.list && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

###
# Djatoka
RUN cd /tmp && \
    wget https://sourceforge.mirrorservice.org/d/dj/djatoka/djatoka/1.1/adore-djatoka-1.1.tar.gz && \
    tar -xzf adore-djatoka-1.1.tar.gz -C /usr/local && \
    ln -s /usr/local/adore-djatoka-1.1/bin/Linux-x86-64/kdu_compress /usr/local/bin/kdu_compress && \
    ln -s /usr/local/adore-djatoka-1.1/bin/Linux-x86-64/kdu_expand /usr/local/bin/kdu_expand && \
    ln -s /usr/local/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_a60R.so /usr/local/lib/libkdu_a60R.so && \
    ln -s /usr/local/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_jni.so /usr/local/lib/libkdu_jni.so && \
    ln -s /usr/local/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_v60R.so /usr/local/lib/libkdu_v60R.so && \
    cp /usr/local/adore-djatoka-1.1/dist/adore-djatoka.war /usr/local/tomcat/webapps/adore-djatoka.war && \
    unzip -o /usr/local/tomcat/webapps/adore-djatoka.war -d /usr/local/tomcat/webapps/adore-djatoka/ && \
    sed -i 's#DJATOKA_HOME=`pwd`#DJATOKA_HOME=/usr/local/adore-djatoka-1.1#g' /usr/local/adore-djatoka-1.1/bin/env.sh && \
    sed -i 's|`uname -p` = "x86_64"|`uname -m` = "x86_64"|' /usr/local/adore-djatoka-1.1/bin/env.sh && \
    echo "/usr/local/adore-djatoka-1.1/lib/Linux-x86-64" > /etc/ld.so.conf.d/kdu_libs.conf && \
    ldconfig && \
    sed -i 's/localhost:8080/isle.localdomain/g' /usr/local/tomcat/webapps/adore-djatoka/index.html && \
    ## Cleanup Phase.
    rm /usr/local/adore-djatoka-1.1/bin/*.bat /usr/local/adore-djatoka-1.1/dist/adore-djatoka.war

###
# Cantaloupe 3.4.2 because I failed 4.x, and also failed to get this running as of 2018-08-05. Giving up for now.
# Ultimate thanks to Diego Pino Navarro's work on the Islandora Vagrant, for which the properties and delegates are copied from.
RUN cd /tmp && \
    wget https://github.com/medusa-project/cantaloupe/releases/download/v3.4.2/cantaloupe-3.4.2.zip && \
    unzip cantaloupe-*.zip -d /usr/local && \
    cp /usr/local/Cantaloupe-3.4.2/Cantaloupe-3.4.2.war /usr/local/tomcat/webapps/cantaloupe.war && \
    unzip /usr/local/tomcat/webapps/cantaloupe.war -d /usr/local/tomcat/webapps/cantaloupe && \
    ## Cleanup Phase.
    rm /usr/local/Cantaloupe-3.4.2/Cantaloupe-3.4.2.war /usr/local/Cantaloupe-3.4.2/*.sample && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set up environmental variables for tomcat & dependencies
ENV KAKADU_HOME=/usr/local/adore-djatoka-1.1/bin \
     KAKADU_LIBRARY_PATH=/usr/local/adore-djatoka-1.1/lib/Linux-x86-64 \
     PATH=$PATH:/usr/local/fedora/server/bin:/usr/local/fedora/client/bin \
     CATALINA_OPTS="-Dcantaloupe.config=/usr/local/Cantaloupe-3.4.2/cantaloupe.properties \
	-Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true \
 	-Dkakadu.home=/usr/local/adore-djatoka-1.1/bin/Linux-x86-64 \
 	-Djava.library.path=/usr/local/adore-djatoka-1.1/lib/Linux-x86-64:/usr/local/tomcat/lib \
 	-DLD_LIBRARY_PATH=/usr/local/adore-djatoka-1.1/lib/Linux-x86-64:/usr/local/tomcat/lib"

COPY rootfs /

EXPOSE 8080

ENTRYPOINT ["/init"]