FROM islandoracollabgroup/isle-tomcat:serverjre8

## Dependencies 
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

## ImageMagick and OpenJPG
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
    ## I believe these are unused and actually install by libavcodec-extra.
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
    curl -O https://www.imagemagick.org/download/ImageMagick.tar.gz && \
    tar xf ImageMagick.tar.gz && \
    cd ImageMagick-* && \
    ./configure --enable-hdri --with-quantum-depth=16 --without-magick-plus-plus --without-perl --with-rsvg && \
    make && \
    make install && \
    ldconfig && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Djatoka
RUN cd /tmp && \
    curl -O https://sourceforge.mirrorservice.org/d/dj/djatoka/djatoka/1.1/adore-djatoka-1.1.tar.gz && \
    tar -xzf adore-djatoka-1.1.tar.gz -C /usr/local && \
    ln -s /usr/local/adore-djatoka-1.1/bin/Linux-x86-64/kdu_compress /usr/local/bin/kdu_compress && \
    ln -s /usr/local/adore-djatoka-1.1/bin/Linux-x86-64/kdu_expand /usr/local/bin/kdu_expand && \
    ln -s /usr/local/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_a60R.so /usr/local/lib/libkdu_a60R.so && \
    ln -s /usr/local/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_jni.so /usr/local/lib/libkdu_jni.so && \
    ln -s /usr/local/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_v60R.so /usr/local/lib/libkdu_v60R.so && \
    cp /usr/local/adore-djatoka-1.1/dist/adore-djatoka.war /usr/local/tomcat/webapps/adore-djatoka.war && \
    unzip -o /usr/local/tomcat/webapps/adore-djatoka.war -d /usr/local/tomcat/webapps/adore-djatoka/ && \
    echo "/usr/local/adore-djatoka-1.1/lib/Linux-x86-64" > /etc/ld.so.conf.d/kdu_libs.conf && \
    ldconfig && \
    sed -i 's/localhost:8080/isle.localdomain/g' /usr/local/tomcat/webapps/adore-djatoka/index.html && \
    ## Cleanup Phase.
    cd /usr/local/adore-djatoka-1.1/bin && \
    rm -rf *.bat Solaris-Sparc Solaris-Sparcv9 Solaris-x86 Win32 ../dist/adore-djatoka.war

## Cantaloupe 4.0.1
RUN cd /tmp && \
    curl -O -L https://github.com/medusa-project/cantaloupe/releases/download/v4.0.1/cantaloupe-4.0.1.zip && \
    unzip cantaloupe-*.zip && \
    rm cantaloupe-4.0.1/*.sample && \
    mkdir -p /usr/local/cantaloupe /usr/local/cantaloupe/temp /usr/local/cantaloupe/cache /usr/local/tomcat/logs/cantaloupe && \
    cp -r cantaloupe-4.0.1/* /usr/local/cantaloupe && \
    mv /usr/local/cantaloupe/cantaloupe-4.0.1.war /usr/local/tomcat/webapps/cantaloupe.war && \
    unzip /usr/local/tomcat/webapps/cantaloupe.war -d /usr/local/tomcat/webapps/cantaloupe && \
    chown tomcat /usr/local/cantaloupe -R && \
    ## Cleanup Phase.
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set up environmental variables for tomcat & dependencies
ENV JAVA_MAX_MEM=${JAVA_MAX_MEM:-2G} \
    JAVA_MIN_MEM=${JAVA_MIN_MEM:-0} \
    ## Per Gavin, we are no longer using -XX:+UseConcMarkSweepGC, instead G1GC.
    JAVA_OPTS='-Djava.awt.headless=true -server -Xmx${JAVA_MAX_MEM} -Xms${JAVA_MIN_MEM} -XX:+UseG1GC -XX:+UseStringDeduplication -XX:MaxGCPauseMillis=200 -XX:InitiatingHeapOccupancyPercent=70' \
    KAKADU_HOME=/usr/local/adore-djatoka-1.1/bin \
    KAKADU_LIBRARY_PATH=/usr/local/adore-djatoka-1.1/lib/Linux-x86-64 \
    CATALINA_OPTS="-Dcantaloupe.config=/usr/local/cantaloupe4/cantaloupe.properties \
    -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true \
    -Dkakadu.home=/usr/local/adore-djatoka-1.1/bin/Linux-x86-64 \
    -Djava.library.path=/usr/local/adore-djatoka-1.1/lib/Linux-x86-64:/usr/local/tomcat/lib \
    -DLD_LIBRARY_PATH=/usr/local/adore-djatoka-1.1/lib/Linux-x86-64:/usr/local/tomcat/lib"

# Labels
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="ISLE Image Services" \
      org.label-schema.description="Serving all your images needs." \
      org.label-schema.url="https://islandora-collaboration-group.github.io" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/Islandora-Collaboration-Group/isle-imageservices" \
      org.label-schema.vendor="Islandora Collaboration Group (ICG) - islandora-consortium-group@googlegroups.com" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0" \
      traefik.port="8080"

COPY rootfs /

EXPOSE 8080

ENTRYPOINT ["/init"]
