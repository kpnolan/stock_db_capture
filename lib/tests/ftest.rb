require 'fiber'

f = Fiber.new { (0..10).each  { |i| $stderr.puts i } }.resume
f = Fiber.new { (11..20).each { |i| $stderr.puts i } }.resume
f = Fiber.new { (21..30).each { |i| $stderr.puts i } }.resume
f = Fiber.new { (31..40).each { |i| $stderr.puts i } }.resume
f = Fiber.new { (41..50).each { |i| $stderr.puts i } }.resume
f = Fiber.new { (51..60).each { |i| $stderr.puts i } }.resume
