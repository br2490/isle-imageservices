FROM benjaminrosner/isle-tomcat:latest

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="ISLE Image Services" \
      org.label-schema.description="Serving all your images needs." \
      org.label-schema.url="https://islandora-collaboration-group.github.io" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/Islandora-Collaboration-Group/isle-solr" \
      org.label-schema.vendor="Islandora Collaboration Group (ICG) - islandora-consortium-group@googlegroups.com" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0" \
      traefik.enable="true" \
      traefik.port="8080" \
      traefik.backend="isle-images"

###
# Dependencies 
RUN GEN_DEP_PACKS="ffmpeg \
    ffmpeg2theora \
    libavcodec-extra \
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
RUN BUILD_DEPS="build-essential \
    cmake \
    pkg-config \
    libtool" && \
    IMAGEMAGICK_LIBS="libbz2-dev \
	libdjvulibre-dev \
	libexif-dev \
    libgif-dev \
    libjpeg8 \
    libjpeg-dev \
	liblqr-dev \
    libopenexr-dev \
    libopenjp2-7-dev \
    libpng-dev \
    libraw-dev \
    librsvg2-dev \
    libtiff-dev \
    libwmf-dev \
    libwebp-dev \
    libwmf-dev \
    zlib1g-dev" && \
    ## These are unused and actually install by libavcodec-extra, I believe.
    IMAGEMAGICK_LIBS_EXTENDED="libfontconfig \
    libfreetype6-dev" && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
    apt-get install -y --no-install-recommends -o APT::Get::Install-Automatic=true $BUILD_DEPS && \
    apt-mark auto $BUILD_DEPS && \
    apt-get install -y --no-install-recommends $IMAGEMAGICK_LIBS && \
    cd /tmp && \
    git clone https://github.com/uclouvain/openjpeg && \
    cd openjpeg && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make && \
    make install && \
    ldconfig && \
    cd /tmp && \
    wget https://www.imagemagick.org/download/ImageMagick.tar.gz && \
    tar xf ImageMagick.tar.gz && \
    cd ImageMagick-* && \
    ./configure --enable-hdri --with-quantum-depth=16 --without-x --without-magick-plus-plus --without-perl --with-rsvg && \
    make && \
    make install && \
    ldconfig && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
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
# Cantaloupe 3.4.3 because I failed 4.x, and also failed to get this running as of 2018-08-05. Giving up for now.
# Ultimate thanks to Diego Pino Navarro's work on the Islandora Vagrant, for which the properties and delegates are copied from.
RUN cd /tmp && \
    wget https://github.com/medusa-project/cantaloupe/releases/download/v3.4.3/Cantaloupe-3.4.3.zip && \
    unzip Cantaloupe-*.zip && \
    rm Cantaloupe-3.4.3/*.sample && \
    mkdir -p /usr/local/cantaloupe /usr/local/tomcat/temp/cantaloupe && \
    cp Cantaloupe-3.4.3/* /usr/local/cantaloupe && \
    mv /usr/local/cantaloupe/Cantaloupe-3.4.3.war /usr/local/tomcat/webapps/cantaloupe.war && \
    unzip /usr/local/tomcat/webapps/cantaloupe.war -d /usr/local/tomcat/webapps/cantaloupe && \
    ## Cleanup Phase.
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set up environmental variables for tomcat & dependencies
ENV KAKADU_HOME=/usr/local/adore-djatoka-1.1/bin \
     KAKADU_LIBRARY_PATH=/usr/local/adore-djatoka-1.1/lib/Linux-x86-64 \
     PATH=$PATH:/usr/local/fedora/server/bin:/usr/local/fedora/client/bin \
     CATALINA_OPTS="-Dcantaloupe.config=/usr/local/cantaloupe/cantaloupe.properties \
	-Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true \
 	-Dkakadu.home=/usr/local/adore-djatoka-1.1/bin/Linux-x86-64 \
 	-Djava.library.path=/usr/local/adore-djatoka-1.1/lib/Linux-x86-64:/usr/local/tomcat/lib \
 	-DLD_LIBRARY_PATH=/usr/local/adore-djatoka-1.1/lib/Linux-x86-64:/usr/local/tomcat/lib"

COPY rootfs /

EXPOSE 8080

ENTRYPOINT ["/init"]