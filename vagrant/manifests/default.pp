Exec {
  path => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin'],
}

class { 'apt':
   proxy_host => "10.0.3.1",
   proxy_port => "3128",
}

# Instlal Subgit
# ==============

exec { "download subgit":
  command => "wget http://subgit.com/download/subgit_2.0.0_all.deb",
  cwd => '/tmp',
  creates => '/tmp/subgit_2.0.0_all.deb',
  environment => [ "HTTP_PROXY=http://10.0.3.1:3128", "http_proxy=http://10.0.3.1:3128" ],
  unless => 'dpkg -s subgit',
}

package { 'subgit' :
  ensure => installed,
  provider => dpkg,
  source => '/tmp/subgit_2.0.0_all.deb',
  require => Exec['download subgit'],
}

# Install Java
# ============

package { 'openjdk-7-jre' : }

# Install gitlab
# ==============

host { 'gitlab.sandcastle':
    ip => '10.0.3.234',
}

include gitlab
