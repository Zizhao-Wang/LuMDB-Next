if(EXISTS "/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/dynamic_bloom_test[1]_tests.cmake")
  include("/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/dynamic_bloom_test[1]_tests.cmake")
else()
  add_test(dynamic_bloom_test_NOT_BUILT dynamic_bloom_test_NOT_BUILT)
endif()