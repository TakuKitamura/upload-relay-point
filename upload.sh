#!/bin/bash

# 内容理解をすべて理解するには bashの最低限の知識が必要
# bash について詳しくは → Google!

# ただ、処理の流れは理解できるようにコメントはきちんと書きます

# コマンドライン引数が渡されているか確認

if [ $# -ne 2 ]; then
  echo "第一引数はファイル名またはディレクトリ名、第二引数はファイルサーバーのパスが必要です。"
  echo "詳しくは、README を確認してください。"
  exit 2
fi

# コマンドライン引数の第一引数を取得
# ex $ /home/hoge/upload-relay-point/upload.sh soccer.txt /home/
# この場合 $ は soccer $absolutePath は /home/

File_or_DirectoryName=$1
absolutePass=$2

# mktemp: 適当なファイル名の空ファイルを作成する
# 一時的に、データを保存したいので使用する
# ex. $ mktemp
#     /tmp/tmp.dpgp9A7UxD

# $[before|after]OperationAbsolutePathTemp には、 /tmp/tmp.dpgp9A7UxD などが格納される
# 下記の処理で、一時ファイルを利用しているかは、(もっとスマートな実装ができる気がする)
# http://www.atmarkit.co.jp/ait/articles/1209/14/news147.html などを参照

fileName=`ssh Ri-one_RelayPoint "mktemp -d -p /home/ec2-user/share"`

#生成したディレクトリ内に第一引数（File_or_DirectoryName）を入れる

identifyFile=~/.ssh/ri-oneFileServerRelayPoint.pem

fileMove=`scp -i $identifyFile $File_or_DirectoryName ec2-user@13.231.55.13:$fileName`

#第二引数（absolutePass）をabspass.txtにコピーしてディレクトリーにいれる

ssh Ri-one_RelayPoint "echo $absolutePass >$fileName/abspass.txt"

