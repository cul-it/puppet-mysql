class cul_db::postgresql::instance(
  $ensure     = present,
  $version    = undef,
  $datadir    = "${base::dbroot}/pgsql",
  $manage_package_repo  = true,
)
{

####### the /etc/sysconfig/pgsql resources are needed to address http://git.io/v2vc_A

  file { '/etc/sysconfig/pgsql':
    ensure => directory,
}

if $version == undef { 

  class { 'postgresql::globals':
        datadir                 => $datadir,
        version                 => $version,
  require     => File["${base::dbroot}/pgsql"],
        } 

  file { '/etc/sysconfig/pgsql/postgresql':
    content => "PGDATA=${datadir}\n",
    before  => Class['postgresql::server'],
 } 

}
  else { 

  class { 'postgresql::globals':
        datadir                 => $datadir,
        manage_package_repo     => $manage_package_repo,
        version                 => $version,
        require                 => File["${base::dbroot}/pgsql"],
        } 

  file { "/etc/sysconfig/pgsql/postgresql-${version}":
    content => "PGDATA=${datadir}\n",
    before  => Class['postgresql::server'],
 } 

  file { '/etc/sysconfig/pgsql/postgresql':
    target      => "/etc/sysconfig/pgsql/postgresql-${version}",
    before      => Class['postgresql::server'],
 } 
}

  class { 'postgresql::server':
    manage_pg_hba_conf => false,
    require            => [File['/var/lib/pgsql'],File['/var/log/pgsql']
                          ]
    } 

file {'/var/lib/pgsql':
    ensure  => link,
    target  => '/users/postgres',
    force   => true,
    }

  file {'/var/log/pgsql':
  ensure    => link,
  target    => "${base::logroot}/pgsql",
  #require   => Class['postgresql::server']

  }

if ! defined (Package['apg']) {
  package { "apg":
    ensure => installed,
    }
  }

file {"${base::logroot}/pgsql":
    ensure  => directory,
    }

file {"${base::dbroot}/pgsql/pg_hba.conf":
    ensure  => present,
    source  => "puppet:///modules/cul_db/pg_hba.conf",
    mode    => '0755',
    owner   => 'root',
    require => Class['postgresql::server'],
    }

file {"${base::culbin}/new_pgsql_dba":
    ensure  => present,
    source  => "puppet:///modules/cul_db/new_pgsql_dba",
    mode    => '0755',
    owner   => 'root',
    require => Class['postgresql::server'],
  }

file {"${base::culbin}/pgsql_initial_setup":
    ensure  => present,
    source  => "puppet:///modules/cul_db/pgsql_initial_setup",
    mode    => '0700',
    owner   => 'postgres',
    require => Class['postgresql::server'],
    replace => false,
    }

exec { 'pgsql_initial_setup':
                command => "${base::culbin}/pgsql_initial_setup",
                creates => '/users/postgres/.pgpass',
                user    => 'postgres',
                require => [ Package['apg'],
                             Class['postgresql::server'],
                             File['/cul/bin/pgsql_initial_setup'],
                           ]
        }

# postgresql::server::pg_hba_rule { 'allow postgres user access locally via ident':
#   description => "allow postgres user access locally via ident",
#   type => 'local',
#   database => 'all',
#   user => 'postgres',
#   auth_method => 'ident',
# }

# postgresql::server::pg_hba_rule { 'allow local user access locally via md5':
#   description => "allow local user access locally via md5",
#   type => 'local',
#   database => 'all',
#   user => 'postgres',
#   auth_method => 'md5',
# }

# postgresql::server::pg_hba_rule { 'allow local user network access via md5':
#   description => "allow local user network access via md5",
#   type => 'host',
#   database => 'all',
#   user => 'all',
#   address => '127.0.0.1/24',
#   auth_method => 'md5',
# }

}