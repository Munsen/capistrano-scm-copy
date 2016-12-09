namespace :copy do
  archive_name = 'archive.gz'

  # Defalut to :all roles
  tar_roles = fetch(:tar_roles, :all)
  tar_verbose = fetch(:tar_verbose, true) ? 'v' : ''

  desc "Archive files to #{archive_name}"
  file archive_name do |t|
    include_dir  = fetch(:include_dir) ||
                   Dir
                   .glob('*', File::FNM_DOTMATCH)
                   .reject { |i| i == '.' || i == '..' }
    exclude_dir  = Array(fetch(:exclude_dir)).push(archive_name)
    exclude_args = exclude_dir.map { |dir| "--exclude '#{dir}'" }

    cmd = ["tar -c#{tar_verbose}zf #{t.name}", *exclude_args, *include_dir]
    sh cmd.join(' ')
  end

  desc "Deploy #{archive_name} to release_path"
  task :release do
    delete archive_name
    Rake::Task[archive_name].execute
    tarball = archive_name

    on roles(tar_roles) do
      # Make sure the release directory exists
      puts "==> release_path: #{release_path} is created on #{tar_roles} roles <=="
      execute :mkdir, '-p', release_path

      # Create a temporary file on the server
      tmp_file = capture('mktemp')

      # Upload the archive, extract it and finally remove the tmp_file
      upload!(tarball, tmp_file)
      execute :tar, '-xzf', tmp_file, '-C', release_path
      execute :rm, tmp_file
    end
  end

  task :clean do
    # Delete the local archive
    File.delete archive_name if File.exist? archive_name
  end

  after 'deploy:finished', 'copy:clean'

  task create_release: :release
  task :check
  task :set_current_revision
end
