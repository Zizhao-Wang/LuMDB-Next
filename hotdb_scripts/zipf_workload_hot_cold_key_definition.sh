
./config.sh

echo fb0-=0-= | sudo -S bash -c 'echo 800000 > /proc/sys/fs/file-max'
sudo bash -c 'ulimit -n 800000'



BASE_VALUE_SIZE=128
billion=1000000000
percentages=(1 5 10 15 20 25 30) # 定义百分比值
range_dividers=(1)
DEVICE_NAME="nvme0n1"


convert_to_billion_format() {
    local num=$1
    local integer_part=$((num / billion))
    local decimal_part=$((num % billion))

    if ((decimal_part == 0)); then
        echo "${integer_part}B"
    else
        # Convert decimal part to the format of "x billionths"
        local formatted_decimal=$(echo "scale=9; $decimal_part / $billion" | bc | sed 's/0*$//' | sed 's/\.$//')
        # Extract only the fractional part after the decimal point
        formatted_decimal=$(echo $formatted_decimal | cut -d'.' -f2)
        echo "${integer_part}.${formatted_decimal}B"
    fi
}

for i in {10..10}; do
    base_num=$(($billion * $i))
    dir1="${i}B_hotdb_key_definition"
    if [ ! -d "$dir1" ]; then
        mkdir $dir1
    fi
        cd $dir1
        for value_size in 128; do
            num_entries=$(($base_num * $BASE_VALUE_SIZE / $value_size))
            stats_interva=$((num_entries / 1000))

            num_format=$(convert_to_billion_format $num_entries)
            num_format=100000000

            for zipf_a in 1.3; do  # 1.2 1.3 1.4 1.5
                    percentages1=() # 1 5 10 15 20 25 30
                    No_hot_percentages=(10 20 30 40 50 60 70 80 90 100)

                    log_file="hotdb_${num_format}_val_${value_size}_zipf${zipf_a}_keydefinition5.log"
                    data_file="/home/jeff-wang/workloads/zipf${zipf_a}_keys10.0B.csv" # 构建数据文件路径
                    # hot_files=$(printf "/home/jeff-wang/workloads/zipf${zipf_a}_top%%s_keys10B.csv," {1,5,10,15,20,25,30})
                    # hot_files=${hot_files%?} # 移除最后一个逗号
                    

                    # 如果日志文件存在，则跳过当前迭代
                    if [ -f "$log_file" ]; then
                        echo "Log file $log_file already exists. Skipping this iteration."
                        continue
                    fi

                    echo "base_num: $base_num"

                    echo "num_entries: $num_entries"
                    echo "value_size:$value_size"
                    echo "stats_interval: $stats_interva"
                    echo "$num_format"

                    db_directory="/mnt/hotdb_test/hotdb10B/5_${zipf_a}"
                    if [ ! -d "$db_directory" ]; then
                        mkdir -p "$db_directory"
                    fi

                    # 检查目录是否为空，如果不为空则删除所有内容
                    if [ "$(ls -A $db_directory)" ]; then
                        rm -rf "${db_directory:?}/"*
                    fi

                    iostat -d 100 -x $DEVICE_NAME > leveldb2_${num_format}_val_${value_size}_zipf${zipf_a}_IOstats.log &
                    PID_IOSTAT=$!
                    
                    ../../hotdb/release/db_bench \
                    --db=$db_directory \
                    --num=$num_entries \
                    --value_size=$value_size \
                    --batch_size=1000 \
                    --benchmarks=fillzipf,stats \
                    --data_file=$data_file  \
                    --logpath=/mnt/logs \
                    --bloom_bits=10 \
                    --log=1  \
                    --cache_size=8388608 \
                    --open_files=40000 \
                    --compression=0 \
                    --stats_interval=$stats_interva \
                    --histogram=1 \
                    --write_buffer_size=1048576 \
                    --max_file_size=2097152   \
                    --print_wa=true \
                    &> >( tee $log_file) &  

                    # 保存 db_bench 的 PID 供监控使用
                    sleep 1

                    DB_BENCH_PID=$(pgrep -af "db_bench --db=$db_directory" | grep -v 'sudo' | awk '{print $1}')
                    echo "Selected DB_BENCH_PID: $DB_BENCH_PID"

                    perf stat -p $DB_BENCH_PID 2>&1 | tee "perf_stat_${num_format}_val_${value_size}_zipf${zipf_a}_Nohot1-${no_hot}.txt" &
                    PERF_PID=$!

                    wait $DB_BENCH_PID

                    # 结束 iostat 进程
                    echo "Checking if iostat process with PID $PID_IOSTAT is still running..."
                    ps -p $PID_IOSTAT
                    if [ $? -eq 0 ]; then
                        echo "iostat process $PID_IOSTAT is still running, killing now..."
                        kill -9 $PID_IOSTAT
                        if [ $? -eq 0 ]; then
                            echo "iostat process $PID_IOSTAT has been successfully killed."
                        else
                            echo "Failed to kill iostat process $PID_IOSTAT."
                        fi
                    else
                        echo "iostat process $PID_IOSTAT is no longer running."
                    fi
            done
        done
done


