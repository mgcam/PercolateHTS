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

module PercolateHTS::Tasks

  def bwa_aln(query, reference, work_dir, args = {}, async = {})
    if query
      qname = File.basename(query, File.extname(query))

      # The args :b, -1 and -2 are used when the query is a BAM file.
      # In this case, the first and last reads could be in the same query file.
      # The following ensures that the respective output file names are distinct.
      output = case
                 when args[:b] && args['1']
                   qname + '__1'
                 when args[:b] && args['2']
                   qname + '__2'
                 else
                   qname
               end

      output = output + '.sai'

      super(query, reference, output, work_dir, args, async)
    end
  end

  def bwa_samse(aln, reads, reference, work_dir, args = {}, async = {})
    if args_available?(reads, reference)
      aname = File.basename(reference) + '.' + File.basename(reads)
      output = aname + '.bam'

      super(aln, reads, reference, output, work_dir, args, async)
    end
  end

  def bwa_sampe(aln1, aln2, reads1, reads2, reference, work_dir, args = {}, async = {})
    if args_available?(reads1, reference)
      aname = File.basename(reference) + '.' + File.basename(reads1)
      output = aname + '.bam'

      super(aln1, aln2, reads1, reads2, reference, output, work_dir, args, async)
    end
  end
end

