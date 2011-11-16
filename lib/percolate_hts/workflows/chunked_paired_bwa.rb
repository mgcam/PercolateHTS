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

  class ChunkedPairedBWA < Percolate::Workflow
    include PercolateHTS::Tasks
    include PercolateHTS::Utilities

    description <<-DESC
    DESC

    usage <<-USAGE
ChunkedPairedBWA args
    USAGE

    version '0.0.1'

    def run(reads1, reads2, reference, work_dir, args = {})
      defaults = {:chunk_size => 1_000_000_000,
                  :chunk_reads => 500_000}
      args = defaults.merge(args)

      unless same_file_format?(reads1, reads2)
        raise PercolateTaskError,
              "Mismatched read files: " + [reads1, reads2].inspect
      end

      max_chunk_size = args.delete(:chunk_size).to_i # bases
      rec_size = estimate_read_length(reads1)
      rec_estimate = max_chunk_size / rec_size

      chunk_unit = args.delete(:chunk_reads).to_i # reads
      num_rec = [rec_estimate / chunk_unit * chunk_unit, chunk_unit].max

      chunks1 = split_read_file(reads1, num_rec, work_dir)
      chunks2 = if reads1 == reads2
                  chunks1
                else
                  split_read_file(reads2, num_rec, work_dir)
                end

      if chunks1 && chunks2
        bams = chunks1.zip(chunks2).each_with_index.collect do |c, i|
          wf = PairedBWA.new(self.workflow_identity + '.' + i.to_s)
          wf.run(c[0], c[1], reference, work_dir, args)
        end

        bam_merge(bams, work_dir)
      end
    end
  end
end
