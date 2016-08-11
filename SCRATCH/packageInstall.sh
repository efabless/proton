yum install glibc
yum install libX11 libpng libjpeg libstdc++ expat
yum install perl.x86_64
yum install make.x86_64
yum install gcc.x86_64
yum install bison
yum install libxslt.x86_64
yum install perl-XML-Parser.x86_64
yum install xterm.x86_64
yum install libX11-devel.x86_64
yum install libXtst.x86_64
yum install libXtst
yum install libXtst-devel.x86_64
yum install libpng-devel libpng.x86_64
yum install libtool-ltdl.x86_64 libtool-ltdl-devel.x86_64
yum install xorg-x11-server-Xvfb.x86_64
yum install xorg-x11-apps-7.1-4.0.1.el5.x86_64
yum install vim-X11.x86_64 vim-enhanced.x86_64 vim-common.x86_64
yum install Xvfb xorg xorg-x11-font*
yum install Xorg
rpm -Uvh /apps/content/ImageMagick-6.6.8-4.x86_64.rpm
perl -MCPAN -e "install Frontier::Daemon"
perl -MCPAN -e "install Getopt::Long"
perl -MCPAN -e "install YAML"
perl -MCPAN -e "install Module::Build"
perl -MCPAN -e "install Proc::ProcessTable"
PERL_MM_USE_DEFAULT=1 perl -MCPAN -e "install Net::Amazon::S3"

tar -zxvf /apps/content/xautomation-1.03.tar.gz
cd xautomation-1.03 ; ./configure ; make ; make install


#-------------- install packages for spice -----#
yum install libtool-ltdl.x86_64
yum install autoconf
yum install libtool.x86_64 automake.noarch
yum install libXaw.x86_64 libXaw-devel.x86_64
tar -zxvf /apps/content/ngspice-22.tar.gz
cd ngspice-22 ; ./autogen.sh ; ./configure; make ; make install

