#!/bin/bash

# Settings
ip="127.0.0.1" 

# check the params
if [ $# -lt 2 ]
then
    echo "Usage: $0 <app> <server> [comment]"
    echo "Example: $0 HelloApp HelloServer"
    exit 1
fi

# init params
app=$2
server=$3
comment="`git config -l | grep -e 'user.name=.*' -o | sed 's/user.name=//g'` $4 [by publish.sh]"
tgz="${server}.tgz"

echo "the publishing comment is \"${comment}\""

# loading thread
trap "pkill -13 -f `basename $0`" EXIT
while true
do
    for i in '-' '\' '|' '/'
    do
        printf "\r%s" $i
        sleep 0.2
    done
    if [ loading = true ]; then break; fi
done &

# get the server node 
echo "getting server node ids ..."
result=`curl -s http://${ip}:3000/pages/server/api/server_list?tree_node_id=1${app}.5${server}`
echo $result
server_ids=`echo ${result} | grep -e '"id":[0-9]*,' -o | grep -e '[0-9]*,' -o | sed 's/,//g'`
echo "the server_ids: ${server_ids}"

if [[ $server_ids == "" ]]
then 
    echo "get server node failure !!!"
    exit 1
fi

# upload the publishing patch
echo "uploading the publishing patch ..."
task_id=$RANDOM
result=`curl -s "http://${ip}:3000/pages/server/api/upload_patch_package" -X POST -F "application=${app}" -F "module_name=${server}" -F "comment=${comment}" -F "task_id=${task_id}" -F "suse=@${tgz}"`
echo $result
patch_id=`echo ${result} | grep -e '"id":[0-9]*,' -o | grep -e '[0-9]*,' -o | sed 's/,//g'`
echo "the patch_id: ${patch_id}"

if [[ $patch_id == "" ]]
then 
    echo "upload failure !!!"
    exit 1
else
    echo "upload success !!!"
fi

# join the publishing request json
items=""
for server_id in $server_ids
do
    items=${items}"{\"server_id\":\"${server_id}\",\"command\":\"patch_tars\",\"parameters\":{\"patch_id\":\"${patch_id}\",\"bak_flag\":false,\"update_text\":\"\"}},"
done
items=`echo $items | sed "s/,$//g"`

# publish
echo "publishing the app ..."
result=`curl -s "http://${ip}:3000/pages/server/api/add_task" -X POST -H "Content-Type: application/json" -d "{\"serial\":true,\"items\":[$items]}"`
echo $result
task_no=`echo $result | grep -e '"data":".*",' -o | sed 's/"data":"//g' | sed 's/",//g'`
echo "the task_no: ${task_no}"

if [[ $task_no == "" ]]
then 
    echo "publish failure !!!"
    exit 1
fi

# polling the publishing status
while true
do
    status=`curl -s "http://${ip}:3000/pages/server/api/task?task_no=${task_no}" | sed 's/"items":.*\]//g' | grep -e '"status":[0-9]*,' -o | sed 's/"status"://g' | sed 's/,//g' `

    if [[ $status == 2 ]]
    then 
        echo "publish success !!!"
        rm $tgz
        break
    elif [[ $status == 3 ]]
    then 
        echo "publish failure !!!"
        exit 1
    fi

    sleep 1
done

echo "http://${ip}:3000/index.html#/server/1${app}.5${server}/manage"

echo -e "\033[32mDONE\033[0m"