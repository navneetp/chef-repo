name             'my_cookbook'
maintainer       'GSLab Pvt. Ltd.'
maintainer_email 'navneetp@gmail.com'
license          'All rights reserved'
description      'Installs/Configures my_cookbook'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "apache2"
depends "mysql"
depends "tomcat"
