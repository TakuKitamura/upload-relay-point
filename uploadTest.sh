#!/bin/bash
option=$1
for i in `seq 0 2`
do
  if [ $option = "-u" ]; then
    echo "アップロード"
    ./upload.sh uploadTestFile.txt /home/ec2-user/share/testDir$i
  elif [ $option = "-d" ]; then
    ./upload.sh -d /home/ec2-user/share/testDir$i/testFile$i.txt
  elif [ $option = "-p" ]; then
    ./upload.sh -p /home/ec2-user/share/testDir$i/testFile$i.txt
  elif [ $option = "-rf" ]; then
    ./upload.sh -r /home/ec2-user/share/testDir$i/testFile$i.txt /home/ec2-user/share/testDir$i/testRenamedFile$i.txt
  elif [ $option = "-rd" ]; then
    ./upload.sh -r /home/ec2-user/share/testDir$i /home/ec2-user/share/testRenamedDir$i
  fi
done
