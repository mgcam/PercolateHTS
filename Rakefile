#--
#
# Copyright (c) 2011 Genome Research Ltd. All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rcov/rcovtask'

spec = Gem::Specification.new do |spec|
  spec.name = 'percolate_hts'
  spec.version = '0.1.0'
  spec.add_dependency('percolate', '>= 0.6.1')
  spec.extra_rdoc_files = []
  spec.summary = ''
  spec.description = ''
  spec.author = 'Keith James'
  spec.email = 'kdj@sanger.ac.uk'
  spec.executables = []
  spec.files = %w(Rakefile) + Dir.glob('{bin,spec}/**/*') +
      Dir.glob('lib/**/*.rb')
  spec.require_path = 'lib'
  spec.bindir = 'bin'
end

Rake::GemPackageTask.new(spec) do |pack|
  pack.gem_spec = spec
  pack.need_tar = true
  pack.need_zip = false
end

Rake::RDocTask.new do |rdoc|
  files =['README', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "Percolate HTS Documentation"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end

Rcov::RcovTask.new do |rcov|
  rcov.pattern = FileList['test/**/*.rb']
  rcov.output_dir = 'coverage'
  rcov.verbose = true
  rcov.rcov_opts << "--sort coverage -x 'rcov,ruby'"
end
