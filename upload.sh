#!/bin/bash

# 鍵のパス
identifyFilePath="$HOME/.ssh/ri-one-file-server.pem"

# 鍵が存在しない時
if [ ! -f $identifyFilePath ]; then
  echo ${identifyFilePath} が存在しません。
  echo "詳しくは、README を確認してください。"
  exit 2
fi

check="no"
relayPointUser="ri-one"

host="172.25.72.13"

option=$1

# 引数が１つ
if [ $# -eq 1 ]; then

  # ディレクトリツリーを表示
  if [ $option = "-t" ]; then
    #ssh -T -i $identifyFilePath $relayPointUser@$host "cat ~/.tree"
    ssh Ri-one-File-Server "cd ~/; tree"

  # バージョン情報を表示
  elif [ $option = "-v" ]; then
    echo "Version 1.00 2017-2018 by Junichiro Kawano, Taku Kitamura, Kansei Ishikawa"
  fi

# 引数が２つ
elif [ $# -eq 2 ]; then

  # ファイルサーバへDELETEリクエスト
  if [ $option = "-d" ]; then

    deleteFileServerPath=$2
    math=`ssh Ri-one-File-Server test -e $deleteFileServerPath ; echo $?`
    if [ $math == "1" ]; then
      echo "そのようなファイルやディレクトリは存在しません"
      echo "終了します。"
      exit 2
    fi
    #ファイルの削除
    ssh Ri-one-File-Server "rm -r $deleteFileServerPath"
    str=`echo ${deleteFileServerPath} | awk -F "/" '{ print $NF }'`
    doname="unlink"
    check="ok"

  else
    # コマンドライン引数の第一引数を取得
    # ex $ /home/hoge/upload-relay-point/upload.sh /home/user/hello.txt abc/def/
    # この場合 $absoluteFileServerPath は abc/def/

    doname="pwrite"

    localFileOrDirectoryPath=$1
    str=`echo ${localFileOrDirectoryPath} | awk -F "/" '{ print $NF }'`

    if [ ! -e $localFileOrDirectoryPath ]; then
      echo "ローカル上の、 $localFileOrDirectoryPath が存在しません。"
      echo "終了します。"
      exit 2
    fi
    relayServerTempDirectoryAbsolutePath=$2

    math=`ssh Ri-one-File-Server test -d $relayServerTempDirectoryAbsolutePath ; echo $?`

    if [ $math == "1" ]; then
      echo "そのようなディレクトリは存在しません"
      echo "終了します。"
      exit 2
    fi

    if [ -f $localFileOrDirectoryPath ]; then
      echo "ファイルをアップロードします。"
      scp -i $identifyFilePath $localFileOrDirectoryPath $relayPointUser@$host:$relayServerTempDirectoryAbsolutePath
      check="ok"

      # ディレクトリの場合
    else
      echo "ディレクトリをアップロードします。"
      scp -i $identifyFilePath -r $localFileOrDirectoryPath $relayPointUser@$host:$relayServerTempDirectoryAbsolutePath
      check="ok"
    fi
  fi

  # 引数が3つ
  elif [ $# -eq 3 ]; then

    # 変更前のファイルパス
    beforePath=$2

    # 変更後のファイルパス
    afterPath=$3

    #rename
    if [ $option = "-r" ]; then
      doname="rename"
      str1="$beforePath|$afterPath"

      # ファイルサーバへのリクエスト情報を一意なディレクトリ内に配置
      ssh Ri-one-File-Server "mv $beforePath $afterPath"
      check="ok"


    fi
  fi

  username=`whoami`
  timename=`date +"%Y/%m/%d %k:%M:%S"`

  ssh Ri-one-File-Server "cd ~/samba-with-db; logger -t smbd_audit \|${username}\|/home/ri-one/share\|$timename\|$doname\|$check\|$str"
