class gitlab {

  # Dependencies
  # ============

  package { 'sudo' : }

  package { 'vim' : }

  package { 'build-essential' : }
  package { 'zlib1g-dev' : }
  package { 'libyaml-dev' : }
  package { 'libssl-dev' : }
  package { 'libgdbm-dev' : }
  package { 'libreadline-dev' : }
  package { 'libncurses5-dev' : }
  package { 'libffi-dev' : }
  package { 'curl' : }
  package { 'openssh-server' : }
  package { 'redis-server' : }
  package { 'checkinstall' : }
  package { 'libxml2-dev' : }
  package { 'libxslt-dev' : }
  package { 'libcurl4-openssl-dev' : }
  package { 'libicu-dev' : }
  package { 'logrotate' : }

  package { 'python2.7' : }
  package { 'python-docutils' : }

  package { 'postfix' : }

  # Ruby
  # ====

  package { 'ruby' : }
  package { 'ruby-dev' : }
  package { 'rubygems' : }

  exec { 'install bundler' :
    command => "gem install --http-proxy http://10.0.3.1:3128 bundler",
    require => Package['rubygems'],
    unless => 'gem list bundler -i',
  }

  # System Users
  # ============

  file { '/home/git' :
    owner => 'git',
    group => 'git',
  }

  user { 'git' :
    comment => 'GitLab',
    home => '/home/git',
  }

  # GitLab Shell
  # ============

  file { '/home/git/gitlab-shell' : 
    owner => 'git',
    group => 'git',
    recurse => true,
  }

  file { '/home/git/gitlab-shell/config.yml' :
    source => 'puppet:///modules/gitlab/config.yml',
  }

  exec { '/home/git/gitlab-shell/bin/install' :
    user => 'git',
    creates => '/home/git/repositories',
  }

  # Database
  # ========

  class { '::mysql::server' : }

  package { 'libmysqlclient-dev' : }

  mysql::db { 'gitlabhq_production':
    user     => 'gitlab',
    password => 'password',
    host     => 'localhost',
    grant    => [
      'SELECT',
      'LOCK TABLES',
      'INSERT',
      'UPDATE',
      'DELETE',
      'CREATE',
      'DROP',
      'INDEX',
      'ALTER',
    ],
  }

  # GitLab
  # ======

  # Source
  # ------

  file { '/home/git/gitlab' : 
    owner => 'git',
    group => 'git',
    recurse => true,
  }

  # Configuration
  # -------------

  file { '/home/git/gitlab/config/gitlab.yml' : 
    source => 'puppet:///modules/gitlab/gitlab.yml',
  }

  file { '/home/git/gitlab/log' :
    owner => 'git',
    mode => 'u+rwX',
    recurse => true,
  }

  file { '/home/git/gitlab/tmp' :
    owner => 'git',
    mode => 'u+rwX',
    recurse => true,
  }

  file { '/home/git/gitlab-satellites' : 
    ensure => 'directory',
    owner => 'git',
  }

  file { '/home/git/gitlab/tmp/pids' : 
    ensure => directory,
    owner => 'git',
    mode => 'u+rwX',
    recurse => true,
  }

  file { '/home/git/gitlab/tmp/sockets' : 
    ensure => directory,
    owner => 'git',
    mode => 'u+rwX',
    recurse => true,
  }

  file { '/home/git/gitlab/public/uploads' : 
    ensure => directory,
    owner => 'git',
    mode => 'u+rwX',
    recurse => true,
  }

  file { '/home/git/gitlab/config/unicorn.rb' : 
    source => 'puppet:///modules/gitlab/unicorn.rb',
  }

  file { '/home/git/gitlab/config/initializers/rack_attack.rb' : 
    source => 'puppet:///modules/gitlab/rack_attack.rb',
  }

  file { '/home/git/.gitconfig' : 
    source => 'puppet:///modules/gitlab/.gitconfig',
  }

  # Configure Database
  # ------------------

  file { '/home/git/gitlab/config/database.yml' : 
    source => 'puppet:///modules/gitlab/database.yml',
  }

  # Install Gems
  # ------------

  exec { 'charlock holmes' :
    command => "gem install --http-proxy http://10.0.3.1:3128 charlock_holmes --version '0.6.9.4'",
    cwd => '/home/git/gitlab',
    require => Package['rubygems', 'ruby-dev'],
    unless => 'gem list charlock_holmes -i',
  }

  exec { "bundle install gitlab" :
    command => 'bundle install --deployment --without development test postgres aws',
    cwd => '/home/git/gitlab',
    unless => 'bundle check',
    require => [Exec['install bundler'], Package['libmysqlclient-dev']],
    environment => ["HOME='/home/git'", "http_proxy=http://10.0.3.1:3128"],
    timeout => 600, # This can take a little while
    logoutput => true,
  }

  # Install Init Script
  # -------------------

  file { '/etc/init.d/gitlab' : 
    source => '/home/git/gitlab/lib/support/init.d/gitlab',
    mode => '+x',
  }

  service { 'gitlab' :
    enable => true,
    require => File['/etc/init.d/gitlab'],
  }

  # Set up Logrotate
  # ----------------

  file { '/etc/logrotate.d/gitlab' :
    source => '/home/git/gitlab/lib/support/logrotate/gitlab',
  }

  # NginX
  # =====

  package { 'nginx' : }

  service { "nginx" :
    ensure => running,
  }

  file { '/etc/nginx/sites-available/gitlab' :
    source => 'puppet:///modules/gitlab/gitlab',
    require => Package['nginx'],
  }

  file { '/etc/nginx/sites-enabled/gitlab' :
    ensure => 'link',
    target => '/etc/nginx/sites-available/gitlab',
   require => [Package['nginx'], File['/etc/nginx/sites-available/gitlab']],
    notify => Service['nginx'],
  }

}
