cd $HOME/logstash6.2/bin
echo "###########################################"

duetrmaingestnodes[0]="[\"eb-es-stg3-1:9201\",\"eb-es-stg3-2:9201\",\"eb-es-stg3-3:9201\",\"eb-es-stg3-4:9201\",\"eb-es-stg3-5:9201\"]"
duetrmaingestnodes[1]="[\"eb-es-stg3-1:9201\",\"eb-es-stg3-2:9201\",\"eb-es-stg3-3:9201\",\"eb-es-stg3-4:9201\",\"eb-es-stg3-5:9201\"]"
duetrmaingestnodes[2]="[\"eb-es-stg3-1:9201\",\"eb-es-stg3-2:9201\",\"eb-es-stg3-3:9201\",\"eb-es-stg3-4:9201\",\"eb-es-stg3-5:9201\"]"
duetrmaingestnodes[3]="[\"eb-es-stg3-1:9201\",\"eb-es-stg3-2:9201\",\"eb-es-stg3-3:9201\",\"eb-es-stg3-4:9201\",\"eb-es-stg3-5:9201\"]"
duetrmaingestnodes[4]="[\"eb-es-stg3-1:9201\",\"eb-es-stg3-2:9201\",\"eb-es-stg3-3:9201\",\"eb-es-stg3-4:9201\",\"eb-es-stg3-5:9201\"]"
duetrmaingestnodes[5]="[\"eb-es-stg3-1:9201\",\"eb-es-stg3-2:9201\",\"eb-es-stg3-3:9201\",\"eb-es-stg3-4:9201\",\"eb-es-stg3-5:9201\"]"

cfg_basename=`basename @option.config@`

if (( @option.workers@ > 6 )); then
    echo number of workers cannot be more than 6
    exit -1
fi

echo "Partition details"

OIFS=$IFS;
IFS=",";
counter=0;

partition=@option.partition_ids@
partitionArray=($partition);

IFS=$OIFS;

# removing the tmp directory so that files changes will reflect.
rm -rf $HOME/logstash6.2/config/rmaotm/tmp

c=`jps  | grep Main | wc -l`
cur=$c
c=$((c+@option.No_of_logstash_instances@))

echo "Total number of Logstash running now $cur"
if (( $c > 24 )); then
    echo "Currently running $cur instancess"
    echo "too many running logstash insances $c  running. Max 24";
    exit -1
fi

echo "Number of batches"
if ((${#partitionArray[@]} > @option.No_of_logstash_instances@)); then 
	echo "I HAVE MORE RANGES TO RUN, SO I WILL RUNNING IN LOOP FOR A LONG TIME....."
	#exit -1
fi

total=${#partitionArray[@]}

#interval=$(($total / @option.No_of_logstash_instances@))

echo "total =${#partitionArray[@]}"
#echo "interval =$interval"


#start=0
#end=$interval    
if [ ! -d $HOME/logstash6.2/config/rmaotm/tmp ]; then
    mkdir -p $HOME/logstash6.2/config/rmaotm/tmp
fi

if [ "@option.remove_existing_data_path@" == "Yes" ]; then
    rm -rf ../../data/$cfg_basename-@option.identifier_tag@*
fi

echo ""
echo ""
echo ""
echo ""

echo "looping start....."
for (( i=0; i<${#partitionArray[@]}; i++ ))
do

    set -- ${partitionArray[$i]}
    
    start_value=${1%:*}
    end_value=${1#*:}
    
    #if [ $i -eq @option.No_of_logstash_instances@ ]; then
    #    end=$total
    #fi
    
    #for (( j=$start+1; j<$end; j++ ))
    #do
    #    start_value=$start_value,${partitionArray[$j]}
    #done

    echo "range=$start_value:$end_value"
    
    cp ../config/rmaotm/@option.config@ /tmp/@option.config@
    
    sql_file=@option.config@
    
    sql_file=${sql_file/json/sql}
    
    #echo $sql_file
    
    es=$i
    if (( $i > 5)); then
        es=$(($i-6))
    fi
    
    #echo "elastic rolling count #######################################################  $es"
    sed "s/:start_value/$start_value/g; s/:end_value/$end_value/g;  s,$sql_file,tmp/$sql_file$i,1; s/:duetrmaingestnodes/${duetrmaingestnodes[$es]}/g" ../config/rmaotm/@option.config@ > ../config/rmaotm/tmp/@option.config@$i

    sed "s/:start_value/$start_value/g; s/:end_value/$end_value/g" ../config/rmaotm/$sql_file > ../config/rmaotm/tmp/$sql_file$i
    

    #Remove the below 3 lines once bitbucket is up.
    #sed -i "s/CSFPRD_SRVC_RO/CSFPRD_SRVC_DM/g" ../config/duetotm/tmp/@option.config@$i
    #sed -i "s/APPSRO/XXCTS_DM_U/g" ../config/duetotm/tmp/@option.config@$i
    #sed -i "s/Vak2G9_M/Ze_U2s6K/g" ../config/duetotm/tmp/@option.config@$i
    
    #cat ../config/rmaotm/@option.config@
    #cat ../config/rmaotm/tmp/@option.config@$i
    
    echo "####################################################################################################"
    
    #cat ../config/rmaotm/tmp/$sql_file$i


    #start_value=$end_value
    
    
    if (( $i >= @option.No_of_logstash_instances@ && $i < ${#partitionArray[@]} )); then
        condition=-1
	    while [ $condition == -1 ]
	    do
	        cond_counter=0
	        for j in ${pid_array[*]}
	        do
	            if [ ! -d "/proc/$j"  ]; then 
	                condition=$cond_counter;
	                echo "command completed its execution...$condition : $cond_counter"
	            else 
	                cond_counter=$((cond_counter+1))
	            fi
	        done
	    done
	 else 
	    echo "print the partition = $start_value:$end_value"
	 fi
    
    echo "pids =${pid_array[@]}"
    
    
	
	 #echo "./logstash -n $cfg_basename-@option.identifier_tag@-$i --pipeline.id $cfg_basename-@option.identifier_tag@-$i --path.data ../../data/$cfg_basename-@option.identifier_tag@-$i -b 1000 -w @option.workers@  -f ../config/rmaotm/tmp/$cfg_basename$i --path.logs=../logs/$cfg_basename-@option.identifier_tag@$s-$i &"
	 #./logstash -n $cfg_basename-@option.identifier_tag@-$i --pipeline.id $cfg_basename-@option.identifier_tag@-$i --path.data ../../data/$cfg_basename-@option.identifier_tag@-$i -b 1000 -w @option.workers@  -f ../config/rmaotm/tmp/$cfg_basename$i --path.logs=../logs/$cfg_basename-@option.identifier_tag@$s-$i &
	 #echo $! > $cfg_basename-@option.identifier_tag@-$i.pid
	 #echo "start_value=${start_value}" >> $cfg_basename-@option.identifier_tag@-$i.pid
	 #echo "end_value=${end_value}" >> $cfg_basename-@option.identifier_tag@-$i.pid
	
	 sleep 30 &
	 pid=" $!"
	 #echo "pid = $pid"
	 echo "wait period over, moving a head"
	 pid_array[$counter]=$pid
	 
	 
	 echo "counter =$counter"
	 counter=$((counter+1))
	 

done

ls -la $HOME/logstash6.2/config/rmaotm/tmp

#sleep 20