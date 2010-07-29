require '../fiber_pool'

fp = FiberPool.new()

count = 1

proc = lambda() { count += 1; puts count }

50.times do
  fp.spawn(&proc)
end
