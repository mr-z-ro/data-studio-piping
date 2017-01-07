require 'commander'
require 'byebug'
require 'net/sftp'
require 'colorize'
require 'whirly'
require 'ruby-progressbar'
require 'mysql2'
require 'net/ssh/gateway'


BACKUP_FILE_LOCATION = '/home/openair/'.freeze
BACKUP_FILE_PREFIX = 'openair_'.freeze

DOWNLOADED_FILE_NAME = 'tempfile'.freeze

MB_DIVISOR = 1_048_576

Whirly.configure spinner: 'dots'

class Shuttle
  include Commander::Methods

  @mysql = nil
  @mysql_client = nil

  @ssh = nil
  @ssh_client = nil

  @port = nil
  @ftp_object = nil

  @host = nil
  @username = nil
  @password = nil

  @production = nil

  def initialize(opts={})
    @mysql = { host: nil, username: nil, password: nil }
    @ssh = { host: nil, username: nil, password: nil }
    @production = false
  end

  def run
    program :name, 'Shuttle'
    program :version, '0.1.0'
    program :description, 'A tool to migrate backups for Tempus Fuget.'

    global_option('-p', '--production', 'Flag to use production databases. Default is localhost for MYSQL otherwise.')

    command :download do |c|
      c.syntax = 'shuttle download [options]'
      c.description = 'Download the backup file from the given host.'
      c.option '--host STRING', String, 'SFTP host to connect to.'
      c.option '-u STRING', String, 'Username for host.'
      c.option '-p STRING', String, 'Password for user. (empty if using a key)'

      c.action do |args, options|
        @production = options.production

        error 'Missing ' + '--host'.yellow + ' option' if options.host.nil?
        error 'Missing ' + '-u'.yellow + ' (username) option' if options.u.nil?

        @host = options.host
        @username = options.u
        @password = options.p

        download_backup
      end
    end

    command :testmysql do |c|
      c.syntax = 'shuttle testmysql [options]'
      c.description = 'Test an SSH tunnel and the MYSQL connection.'
      c.option '--host STRING', String, 'SSH host to connect to.'
      c.option '-u STRING', String, 'Username for ssh host.'
      c.option '-p STRING', String, 'Password for ssh user. (empty if using a key)'
      c.option '--mysql_host STRING', String, 'Host for mysql.'
      c.option '--mysql_u STRING', String, 'Username for mysql user.'
      c.option '--mysql_p STRING', String, 'Password for mysql user.'

      c.action do |args, options|
        @production = options.production

        error 'Missing ' + '--host'.yellow + ' option' if options.host.nil?
        error 'Missing ' + '-u'.yellow + ' (username) option' if options.u.nil?
        if options.production
          error 'Missing ' + '--mysql_host'.yellow + ' option' if options.mysql_host.nil?
          error 'Missing ' + '--mysql_u'.yellow + ' option' if options.mysql_u.nil?
          error 'Missing ' + '--mysql_p'.yellow + ' option' if options.mysql_p.nil?

          error 'Missing ' + '--host'.yellow + ' option' if options.host.nil?
          error 'Missing ' + '-u'.yellow + ' (username) option' if options.u.nil?

          @host = options.host
          @username = options.u
          @password = options.p

          @mysql[:host] = options.mysql_host
          @mysql[:username] = options.mysql_u
          @mysql[:password] = options.mysql_p
        else
          @mysql[:host] = '127.0.0.1'
          @mysql[:username] = 'root'
          @mysql[:password] = 'root'
        end

        @host = options.host
        @username = options.u
        @password = options.p

        # create_database 'test', options.production
        move_database 'openair', 'openair_old'

      end
    end

    command :testssh do |c|
      c.syntax = 'shuttle testssh [options]'
      c.description = 'Test an SSH connection.'
      c.option '--host STRING', String, 'SSH host to connect to.'
      c.option '-u STRING', String, 'Username for ssh host.'
      c.option '-p STRING', String, 'Password for ssh user. (empty if using a key)'
      c.action do |args, options|
        @production = options.production

        error 'Missing ' + '--host'.yellow + ' option' if options.host.nil?
        error 'Missing ' + '-u'.yellow + ' (username) option' if options.u.nil?
        # if options.production
        # else
        # end

        @host = options.host
        @username = options.u
        @password = options.p

        installed = check_if_mysql_is_installed

        success 'SSH is working properly' if installed
        error 'SSH is not correctly connecting or mysql is not installed' unless installed
      end
    end

    command :run do |c|
      c.syntax = 'shuttle run [options]'
      c.description = 'Run full lifecycle.'
      c.option '--host STRING', String, 'SSH host to connect to.'
      c.option '-u STRING', String, 'Username for ssh host.'
      c.option '-p STRING', String, 'Password for ssh user. (empty if using a key)'
      c.option '--mysql_host STRING', String, 'Host for mysql.'
      c.option '--mysql_u STRING', String, 'Username for mysql user.'
      c.option '--mysql_p STRING', String, 'Password for mysql user.'

      c.action do |args, options|
        @production = options.production

        if options.production
          error 'Missing ' + '--mysql_host'.yellow + ' option' if options.mysql_host.nil?
          error 'Missing ' + '--mysql_u'.yellow + ' option' if options.mysql_u.nil?
          error 'Missing ' + '--mysql_p'.yellow + ' option' if options.mysql_p.nil?

          error 'Missing ' + '--host'.yellow + ' option' if options.host.nil?
          error 'Missing ' + '-u'.yellow + ' (username) option' if options.u.nil?

          @mysql[:host] = options.mysql_host
          @mysql[:username] = options.mysql_u
          @mysql[:password] = options.mysql_p
        else
          @mysql[:host] = '127.0.0.1'
          @mysql[:username] = 'root'
          @mysql[:password] = 'root'
        end

        @host = options.host
        @username = options.u
        @password = options.p

        # create_database 'test', options.production
        download_backup
        create_database 'openair_new'
        import_mysql_backup "./#{DOWNLOADED_FILE_NAME}", 'openair_new'
        # Run commands against openair_new
        create_database 'openair_old'
        move_database 'openair', 'openair_old'
        move_database 'openair_new', 'openair'

      end
    end

    run!

    # Just in case it's left open
    close_ftp_object
  end

  # Steps needed
  # 1. Download backup from ftp server - 💥
  # 2. Import SQL backup to MYSQL server in _new database
  # 3. Run SQL commands against _new database
  # 4. Rename original database to _old
  # 5. Rename _new to original names

  def download_backup
    file = check_if_backup_exists
    error 'Backup file not found on FTP server.' if file.nil?

    final_location = "./#{DOWNLOADED_FILE_NAME}.zip"
    download_file(file, final_location)
    unzip_file final_location
  end

  def unzip_file(filename)
    # I have no idea if this'll work on *nix boxes, but it works on MacOS
    result = nil
    filename = File.basename("./#{filename}", '.zip') if filename.include? '.zip'
    Whirly.start status: 'Unzipping backup file'.green do
      result = `unzip -o #{filename}.zip -d #{filename}`
    end

    error "Cannot find or open file #{filname}" if result.include? 'cannot find'
    success 'Successfully unzipped backup file'
  end

  def check_if_backup_exists
    file_exists = nil
    ftp_object_temp = ftp_object
    Whirly.start status: 'Checking if backup file exists'.green do
      files = ftp_object_temp.dir.entries(BACKUP_FILE_LOCATION).keep_if { |e| e.name =~/^(openair_)[\d-]+.zip$/}
      file_exists = files[0]
    end

    file_exists
  end

  #
  # FTP Management
  #

  def connect_to_ftp(host, username, password)
    # TODO: This is a stub, needs to actually be sftp
    ftp = nil
    Whirly.start status: 'Connecting to FTP server...'.green do
      ftp = Net::SFTP.start(host, username, password: password)
    end

    say 'Connected to FTP server '.green + '‎️‍🌈'
    ftp
  end

  def download_file(file, final_location)
    size = file.attributes.size / MB_DIVISOR
    name = BACKUP_FILE_LOCATION + file.name
    say 'Downloading ' + file.name.yellow + ' size: ' + "#{size}MB".blue

    progress_format = '%e %P%% ⬇️ %B Downloaded: %c of %C bytes'
    progressbar = ProgressBar::ProgressBar.create format: progress_format, total: file.attributes.size

    ftp_object.download!(name, final_location) do |event, _, *args|
      case event
      when :get then
        progressbar.progress += args[2].length
      when :finish then
        puts 'Backup file downloaded 📜'
      end
    end
  end

  def ftp_object
    error 'No FTP host indicated' if @host.nil?

    @ftp_object = connect_to_ftp @host, @username, @password if @ftp_object.nil?
    @ftp_object
  end

  def close_ftp_object
    @ftp_object.close(nil) unless @ftp_object.nil?
  end

  #
  # SSH Management
  #

  def connect_to_ssh(host, username)
    ssh = nil
    Whirly.start status: "Connecting to #{host} via ssh...".green do
      begin
          ssh = Net::SSH.start(host, username)
        rescue
          error "Unable to connect to #{host} using #{username}"
        end
    end

    say "Connected to #{host} server ".green + '‎️‍🌈'
    ssh
  end

  def connect_to_ssh_tunnel(host, tunnel_host, username)
    gateway = Net::SSH::Gateway.new(host, username)
    port = gateway.open(tunnel_host, 3306, 3307)
    port
  end

  #
  # MYSQL Management
  #

  def connect_to_mysql(host, username, password, db_name, port)
    client = Mysql2::Client.new(
      host: host,
      username: username,
      password: password,
      database: db_name,
      port: port
    )
    client
  end

  def close_mysql(client)
    client.close
  end

  def connect_to_db(db_name); end

  def create_database(db_name)
    run_sql_command("CREATE DATABASE #{db_name}", true)
  end

  def delete_database(db_name); end

  def check_if_mysql_is_installed
    results = @production ? ssh_client.exec!('mysql -V') : `mysql -V`
    return false if results.include?'command not found'
    true
  end

  def move_database(from, to)
    create_database(to)

    tables = tables_in_db from

    tables.each do |table|
      run_sql_command("RENAME TABLE #{from}.#{table} TO #{to}.#{table};")
    end
  end

  def tables_in_db(db)
    command = "SHOW TABLES FROM #{db};"
    tables = run_sql_command(command)
    tables.collect { |table| table.values.first }
  end

  def import_mysql_backup(directory, db_name)
    error 'Cannot find directory to import MYSQL from' unless Dir.exist?(directory)

    import_mysql_backup_file "#{directory}/mysql.sql", db_name
    import_mysql_backup_file "#{directory}/mysql_1.sql", db_name
  end

  def import_mysql_backup_file(file, db_name)
    # NOTE: You have to disable STRICT_TRANS_TABLES.
    # I do that in the docker container with `mysqld --sql_mode=""`
    # But you should figure it out yourself for your setup
    # https://stackoverflow.com/questions/36374335/error-in-mysql-when-setting-default-value-for-date-or-datetime/36374690#36374690

    error 'Cannot find file #{file}' unless File.exist?(file)
    Whirly.start status: "Importing #{file}".green do
      `mysql --host #{@mysql[:host]} --user #{@mysql[:username]} -p#{@mysql[:password]} #{db_name} < #{file} --force`
    end
    say "#{file} successfully imported into #{db_name}"
  end

  def run_sql_commands; end

  def run_sql_command(command, continue_on_error = false)
    begin
      mysql_client.query(command)
    rescue => exception
      error exception.to_s, continue_on_error
      throw exception unless continue_on_error
    end
  end

  def mysql_client(production = @production)
    return @mysql_client unless @mysql_client.nil?

    @port = production ? connect_to_ssh_tunnel(@host, @mysql[:host], @username) : '3306'
    error '"mysql" must be installed on server for script to work' unless check_if_mysql_is_installed
    @mysql_client = connect_to_mysql('127.0.0.1', @mysql[:username], @mysql[:password], nil, @port)
    @mysql_client
  end

  def ssh_client(production = @production)
    return @ssh_client unless @ssh_client.nil?

    @ssh_client = connect_to_ssh(@host, @username)
    @ssh_client
  end

  def error(message, continue = false)
    spacing = '     '
    say '------------------------------------------------------------'.red
    say spacing + '💥Error💥'.red
    say spacing + message if message.is_a? String
    message.each { |line| say spacing + line } if message.is_a? Array
    say '------------------------------------------------------------'.red
    exit unless continue
  end

  def success(message, continue = true)
    spacing = '     '
    say '------------------------------------------------------------'.green
    say spacing + '✨Success✨'.green
    say spacing + message if message.is_a? String
    message.each { |line| say spacing + line } if message.is_a? Array
    say '------------------------------------------------------------'.green
    exit unless continue
  end

end

Shuttle.new.run if $0 == __FILE__
