if(EXISTS "/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/sim_cache_test[1]_tests.cmake")
  include("/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/sim_cache_test[1]_tests.cmake")
else()
  add_test(sim_cache_test_NOT_BUILT sim_cache_test_NOT_BUILT)
endif()
