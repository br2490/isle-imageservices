# ISLE Image Services

## Part of the ISLE Islandora 7.x Docker Images
Designed as an Adore-djatoka and IIIF compliant image server for ISLE.

Based on:
  - [ISLE-tomcat](https://hub.docker.com/r/benjaminrosner/isle-tomcat/)
    - Ubuntu 18.04 "Bionic" (@see [ISLE-ubuntu-basebox](https://hub.docker.com/r/benjaminrosner/isle-ubuntu-basebox/))
      - General Dependencies
      - Oracle Java
      - Tomcat 8.5.31
  - [Cantaloupe 3.4.3](https://medusa-project.github.io/cantaloupe/) an IIIF comliant open-source dynamic image server
  - Adore-Djatoka 1.1 (deprecate when the community does)

Contains and Includes:
  - [ImageMagick 7](https://www.imagemagick.org/)
    - Features: Cipher DPC HDRI OpenMP 
    - Delegates (built-in): bzlib djvu mpeg fontconfig freetype jbig jng jpeg lcms lqr lzma openexr openjp2 png ps raw rsvg tiff webp wmf x zlib
  - [OpenJPEG](http://www.openjpeg.org/)
  - [FFmepg](https://www.ffmpeg.org/) 

## Generic Usage

```
docker run -it -p "8080:8080" --rm benjaminrosner/isle-imageservices bash
```

## Tomcat users

admin:isle_admin  
manager:isle_manager  

## Cantaloupe Default Admin User

Username: admin  
Password: isle_admin  