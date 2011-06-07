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

module PercolateHTS::BasicTasks
  
  def bwa_available?
    system('which bwa >/dev/null 2>&1')
  end

  def bwa_indices(reference)
    if reference
      %W{.amb .ann .bwt .pac .rbwt .rpac .rsa .sa}.collect do |suffix|
        reference + suffix
      end
    end
  end

  def bwa_indexed?(reference)
    if reference
      bwa_indices(reference).all? { |index| FileTest.file?(index) }
    end
  end

  # Runs bwa to index a Fasta reference.
  #
  # Arguments:
  #
  # - reference (String): Fasta reference sequence file.
  # - args (Hash): A Hash of arguments to bwa, keys being symbols.
  # - async (Hash): Arguments for batch submission.
  #
  # Returns:
  #
  # - Array of String (index files).
  def bwa_index(reference, work_dir, args = {}, async = {})
    if args_available?(reference, work_dir)
      defaults = {:a => :is,
                  :p => File.basename(reference),
                  :c => false}
      args = defaults.merge(args)

      margs = [reference, work_dir, args]
      task_id = task_identity(:bwa_index, *margs)
      log = task_id + '.log'
      bwa_stderr = task_id + '.stderr'
      ref_dir = File.dirname(reference)
      ref_dir = work_dir if ref_dir == '.'

      expected = %W{.amb .ann .bwt .pac .rbwt .rpac .rsa .sa}.collect do |suffix|
        File.join(ref_dir, args[:p] + suffix)
      end

      # BWA always chatters to STDERR, so we have to gag it
      command = ['bwa index', cli_arg_map(args, :prefix => '-'),
                 reference, '2>', bwa_stderr].flatten.join(' ')

      async_task(margs, command, work_dir, log,
                 :post => lambda { ensure_files(expected, :error => true) },
                 :result => lambda { expected },
                 :async => async)
    end
  end

  # Runs bwa to align reads to a reference.
  #
  # Arguments:
  #
  # - query (String): BAM or Fastq read file.
  # - reference (String): Fasta reference sequence file.
  # - output (String): Alignment file.
  # - work_dir (String): Working directory.
  # - args (Hash): A Hash of arguments to bwa, keys being symbols.
  # - async (Hash): Arguments for batch submission.
  #
  # Returns:
  #
  # - String (alignment file).
  def bwa_aln(query, reference, output, work_dir, args = {}, async = {})
    if args_available?(query, reference, output, work_dir)
      # These defaults are taken from the BWA manpage. They are used
      # explicitly here in case the BWA defaults change.
      defaults = {:n => 0.04,
                  :o => 1,
                  :e => -1,
                  :d => 16,
                  :i => 5,
                  :l => 32,
                  :k => 2,
                  :m => 2000000,
                  :t => 1,
                  :M => 3,
                  :O => 11,
                  :E => 4,
                  :R => 30,
                  :q => 0}
      args = defaults.merge(args)
      args[:f] = output

      margs = [query, reference, work_dir, args]
      task_id = task_identity(:bwa_aln, *margs)
      log = task_id + '.log'
      bwa_stderr = task_id + '.stderr'
      sai = absolute_path(output, work_dir)

      # BWA always chatters to STDERR, so we have to gag it
      command = ['bwa aln', cli_arg_map(args, :prefix => '-'),
                 reference, query, '2>', bwa_stderr].flatten.join(' ')

      async_task(margs, command, work_dir, log,
                 :post => lambda { ensure_files([sai], :error => false) },
                 :result => lambda { sai },
                 :async => async)
    end
  end

  def bwa_samse(aln, reads, reference, output, work_dir, args = {}, async = {})
    if args_available?(aln, reads, reference, output, work_dir)
      defaults = {:n => 3}
      args = defaults.merge(args)

      margs = [aln, reads, reference, output, work_dir, args]
      task_id = task_identity(:bwa_samse, *margs)
      log = task_id + '.log'
      bwa_stderr = task_id + '.stderr'
      bam = absolute_path(output, work_dir)

      samtools_args = {:S => true,
                       :b => true,
                       :T => reference,
                       :o => output}

      # BWA always chatters to STDERR, so we have to gag it. Likewise samtools
      command = ['bwa samse', cli_arg_map(args, :prefix => '-'),
                 reference, aln, reads, '2>', bwa_stderr, '|',
                 'samtools view', cli_arg_map(samtools_args, :prefix => '-'),
                 '-', '2>', '/dev/null'].flatten.join(' ')

      async_task(margs, command, work_dir, log,
                 :post => lambda { ensure_files([bam], :error => false) },
                 :result => lambda { bam },
                 :async => async)
    end
  end

  # Runs bwa sampe and inline samtools to create a BAM file.
  #
  # Arguments:
  #
  # - aln1 (String): Forward alignment file.
  # - aln2 (String): Reverse alignment file.
  # - reads1 (String); Forward BAM or Fastq reads file.
  # - reads2 (String); Reverse BAM or Fastq reads file.
  # - reference (String): Fasta reference sequence file.
  # - output (String): Output file.
  # - work_dir (String): Working directory.
  # - args (Hash): A Hash of arguments to bwa, keys being symbols.
  # - async (Hash): Arguments for batch submission.
  #
  # Returns:
  #
  # - String (BAM alignment file).
  def bwa_sampe(aln1, aln2, reads1, reads2, reference, output, work_dir,
      args = {}, async = {})
    if args_available?(aln1, aln2, reads1, reads2, reference, output, work_dir)
      args_defaults = {:a => 500,
                       :n => 3,
                       :o => 100_000,
                       :N => 10}
      args = args_defaults.merge(args)

      margs = [aln1, aln2, reads1, reads2, reference, output, work_dir, args]
      task_id = task_identity(:bwa_sampe, *margs)
      bam = absolute_path(output, work_dir)
      bwa_stderr = task_id + '.stderr'
      log = task_id + '.log'

      samtools_args = {:S => true,
                       :b => true,
                       :T => reference,
                       :o => output}

      # BWA always chatters to STDERR, so we have to gag it. Likewise samtools
      command = ['bwa sampe', cli_arg_map(args, :prefix => '-'),
                 reference, aln1, aln2, reads1, reads2, '2>', bwa_stderr, '|',
                 'samtools view', cli_arg_map(samtools_args, :prefix => '-'),
                 '-', '2>', '/dev/null'].flatten.join(' ')

      async_task(margs, command, work_dir, log,
                 :post => lambda { ensure_files([bam], :error => false) },
                 :result => lambda { bam },
                 :async => async)
    end
  end
end
