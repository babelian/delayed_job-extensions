Gem::Specification.new do |s|
  s.name = 'delayed_job-extensions'
  s.version = '0.0.0'
  s.require_paths = ['lib']
  s.authors = ['Zachary Powell']
  s.date = '2019-05-01'
  s.email = 'zach@babelian.net'
  s.files = Dir.glob('{lib}/**/*')
  s.homepage = 'http://github.com/babelian/delayed_job-extensions'
  s.rubygems_version = '3.0.1'
  s.summary = 'Extensions for delayed_job and delayed_job_active_record'

  s.add_runtime_dependency 'delayed_job', '4.1.5'
  s.add_runtime_dependency 'delayed_job_active_record', '4.1.3'

  s.add_development_dependency 'bump'
end
