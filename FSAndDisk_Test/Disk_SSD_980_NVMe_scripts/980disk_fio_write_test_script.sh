#!/bin/bash

# 设定文件路径和大小
# 使用从父脚本导出的FILENAME变量
echo "Using device: $FILENAME"

SIZE=214748364800
BLOCK_SIZE=4k
OUTPUT_DIR=./980_fio_test_write_ranseq
# 循环测试从1个线程到32个线程
for NUMJOBS in {2..32}
do
    # 随机写测试
    iostat -d 100 -x $FILENAME > $OUTPUT_DIR/rand_write_test_${NUMJOBS}_jobs_IOstats.out &
    PID_IOSTAT=$!

    SIZE_PER_JOB=$(($SIZE / $NUMJOBS))
    SIZE_PER_JOB_IN_G=$(echo "scale=2; $SIZE_PER_JOB / (1024*1024*1024)" | bc)
    echo "write unit per job: $SIZE_PER_JOB bytes $SIZE_PER_JOB_IN_G GiB"

    sudo fio --name=rand_write_test \
        --rw=randwrite \
        --bs=$BLOCK_SIZE \
        --size=$SIZE_PER_JOB \
        --numjobs=$NUMJOBS \
        --ioengine=libaio \
        --direct=1 \
        --group_reporting \
        --filename=$FILENAME \
        --output=$OUTPUT_DIR/rand_write_test_${NUMJOBS}_jobs.out
    # 结束 iostat 进程
    kill $PID_IOSTAT

    # 顺序写测试
    iostat -d 100 -x $FILENAME > $OUTPUT_DIR/seq_write_test_${NUMJOBS}_jobs_IOstats.out &
    PID_IOSTAT=$!
    sudo fio --name=seq_write_test \
        --rw=write \
        --bs=$BLOCK_SIZE \
        --size=$SIZE_PER_JOB \
        --numjobs=$NUMJOBS \
        --ioengine=libaio \
        --direct=1 \
        --group_reporting \
        --filename=$FILENAME \
        --output=$OUTPUT_DIR/seq_write_test_${NUMJOBS}_jobs.out
    # 结束 iostat 进程
    kill $PID_IOSTAT
done

echo "所有写操作测试已完成。"
