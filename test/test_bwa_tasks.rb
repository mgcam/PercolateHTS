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
require 'fileutils'

require 'percolate_hts'
require File.join(testpath, 'test_helper')

class TestBWATasks < Test::Unit::TestCase
  include TestHelper
  include PercolateHTS
  include PercolateHTS::BasicTasks

  def initialize(name)
    super(name)
    @msg_host = 'localhost'
    @msg_port = 11300
  end

  def setup
    Percolate.log = Logger.new(File.join(data_path, 'test_bwa_tasks.log'))
    Percolate.asynchronizer = SystemAsynchronizer.new
  end

  def data_path
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'data'))
  end

  def test_bwa_index
    run_test_if(method(:bwa_available?), "Skipping test_bwa_index") do
      work_dir = make_work_dir('test_bwa_index', data_path)
      ref_file = File.join(work_dir, 's_pombe_reference.fasta')
      FileUtils.cp(File.join(data_path, 's_pombe_reference.fasta'), ref_file)

      indices = wait_for('test_bwa_index', 60, 5) do
        bwa_index(ref_file, work_dir, :a => :is)
      end

      assert_equal(8, indices.size)
      index_prefix = File.basename(ref_file)
      assert(indices.collect { |file| File.basename(file) }.all? { |file|
        file.start_with?(index_prefix)
      })

      remove_work_dir(work_dir)
    end
  end

  def test_bwa_samse_tasks
    run_test_if(method(:bwa_available?), "Skipping test_bwa_samse_tasks") do
      work_dir = make_work_dir('test_bwa_samse_tasks', data_path)
      ref_file = File.join(work_dir, 's_pombe_reference.fasta')
      FileUtils.cp(File.join(data_path, 's_pombe_reference.fasta'), ref_file)

      reads_file = File.join(data_path, 'c1006_mrna_1.fastq')
      sai_name = 'c1006_mrna_1.s_pombe_reference.sai'
      bam_name = 'c1006_mrna_1.s_pombe_reference.bam'

      wait_for('test_bwa_tasks', 60, 5) do
        bwa_index(ref_file, work_dir, :a => :is)
      end

      sai_file = wait_for('test_bwa_samse_tasks', 60, 5) do
        bwa_aln(reads_file, ref_file, sai_name, work_dir)
      end
      assert_equal(File.join(work_dir, sai_name), sai_file)

      bam_file = wait_for('test_bwa_samse_tasks', 60, 5) do
        bwa_samse(sai_file, reads_file, ref_file, bam_name, work_dir)
      end
      assert_equal(File.join(work_dir, bam_name), bam_file)

      remove_work_dir(work_dir)
    end
  end

  def test_bwa_sampe_tasks
    run_test_if(method(:bwa_available?), "Skipping test_bwa_sampe_tasks") do
      work_dir = make_work_dir('test_bwa_sampe_tasks', data_path)
      ref_file = File.join(work_dir, 's_pombe_reference.fasta')
      FileUtils.cp(File.join(data_path, 's_pombe_reference.fasta'), ref_file)

      reads_file1 = File.join(data_path, 'c1006_mrna_1.fastq')
      reads_file2 = File.join(data_path, 'c1006_mrna_2.fastq')
      sai_name1 = 'c1006_mrna_1.s_pombe_reference.sai'
      sai_name2 = 'c1006_mrna_2.s_pombe_reference.sai'

      bam_name = 'c1006_mrna.s_pombe_reference.bam'

      wait_for('test_bwa_sampe_tasks', 60, 5) do
        bwa_index(ref_file, work_dir, :a => :is)
      end

      sai_file1, sai_file2 = wait_for('test_bwa_sampe_tasks', 60, 5) do
        [bwa_aln(reads_file1, ref_file, sai_name1, work_dir),
         bwa_aln(reads_file2, ref_file, sai_name2, work_dir)]
      end
      assert_equal([sai_name1, sai_name2].collect { |file|
        File.join(work_dir, file)
      }, [sai_file1, sai_file2])

      bam_file = wait_for('test_bwa_sampe_tasks', 60, 5) do
        bwa_sampe(sai_file1, sai_file2, reads_file1, reads_file2,
                  ref_file, bam_name, work_dir)
      end
      assert_equal(File.join(work_dir, bam_name), bam_file)

      remove_work_dir(work_dir)
    end
  end
end
