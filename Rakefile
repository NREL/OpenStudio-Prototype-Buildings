require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['create_DOE_prototype_building/resources/Prototype*.rb', 'create_DOE_prototype_building/resources/Standards*.rb']   # optional
  #t.options = ['--hide-api private']
  #t.stats_options = ['--list-undoc']
end

require 'rubocop/rake_task'
desc 'Run RuboCop on the lib directory'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['--no-color', '--out=rubocop-results.xml']
  task.formatters = ['RuboCop::Formatter::CheckstyleFormatter']
  task.requires = ['rubocop/formatter/checkstyle_formatter']
  # don't abort rake on failure
  task.fail_on_error = false
end
