if(EXISTS "/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/transaction_test[1]_tests.cmake")
  include("/home/jeff-wang/WorkloadAnalysis/comparedDBs/rocksdb/build/transaction_test[1]_tests.cmake")
else()
  add_test(transaction_test_NOT_BUILT transaction_test_NOT_BUILT)
endif()