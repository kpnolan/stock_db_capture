$foo = 0

a = Thread.new {
  $foo += 1
  Thread.stop
  $foo += 1
}
Thread.pass
Thread.pass
Thread.pass
Thread.pass
Thread.pass
$stderr.puts $foo
$foo = 10
a.run
$stderr.puts $foo

#   a.join
