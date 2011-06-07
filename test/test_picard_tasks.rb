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

require 'percolate_hts'
require File.join(testpath, 'test_helper')

class TestPicardTasks < Test::Unit::TestCase
  include TestHelper
  include PercolateHTS
  include PercolateHTS::Tasks
  
  def initialize(name)
    super(name)
    @msg_host = 'localhost'
    @msg_port = 11300
  end

  def setup
    Percolate.asynchronizer = SystemAsynchronizer.new
  end

  def data_path
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'data'))
  end

  def test_merge_sam_files
    run_test_if(method(:picard_available?), "Skipping test_merge_sam_files") do
      work_dir = make_work_dir('test_merge_sam_files', data_path)

      sam_names = (0..4).collect do |i|
        'c1006_mrna.s_pombe_reference.sam0' + i.to_s
      end
      sam_files = sam_names.collect do |file|
        File.join(data_path, file)
      end

      merged_name = 'merged.bam'
      merged_file = File.join(work_dir, merged_name)
      
      result = wait_for('test_merge_sam_files', 60, 2) do
        merge_sam_files(sam_files, merged_name, work_dir)
      end
      assert_equal(merged_file, result)

      remove_work_dir(work_dir)
    end
  end
end
