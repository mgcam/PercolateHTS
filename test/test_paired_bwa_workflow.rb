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

devpath = File.expand_path(File.join(File.dirname(__FILE__), '..'))
libpath = File.join(devpath, 'lib')
testpath = File.join(devpath, 'test')

$:.unshift(libpath) unless $:.include?(libpath)

require 'rubygems'
require 'test/unit'
require 'timeout'
require 'yaml'

require 'percolate_hts'
require File.join(testpath, 'test_helper')

class TestPairedBWA < Test::Unit::TestCase
  include PercolateHTS
  include PercolateHTS::Tasks
  include TestHelper

  def initialize(name)
    super(name)
    @msg_host = 'localhost'
    @msg_port = 11300
  end

  def setup
    Percolate.log = Logger.new(File.join(data_path, 'test_paired_bwa_workflow.log'))
    Percolate.asynchronizer = SystemAsynchronizer.new
  end

  def data_path
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'data'))
  end

  def test_paired_bwa_fastq
    run_test_if(method(:bwa_available?), "Skipping test_paired_bwa_fastq") do
      work_dir = make_work_dir('test_paired_bwa_fastq', data_path)
      ref_file = File.join(work_dir, 's_pombe_reference.fasta')
      FileUtils.cp(File.join(data_path, 's_pombe_reference.fasta'), ref_file)

      reads1 = File.join(data_path, 'c1006_mrna_1.fastq')
      reads2 = File.join(data_path, 'c1006_mrna_2.fastq')

      # Indexing isn't part of the workflow
      wait_for('test_bwa_index', 60, 5) do
        bwa_index(ref_file, work_dir, :a => :is)
      end

      percolator = Percolator.new({'root_dir' => work_dir,
                                   'log_file' => 'percolate-test.log',
                                   'log_level' => 'DEBUG',
                                   'msg_host' => @msg_host,
                                   'msg_port' => @msg_port})

      # Simulate a user putting a config file in their 'in' directory'
      File.open(File.join(work_dir, 'in', 'test.yml'), 'w') do |out|
        config = {'library' => 'percolate_hts',
                  'workflow' => 'PercolateHTS::Workflows::PairedBWA',
                  'arguments' => [reads1, reads2, ref_file, work_dir]}
        out.puts(YAML.dump(config))
      end

      # The Percolator returns all its workflows after each iteration
      workflow = nil
      Timeout.timeout(90) do
        until workflow && workflow.finished? do
          sleep(5)
          print('#')
          workflow = percolator.percolate.first
        end
      end

      assert(workflow.passed?)
      remove_work_dir(work_dir)
    end
  end
end
