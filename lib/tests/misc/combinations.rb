#!/usr/bin/env ruby
require("rbgsl")

printf("All subsets of {0,1,2,3} by size:\n") ;
#for i in 0...4 do
  c = GSL::Combination.calloc(10, 3);
  begin
    printf("{");
    c.fprintf(STDOUT, " %u");
    printf(" }\n");
  end while c.next == GSL::SUCCESS
#end
