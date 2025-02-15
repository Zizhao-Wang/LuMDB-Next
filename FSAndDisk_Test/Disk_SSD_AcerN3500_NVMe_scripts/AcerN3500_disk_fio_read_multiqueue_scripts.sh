#!/bin/bash

# 设定文件路径和大小
# 使用从父脚本导出的FILENAME变量
echo "Using device: $FILENAME"

OUTPUT_DIR=./AcerN3500_fio_test_read_ranseq_multi_queue


for BLOCK_SIZE in 4K 8K 16k 64k 128K 256k 512k 1M 2M 4M 8M
    do
    # 循环测试从1个线程到32个线程
    for NUMJOBS in {1..1}
    do

        for IODEPTH in 2 4 8 16 32
        do
            TEST_NAME="seq_read_test"
            # 顺序读测试
            iostat -d 1 -x $FILENAME > $OUTPUT_DIR/${TEST_NAME}_block_${BLOCK_SIZE}_${IODEPTH}_${NUMJOBS}_jobs_IOstats.out &
            PID_IOSTAT=$!

            SIZE_PER_JOB=$(($SIZE / $NUMJOBS))
            SIZE_PER_JOB_IN_G=$(echo "scale=2; $SIZE_PER_JOB / (1024*1024*1024)" | bc)
            echo "write unit per job: $SIZE_PER_JOB bytes $SIZE_PER_JOB_IN_G GiB"

            
            fio --name=$TEST_NAME \
                --rw=read \
                --bs=$BLOCK_SIZE \
                --size=$SIZE_PER_JOB \
                --numjobs=$NUMJOBS \
                --ioengine=libaio \
                --iodepth=$IODEPTH \
                --direct=1 \
                --group_reporting \
                --filename=$FILENAME \
                --output=$OUTPUT_DIR/${TEST_NAME}_block_${BLOCK_SIZE}_${IODEPTH}_${NUMJOBS}_jobs.out &
            
            sleep 1
            # 使用 pgrep 捕获所有相关的 fio 进程ID，排序后选取第二个最小的 PID
            SECOND_SMALLEST_FIO_PID=$(pgrep -af "fio --name=$TEST_NAME" | awk '{print $1}' | sort -n | sed -n '2p')
            # 检查是否有进程ID被捕获
            if [ -z "$SECOND_SMALLEST_FIO_PID" ]; then
                echo "No suitable FIO process found. Exiting."
                exit 1
            else
                echo "Second smallest FIO PID found: $SECOND_SMALLEST_FIO_PID"
            fi
            # 使用perf监控选定的PID
            perf stat -p $SECOND_SMALLEST_FIO_PID 2>&1 | tee "$OUTPUT_DIR/perfstat_${TEST_NAME}_${BLOCK_SIZE}_${IODEPTH}_${NUMJOBS}_jobs.txt" &
            # 等待原始的 fio 进程结束
            wait $!
            # 结束 iostat 进程
            kill $PID_IOSTAT




            TEST_NAME2="rand_read_test"
            # 随机读测试
            iostat -d 1 -x $FILENAME > $OUTPUT_DIR/${TEST_NAME2}_block_${BLOCK_SIZE}_${IODEPTH}_${NUMJOBS}_jobs_IOstats.out &
            PID_IOSTAT=$!
            fio --name=$TEST_NAME2 \
                --rw=randread \
                --bs=$BLOCK_SIZE \
                --size=$SIZE_PER_JOB \
                --numjobs=$NUMJOBS \
                --iodepth=$IODEPTH \
                --ioengine=libaio \
                --direct=1 \
                --group_reporting \
                --filename=$FILENAME \
                --output=$OUTPUT_DIR/${TEST_NAME2}_block_${BLOCK_SIZE}_${IODEPTH}_${NUMJOBS}_jobs.out &

            sleep 1
            # 使用 pgrep 捕获所有相关的 fio 进程ID，排序后选取第二个最小的 PID
            SECOND_SMALLEST_FIO_PID=$(pgrep -af "fio --name=$TEST_NAME2" | awk '{print $1}' | sort -n | sed -n '2p')
            # 检查是否有进程ID被捕获
            if [ -z "$SECOND_SMALLEST_FIO_PID" ]; then
                echo "No suitable FIO process found. Exiting."
                exit 1
            else
                echo "Second smallest FIO PID found: $SECOND_SMALLEST_FIO_PID"
            fi
            # 使用perf监控选定的PID
            perf stat -p $SECOND_SMALLEST_FIO_PID 2>&1 | tee "$OUTPUT_DIR/perfstat_${TEST_NAME2}_${BLOCK_SIZE}_${IODEPTH}_${NUMJOBS}_jobs.txt" &
            # 等待原始的 fio 进程结束
            wait $!
            # 结束 iostat 进程
            kill $PID_IOSTAT
        done
    done
done


echo "所有测试已完成。"
