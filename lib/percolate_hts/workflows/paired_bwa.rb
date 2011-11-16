#--
#
# Copyright (c) 2010-2011 Genome Research Ltd. All rights reserved.
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

module PercolateHTS::Workflows

  class PairedBWA < Percolate::Workflow
    include PercolateHTS::Tasks
    include PercolateHTS::Utilities

    description <<-DESC
This workflow maps a pair of files of reads to a reference using
BWA. The unmapped reads may be in Fastq or queryname-sorted BAM
format.

You probably do not want to use this workflow directly with large data
e.g. an entire platform unit. It is more efficient to use the
ChunkedPairedBWA workflow which will split the data into pieces, map the
PairedBWA workflow across each piece in parallel and finally reduce the
pieces into a single BAM file.
    DESC

    usage <<-USAGE
PairedBWA args

Arguments:

- reads1 (String): A string file name. The file must contain first
  reads if Fastq format. If BAM format, reads1 must be the same as reads2.
- reads2 (String): A string file name. The file must contain terminal reads
  if in Fastq format. If BAM format, reads2 must be the same as reads2.
- reference (String): A string file name of the reference sequence in
  Fasta format. The reference must be indexed.
- work_dir (String): Working directory (absolute path).
- other arguments (keys and values):

  :async: <Hash>. Percolate batch queue hints, the default being:

  { :queue => :normal }

  plus all bwa arguments, the defaults being:

  :n => 0.04,
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
  :q => 0

Returns:

- String (filename of BAM format file)
    USAGE

    version '0.0.1'

    def run(reads1, reads2, reference, work_dir, args = {})
      async = args.delete(:async) || { :queue => :normal }

      if args_available?(reads1, reads2, reference, work_dir) && bwa_indexed?(reference)
        unless same_file_format?(reads1, reads2)
          raise ArgumentError,
                "Mismatched read files: " + [reads1, reads2].inspect
        end

        args1 = args2 = {}
        case
          when bam_file?(reads1)
            args1 = {:b => true, '1' => true}.merge(args)
            args2 = {:b => true, '2' => true}.merge(args)
          when fastq_file?(reads1)
            args1 = args2 = args
          else
            raise ArgumentError,
                  "Unknown read format '#{reads1}'; expected one of BAM or Fastq."
        end

        # TODO: allow sampe args to be passed through
        sampe_args = {:a => 500,
                      :n => 3,
                      :o => 100_000,
                      :N => 10}

        # Finally, the pipeline
        bwa_sampe(bwa_aln(reads1, reference, work_dir, args1, async),
                  bwa_aln(reads2, reference, work_dir, args2, async),
                  reads1, reads2, reference, work_dir, sampe_args, async)
      end
    end
  end
end
