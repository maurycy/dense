$:.unshift "../lib"

require 'rubygems'
require 'benchmark'
require 'dense'

ITERATIONS = 100_000

Dense.objective(:default, {
  :pack   => Proc.new {|obj| obj },
  :unpack => Proc.new {|obj| obj }
})

Benchmark.bm(7) do |x|
  x.report("pass:")    { ITERATIONS.times {|n| tmp =           ('a' * n)}}
  x.report("pack:" )   { ITERATIONS.times {|n| tmp = Dense.pack('a' * n)}}
end

puts