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

require 'percolate'

module PercolateHTS
  include Percolate
  include Tasks
  include Utilities
end

require 'percolate_hts/tasks'

require 'percolate_hts/tasks/basic_bwa'
require 'percolate_hts/tasks/bwa'

require 'percolate_hts/tasks/basic_picard'
require 'percolate_hts/tasks/basic_samtools'

require 'percolate_hts/workflows'
require 'percolate_hts/workflows/paired_bwa'
