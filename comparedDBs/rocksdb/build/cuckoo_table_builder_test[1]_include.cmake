if(EXISTS "/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/cuckoo_table_builder_test[1]_tests.cmake")
  include("/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/cuckoo_table_builder_test[1]_tests.cmake")
else()
  add_test(cuckoo_table_builder_test_NOT_BUILT cuckoo_table_builder_test_NOT_BUILT)
endif()