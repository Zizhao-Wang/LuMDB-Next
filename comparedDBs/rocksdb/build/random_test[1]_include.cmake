if(EXISTS "/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/random_test[1]_tests.cmake")
  include("/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/random_test[1]_tests.cmake")
else()
  add_test(random_test_NOT_BUILT random_test_NOT_BUILT)
endif()
