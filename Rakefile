task default: %w[run_server]

task :run_server do
  sh 'bundle exec ruby server.rb'
end

task :logs do
  sh 'heroku logs -s app -t'
end

