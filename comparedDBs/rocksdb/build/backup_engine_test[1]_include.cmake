if(EXISTS "/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/backup_engine_test[1]_tests.cmake")
  include("/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/backup_engine_test[1]_tests.cmake")
else()
  add_test(backup_engine_test_NOT_BUILT backup_engine_test_NOT_BUILT)
endif()