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

module PercolateHTS::Utilities
  def fastq_file?(file)
    File.extname(file).match(/^\.(fastq|fq)$/i)
  end

  def bam_file?(file)
    File.extname(file).match(/^\.bam$/i)
  end

  def same_file_format?(*files)
    extnames = files.collect { |file| file && File.extname(file) }.uniq
    extnames.size == 1 && !extnames.first.nil?
  end

  def file_format(*files)
    same_file_format?(files) && File.extname(first.files)
  end

  def estimate_read_length(file)
    if file
      case
        when fastq_file?(file)
          peek_fastq_length(file)
        when bam_file?(file)
          peek_bam_length(file)
        else
          raise ArgumentError,
                "Unknown read format '#{file}'; expected one of BAM or Fastq."
      end
    end
  end

  def peek_fastq_length(file)
    File.open(file) do |io|
      header = io.readline
      io.take_while { |line| line.chomp.strip != '+'}.inject(0) do |total, line|
        total + line.length
      end
    end
  end

  def peek_bam_length(file)
    IO.popen("samtools view #{file} 2>/dev/null") do |io|
      io.sync = true
      fields = io.readline.split(/\t/)
      fields.length == 13 && fields[9].length
    end
  end
end
