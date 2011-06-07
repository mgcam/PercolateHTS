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
  
  def picard_available?
    picard = ENV['PICARD_HOME']
    picard && File.directory?(picard)
  end

  def picard_home
    ENV['PICARD_HOME']
  end

  def picard_jar(jar)
    unless picard_available?
      raise PercolateError, "Unable to locate Picard tools"
    end

    File.join(picard_home, jar)
  end

  def java_args(args = {})
    defaults = {}
    cli_arg_map(defaults.merge(args), :prefix => '-')
  end

  def jvm_args(args = {})
    defaults = {'Xmx' => '2000m',
                'XX:ParallelGCThreads=' => 1}
    cli_arg_map(defaults.merge(args), :prefix => '-', :sep => '')
  end

  def picard_default_args
    {:VALIDATION_STRINGENCY => :SILENT,
     :VERBOSITY => :WARNING,
     :QUIET => 'true'}
  end

  def merge_sam_files(inputs, output, work_dir, args = {}, async = {})
    if args_available?(inputs, output, work_dir)
      defaults = {:ASSUME_SORTED => 'false',
                  :COMMENT => "'Merged\\ from\\ #{inputs.join('\\ ')}'",
                  :TMP_DIR => work_dir}.merge(picard_default_args)
      args = defaults.merge(args)
      args[:OUTPUT] = output

      margs = [inputs, work_dir, args]
      task_id = task_identity(:merge_sam_files, *margs)
      merged = File.join(work_dir, output)
      log = task_id + '.log'

      command = ['java', jvm_args('Xmx' => '1g'),
                 java_args('jar' => picard_jar('MergeSamFiles.jar')),
                 inputs.inject("") { |acc, str| acc + "INPUT=#{str} " },
                 cli_arg_map(args, :sep => '=')].flatten.join(' ')

      async_task(margs, command, work_dir, log,
                 :post => lambda { ensure_files([merged], :error => false) },
                 :result => lambda { merged },
                 :async => async)
    end
  end
end

