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
  
  def samtools_available?
    system('which samtools >/dev/null 2>&1')
  end

  def samtools_view(bam_file, output, work_dir, args = {}, async = {})
    if args_available?(bam_file, work_dir)
      defaults = {:o => output}
      args = defaults.merge(args)

      margs = [bam_file, work_dir, args]
      task_id = task_identity(:samtools_view, *margs)
      log = task_id + '.log'
      file = absolute_path(output, work_dir)

      command = ['samtools view', bam_file,
                 cli_arg_map(args, :prefix => '-')].flatten.join(' ')

      async_task(margs, command, work_dir, log,
                 :post => lambda { ensure_files([file], :error => false) },
                 :result => lambda { file },
                 :async => async)
    end
  end

  # Returns an Array of Strings that are the reference sequence names
  # given in a BAM file header.
  def bam_reference_names(bam_file)
    if args_available?(bam_file)
      command = ['samtools view', bam_file, '-H'].flatten.join(' ')
      result = task([bam_file], command, File.dirname(bam_file),
                    :result => lambda { true },
                    :unwrap => false)

      result && result.stdout.grep(/^@SQ/).collect do |line|
        line.gsub(/^@SQ\tSN:(\S+).*/, '\1')
      end
    end
  end
end
