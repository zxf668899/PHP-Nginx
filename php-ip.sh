#!/bin/bash
# Description: PHP install script For Docker
# Date: 2016-08-25
# jie.yang  zxf668899@163.com
# Please after yum execute the script!!
# yum install -y gcc gcc-c++ apr-devel apr-util-devel unzip cmake libtool perl-devel perl-ExtUtils-Embed GeoIP GeoIP-devel make
# yum install -y git wget 
#
Sdir=${PWD}
Bsdir=${PWD}/BasicPackage
Exdir=${PWD}/PHP-Extend
###
openssl=${Sdir}/openssl-1.0.2h
nghttp2=${Sdir}/nghttp2
curl=${Sdir}/curl-7.44.0
jpeg=${Sdir}/jpeg-9
libiconv=${Sdir}/libiconv-1.14
libmcrypt=${Sdir}/libmcrypt-2.5.8
libxml2=${Sdir}/libxml2-2.9.0
libxslt=${Sdir}/libxslt-1.1.28
zlib=${Sdir}/zlib-1.2.7
libpng=${Sdir}/libpng-1.6.0
freetype=${Sdir}/freetype-2.4.0
fontconfig=${Sdir}/fontconfig-2.10.2
gd=${Sdir}/gd/2.0.35
gd2=${Sdir}/libgd-gd-libgd-9f0a7e7f4f0f
pcre=${Sdir}/pcre-8.32
libevent=${Sdir}/libevent-2.0.21-stable
mhash=${Sdir}/mhash-0.9.9.9
libunwind=${Sdir}/libunwind-1.1
gperftools=${Sdir}/gperftools-2.1
#####   PHP Variable declaration  ######
php7=${Sdir}/php-7.0.10
basedir=/usr/local/php
cfile=/usr/local/php/etc
### PHP Extend Package Path
phpredis=${Sdir}/phpredis-php7
libmemcache=${Sdir}/libmemcached-1.0.18
phpmemcache=${Sdir}/php-memcached-php7
phpmongo=${Sdir}/mongo-php-driver
phpssdb=${Sdir}/phpssdb-php7
runkit7=${Sdir}/runkit7-master
swoole=${Sdir}/swoole-src-1.8.10-stable
geoip=${Sdir}/geoip
### Add  User
groupadd -g 1000 apache
useradd -u 510 -r -g apache apache 
### Unpack the Basic installation package
set -e
for Package in ${Bsdir}/*.tar.gz
do
   tar zxf $Package
done

# Unpack the Extend installation package
for egz in ${Exdir}/*.tar.gz
do
  tar zxf $egz
done

#####   Dependent environment install ####
cd $openssl && \
./config -fPIC --prefix=/usr/local/openssl enable-shared && \
mv /usr/bin/pod2man /usr/bin/pod2man_bak 
make && make install 

#####git clone https://github.com/tatsuhiro-t/nghttp2.git
cd $nghttp2 && \
autoreconf -i && automake && autoconf
./configure --prefix=/usr/local/nghttp2 && \
make && make install 

cd $curl && \
env LDFLAGS=-R/usr/local/openssl/lib
echo "/usr/local/nghttp2/lib" > /etc/ld.so.conf.d/nghttp2.conf
ldconfig
./configure --prefix=/usr/local/curl --with-nghttp2=/usr/local/nghttp2 --with-ssl=/usr/local/openssl && \
make && make install
/usr/bin/mv /usr/bin/curl /usr/bin/curl_bak
/usr/bin/ln -s /usr/local/curl/bin/curl /usr/bin/curl
/usr/bin/ln -s /usr/local/openssl/lib/libssl.so.1.0.0 /usr/lib64/libssl.so.1.0.0
/usr/bin/ln -s /usr/local/openssl/lib/libcrypto.so.1.0.0 /usr/lib64/libcrypto.so.1.0.0

cd $libiconv && \
./configure --prefix=/usr/local/libiconv && \
sed -i 698d srclib/stdio.in.h
make && make install 

cd $libxml2 && \
sed -i 17035d configure
./configure --prefix=/usr/local/libxml2 && \
make && make install

cd $libxslt && \
sed -i 15644d configure
./configure --prefix=/usr/local/libxslt --with-libxml-prefix=/usr/local/libxml2 && \
make && make install

cd $libmcrypt && \
./configure && make && make install

cd $jpeg
./configure --prefix=/usr/local/jpeg9 --enable-shared --enable-static && \
make && make install

cd $zlib && \
./configure && \
make && make install

cd $libpng && \
cp scripts/makefile.linux makefile>./configure
./configure && \
make && make install

cd $freetype
./configure --prefix=/usr/local/freetype && \
make && make install

cd $fontconfig 
export PKG_CONFIG_PATH=/usr/local/freetype/lib/pkgconfig:$PKG_CONFIG_PATH
export PKG_CONFIG_PATH=/usr/local/libxml2/lib/pkgconfig:$PKG_CONFIG_PATH
./configure --prefix=/usr/local/fontconfig --with-libiconv=/usr/local/libiconv -enable-libxml2 && \
make && make install

cd $gd 
./configure --prefix=/usr/local/gd --with-jpeg=/usr/local/jpeg9 --with-png --with-freetype=/usr/local/freetype --with-fontconfig=/usr/local/fontconfig && \
make && make install 

cd $gd2 
cmake . 
make && make install

cd $pcre
./configure && make && make install

cd $libevent
./configure && make && make install 

cd $mhash
./configure && make && make install && \
ln -s /usr/local/lib/libmhash.a /usr/lib64/libmhash.a
ln -s /usr/local/lib/libmhash.la /usr/lib64/libmhash.la
ln -s /usr/local/lib/libmhash.so /usr/lib64/libmhash.so
ln -s /usr/local/lib/libmhash.so.2 /usr/lib64/libmhash.so.2
ln -s /usr/local/lib/libmhash.so.2.0.1 /usr/lib64/libmhash.so.2.0.1

cd $libunwind
./configure CFLAGS=-fPIC
make CFLAGS=-fPIC
make CFLAGS=-fPIC install

cd $gperftools
./configure --enable-frame-pointers
make && make install
echo -e "/usr/local/lib" > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig

#### PHP install ###
cd $php7
./configure --prefix=/usr/local/php \
--with-config-file-path=/usr/local/php/etc --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
--with-iconv --with-freetype-dir=/usr/local/freetype --with-jpeg-dir=/usr/local/jpeg9 \
--with-png-dir=/usr/local/lib --with-zlib-dir=/usr/local/lib \
--with-libxml-dir=/usr/local/libxml2 \
--with-curl=/usr/local/curl/ --with-mcrypt \
--with-gd --with-openssl=/usr/local/openssl --with-mhash \
--with-xmlrpc --with-xsl=/usr/local/libxslt --enable-xml --enable-bcmath \
--enable-shmop --enable-sysvsem --enable-inline-optimization --enable-mbregex \
--enable-fpm --enable-mbstring --enable-pcntl --enable-sockets --enable-zip --enable-debug \
--enable-ftp --enable-soap --enable-exif --enable-opcache
make && make install
cp ${php7}/php.ini-production ${cfile}/php.ini
ln -s ${basedir}/bin/php /usr/bin/
ln -s ${basedir}/bin/php-config /usr/bin/
ln -s ${basedir}/bin/phpize /usr/bin/
ln -s ${basedir}/etc/php.ini /etc/
cp ${cfile}/php-fpm.conf.default ${cfile}/php-fpm.conf
#cp -r ${php7}/sapi/fpm/init.d.php-fpm.in /etc/init.d/php-fpm
cp ${cfile}/php-fpm.d/www.conf.default ${cfile}/php-fpm.d/www.conf
sed -i 's/user = nobody/user = apache/g' ${cfile}/php-fpm.d/www.conf
sed -i 's/group = nobody/group = apache/g' ${cfile}/php-fpm.d/www.conf
sed -i 's#listen = 127.0.0.1:9000#listen = 0.0.0.0:9000#g' ${cfile}/php-fpm.d/www.conf
sed -i 's/;daemonize = yes/daemonize = no/g' /usr/local/php/etc/php-fpm.conf

################  PHP Extend install ####

## PHP redis install
cd $phpredis
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install

##PHP mamcache install
cd $libmemcache
./configure --prefix=/usr/local/libmemcached
make && make install

cd $phpmemcache
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config \
--with-libmemcached-dir=/usr/local/libmemcached
make && make install

###Install mongo-php-driver 
# git clone https://github.com/mongodb/mongo-php-driver
# Need to execute this command after download
# cd mongo-php-driver && git submodule update --init
# Since it has been initialized and packaged, there is no need to perform the above operations
cd $phpmongo
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install 

### PHP ssdb install
cd $phpssdb
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install

### Runkit7 
##git clone https://github.com/runkit7/runkit7.git
cd $runkit7
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install

### swoole 
cd $swoole
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install

### GeoIP
cd ${Exdir} && mv GeoLiteCity.dat /usr/share/GeoIP/ && \
ln -s /usr/share/GeoIP/GeoLiteCity.dat /usr/share/GeoIP/GeoIPCity.dat
cd $geoip
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config --with-geoip
make && make install

### Add extenssion ###
Phpini=/etc/php.ini
echo -e "extension=redis.so" >> $Phpini
echo -e "extension=memcached.so" >> $Phpini
echo -e "extension=ssdb.so" >> $Phpini
echo -e "extension=mongodb.so" >> $Phpini
echo -e "extension=runkit.so" >> $Phpini
echo -e "extension=swoole.so" >> $Phpini
echo -e "extension=geoip.so" >> $Phpini
