$:.unshift "../lib"

require 'rubygems'
require 'benchmark'
require 'dense'

ITERATIONS = 100_000

Dense.objective(:default, {
  :pack   => :to_json,
  :unpack => Proc.new {|obj| JSON.parse(obj) }
})

Benchmark.bm(7) do |x|
  x.report("json:")    { ITERATIONS.times {|n| tmp =           ('a' * n).to_json}}
  x.report("pack:" )   { ITERATIONS.times {|n| tmp = Dense.pack('a' * n)}}
end

puts