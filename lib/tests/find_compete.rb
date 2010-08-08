require 'thread'

def mkq(cnt=500_000)
  q = Queue.new
  cnt.times { |i| q.push(i) }
  q
end

def mkpush(q, cnt)
  threads = []
  cnt.times { |i| threads << Thread.fork() { loop { q.push(rand(500_000)) } } }
  threads
end

def mkpop(q, cnt)
  threads = []
  cnt.times { |i| threads << Thread.fork() { loop { q.pop } } }
  threads
end

def start(num)
  q = mkq()
  t1 = mkpush(q, num)
  t2 = mkpop(q, num)
  @pool = t1+t2
end

def p()
  @pool.map(&:status)
end

def t()
  proxy = Position.first.to_proxy
  proxy.dereference
end


