class mysql::instance (
	$ensure			= present,
)	
 {
    package { "mysql-server":
    	ensure		=> installed,
		require     => [File["${base::dbroot}/mysql"],
						File["${base::logroot}/mysql"],
						File["${base::dbroot}/mysql"],
						File['/var/lib/mysql']
						]
    }

    package {"mysql-devel":
		ensure	=> installed,
	}
    
    service { "mysqld":
        ensure      => running,
        enable      => true,
        hasrestart  => true,
        hasstatus   => true,
		require		=> [ File['/var/lib/mysql'],
						 User['mysql'],
						 Package['mysql-server'],
						]
    }

    user { 'mysql':
	    home    => '/home/mysql',
	    ensure  => present,
    }

    user { 'mysqldump':
	    home    => '/home/mysql',
	    ensure  => present,
    }

	file {'/var/lib/mysql':
		ensure	=> link,
		target	=> "${base::dbroot}/mysql",
		require	=> File["${base::dbroot}/mysql"],
		force	=> true,
	}

	file {"${base::dbroot}/mysql":
	     ensure	=> directory,
	}

	file {'/var/log/mysql':
		ensure	=> link,
		target	=> "${base::logroot}/mysql",
		require	=> File["${base::logroot}/mysql"],
		force	=> true,
	}

	file {"${base::logroot}/mysql":
		ensure	=> directory,
		owner 	=> 'mysql',
		group 	=> 'mysql',
	}


	file { "/cul/bin/new_mysql_dba":
        ensure => file,
        source => "puppet:///modules/mysql/new_mysql_dba",
        mode   => 0755
    }
}

class mysql::instance::init {

	include mysql::instance
	
	file { "/cul/bin/mysql_initial_setup":
		ensure => file,
		source => "puppet:///modules/mysql/mysql_initial_setup",
		mode   => 0755,
		replace => false
	}

	file {'/cul/bin/mysqlbackup.sh':
		ensure		=> file,
		source		=> "puppet:///modules/mysql/mysqlbackup.sh",
		mode		=> '0770',
    	owner		=> 'root',
    	group 		=> 'mysqldump',
		replace		=> 'true',
	}

	file {'/etc/cron.daily/mysqldump':
		ensure		=> file,
		content		=> "/cul/bin/mysqlbackup.sh",
		mode		=> '0111',
		owner		=> 'root',
		group		=> 'root',
		require		=> File['/cul/bin/mysqlbackup.sh'],
	}

	file {"${base::culbackup}/mysql":
		ensure		=> directory,
		mode		=> '0775',
		owner		=> 'root',
		group		=> 'mysqldump',
	}

    file {'/usr/local/dbbackup':
            ensure  => link,  
            target	=>  "${base::culbackup}/mysql",                                                                                                                
                owner   => root,                                                                                                                        
                group   => root,                                                                                                                        
                mode    => 755,                                                                                                                         
                require => File["${base::culbackup}/mysql"]
	}

exec { 'mysql_initial_setup':
            command => "${base::culbin}/mysql_initial_setup ${base::dbroot}/mysql",
            creates  => '/root/.my.cnf',
            require => [ Package['apg'],
                         Package['mysql-server'],
                         File['/cul/bin/mysql_initial_setup'],
                       ]
        }

}