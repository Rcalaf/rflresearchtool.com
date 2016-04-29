require "bundler/capistrano" 
#require "whenever/capistrano"
load 'deploy/assets'



ENV['RAILS_ENV'] ||= 'production'

### 
# SSH settings

## New server
set :server_ip, "91.121.65.49"


default_run_options[:pty] = true
set :ssh_options, {:forward_agent => true}
set :user, "deploy"

###
# Deploy settings
#

set :application, "ikea.rogercalaf.com"
set :local_app, "ikea.com"
set :deploy_to, "/home/#{user}/#{application}"

### 
# Git settings
#
set :scm, :git
set :repository,  "."  #point to github CLONE URL.
set :copy_strategy, :export
set :copy_compression, :gzip
set :deploy_via, :copy



###
# BBDD settings
#

set :db_passwd, "wL8XSPha"
set :db_name, "ikea_com_production"

role :app, server_ip
role :web, server_ip
role :db,  server_ip, :primary => true

set :use_sudo, false

# **ATTENTION** After the first deploy create “/var/www/my_app/shared/log” folder for toubleshooting
#create a Task for this issue above.

#Cleaner reaper error on cap deploy:restart & deploy. Those tries to restart mongrel clusters thorught a pool of scripts called spinners. 
#Now we restart passenger so we deploy over Phussion passenger instead
deploy.task :restart, :roles => :app do
  run "touch #{current_path}/tmp/restart.txt"
end

##
# Setup mantenance options, upload conf, remove conf, etc..
#

namespace :maintenance do 
  
  desc "Deploy maintenance folder and Virtual Host."
  task :setup, :roles => :web do
    system "tar -czvf #{application}_maintenance.tgz maintenance/"
    system "scp #{application}_maintenance.tgz #{user}@#{server_ip}:~/"
    system "rm #{application}_maintenance.tgz"
    run "tar -xvf #{application}_maintenance.tgz"
    run "mv maintenance #{application}_maintenance"
    run "rm #{application}_maintenance.tgz"
    system "scp config/apache/maintenance.conf root@#{server_ip}:/etc/apache2/sites-available/#{application}.maintenance"
  end
  
  desc "Shuts down the App and start maintenance page."
  task :enable, :roles => :web do 
    system "ssh root@#{server_ip} a2ensite #{application}.maintenance"
    apache.disable
  end
  
  desc "Starts App and shuts down maintenance page."
  task :disable, :roles => :web do 
    system "ssh root@#{server_ip} a2dissite #{application}.maintenance"
    apache.enable
  end

  desc "Destroy and re-deploy maintenance config and folder."
  task :update, :roles => :web do
    clean
    setup
  end
  
  desc "Delete App_maintenance folder"
  task :clean, :roles => :web do 
    disable
    system "ssh root@#{server_ip} rm /etc/apache2/sites-available/#{application}.maintenance"
    run "rm -rf ~/#{application}_maintenance"
  end

end


###
# Site Backup, Db dump, system folder, etc..
#
namespace :backup do
  
  desc "Setup all needed to backup"
  task :setup, :roles => :app do 
    system "mkdir ~/Sites/#{local_app}/backups"   
  end
  
  #desc "Compress the current release."
  task :compress_current_folder, :roles => :app do 
    run "tar czvf ~/#{application}_current.tgz  #{latest_release}"
  end
  
  desc "Download the current release."
  task :current_folder, :roles => :app do 
    compress_current_folder 
    system "scp #{user}@#{server_ip}:~/#{application}_current.tgz ~/Sites/#{local_app}/backups/"+Time.now.strftime("%Y%m%d")+"_current.tgz"
    run "rm ~/#{application}_current.tgz"
  end
  
  #desc "Compress and download the System folder"
  task :compress_system_folder, :roles => :app do 
    run "tar czvf ~/#{application}_system.tgz ~/#{application}/shared/system"
  end
  
  desc "Download the System folder"
  task :system_folder, :roles => :app do 
    compress_system_folder
    system "scp #{user}@#{server_ip}:~/#{application}_system.tgz ~/Sites/#{local_app}/backups/"+Time.now.strftime("%Y%m%d")+"_system.tgz"
    run "rm ~/#{application}_system.tgz"
  end
  
  #desc "Makes a DB dump."
  task :db_dump, :roles => :db do 
    run "mysqldump -u root -p #{db_passwd} #{db_name} > ~/#{db_name}_dump.sql"
  end
  
  desc "Download the latest DB dump."
  task :db, :roles => :db do 
    db_dump
    system "scp #{user}@#{server_ip}:~/#{db_name}_dump.sql ~/Sites/#{local_app}/backups/"+Time.now.strftime("%Y%m%d")+"_db.sql"
    run "rm ~/#{db_name}_dump.sql"
  end
  
  desc "Download a complete backup of the aplication."
  task :all, :roles => :app do
    db
    current_folder
    system_folder
  end
end

namespace :deploy do
  desc "Migrate the DB"
  task :seed, :roles => :db do
    run "cd #{current_path}; rake db:seed RAILS_ENV='production'"
  end
end

namespace :apache do

  desc "Move App VirtualHost.conf to available-sites"
  task :configure, :roles => :web do
    system "scp config/apache/site.conf root@#{server_ip}:/etc/apache2/sites-available/#{application}"
    modules
  end

  desc "Enable Rewrite Modules"
  task :modules, :roles => :web do
    system "ssh root@#{server_ip} a2enmod rewrite"
  end

  desc "Enable site & restart Apache"
  task :enable, :roles => :web do
    system "ssh root@#{server_ip} a2ensite #{application}"
    reload
  end

  desc "Disable site & restart Apache"
  task :disable, :roles => :web do
    system "ssh root@#{server_ip} a2dissite #{application}"
    reload
  end
  
  desc "List enabled Apache sites"
  task :enabled_sites_list, :roles => :web do
    run "ls /etc/apache2/sites-enabled"
  end

  desc "List available Apache sites"
  task :available_sites_list, :roles => :web do
    run "ls /etc/apache2/sites-available"
  end

  desc "Start Apache"
  task :start, :roles => :web do
    system "ssh root@#{server_ip} /etc/init.d/apache2 start > /dev/null"
  end

  desc "Stop Apache"
  task :stop, :roles => :web do
    system "ssh root@#{server_ip} /etc/init.d/apache2 stop > /dev/null"
  end

  desc "Restart Apache"
  task :restart, :roles => :web do
    system "ssh root@#{server_ip} /etc/init.d/apache2 restart > /dev/null"
  end

  desc "Reload Apache"
  task :reload, :roles => :web do
    system "ssh root@#{server_ip} /etc/init.d/apache2 reload > /dev/null"
  end

  desc "Force Reload Apache"
  task :force_reload, :roles => :web do
    system "ssh root@#{server_ip} /etc/init.d/apache2 force-reload > /dev/null"
  end

end

 


