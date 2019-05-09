Gem::Specification.new do |s|
  s.name = 'delayed_job-extensions'
  s.version = '0.0.0'

  s.authors = 'Zachary Powell'
  s.email = 'zach@babelian.net'
  s.homepage = 'http://github.com/babelian/delayed_job-extensions'
  s.license = 'MIT'
  s.summary = 'Extensions for delayed_job and delayed_job_active_record'

  s.files = Dir.glob('{lib}/**/*')
  s.extra_rdoc_files = ['LICENSE', 'README.md']
  s.require_paths = %w[lib]
  s.required_ruby_version = '>= 2.6.0'
  s.rubygems_version = '3.0.1'

  s.add_runtime_dependency 'delayed_job', '4.1.5'
  s.add_runtime_dependency 'delayed_job_active_record', '4.1.3'

  s.add_development_dependency 'rspec', '3.8.0'
end