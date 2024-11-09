# MIT License
#
# Copyright (c) rguiscard 2024
# Copyright (c) Sebastian Katzer 2017
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

MRuby::Gem::Specification.new('mruby-wheelcake') do |spec|
  spec.license = 'MIT'
  spec.authors = 'rguiscard '
  spec.summary = 'Embedded web framework based on mruby-shelf and mruby-yeah'

  spec.add_dependency 'mruby-r3',  mgem: 'mruby-r3'
  spec.add_dependency 'mruby-env', mgem: 'mruby-env'

  spec.add_dependency 'mruby-object-ext',      core: 'mruby-object-ext'
  spec.add_dependency 'mruby-exit',            core: 'mruby-exit'
#  spec.add_dependency 'mruby-heeler',          mgem: 'mruby-heeler'
  spec.add_dependency 'mruby-tiny-opt-parser', mgem: 'mruby-tiny-opt-parser'

  spec.add_test_dependency 'mruby-sprintf', core: 'mruby-sprintf'
  spec.add_test_dependency 'mruby-print',   core: 'mruby-print'
  spec.add_test_dependency 'mruby-time',    core: 'mruby-time'
  spec.add_test_dependency 'mruby-io',      core: 'mruby-io'
  spec.add_test_dependency 'mruby-logger',  mgem: 'mruby-logger'

  spec.rbfiles = Dir.glob("#{spec.dir}/mrblib/**/*.rb").sort.reverse
end
