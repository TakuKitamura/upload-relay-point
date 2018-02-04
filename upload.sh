#!/bin/bash

# 内容理解をすべて理解するには bashの最低限の知識が必要
# bash について詳しくは → Google!

# コマンドライン引数の数が正しいか判定
# if [ $# -ne 2 ]; then
#   echo "第一引数はファイルまたはディレクトリの絶対パス"
#   echo "第二引数はファイルサーバーの/home/share/ 以下のディレクトリのパスが必要です。"
#   echo "詳しくは、README を確認してください。"
#   exit 2
# fi

# 鍵のパス
identifyFilePath="$HOME/.ssh/ri-oneFileServerRelayPoint.pem"

# 鍵が存在しない時
if [ ! -f $identifyFilePath ]; then
  echo ${identifyFilePath} が存在しません。
  echo "詳しくは、README を確認してください。"
  exit 2
fi

relayPointUser="ec2-user"

host="13.231.55.13"

if [ $# -eq 1 ]; then
  option=$1
  if [ $option = "-l" ]; then
    ssh -i $identifyFilePath $relayPointUser@$host "cat ~/.tree"
  fi

elif [ $# -eq 2 ]; then

  # コマンドライン引数の第一引数を取得
  # ex $ /home/hoge/upload-relay-point/upload.sh /home/user/hello.txt abc/def/
  # この場合 $absoluteFileServerPath は abc/def/

  localFileOrDirectoryPath=$1
  absoluteFileServerPath=$2

  # $[before|after]OperationabsoluteFileServerPathTemp には、 /tmp/tmp.dpgp9A7UxD などが格納される
  # 下記の処理で、一時ファイルを利用しているかは、(もっとスマートな実装ができる気がする)
  # http://www.atmarkit.co.jp/ait/articles/1209/14/news147.html などを参照

  # mktemp: 適当なファイル名の空ファイルを作成する
  # 一時的に、データを保存したいので使用する
  # ex. $ mktemp -d -p '/home/ec2-user/share'
  #     /home/ec2-user/share/tmp.VlLH6dQviP

  # $relayServerTempDirectoryAbsolutePath　には、 /home/ec2-user/share/tmp.VlLH6dQviP などが格納
  relayServerTempDirectoryAbsolutePath=`ssh -i $identifyFilePath $relayPointUser@$host "cd ~; mktemp -d -p './share'"`

  # 生成したディレクトリ内に第一引数（localFileOrDirectoryPath）を入れる

  # 経由するインスタンス上に、ローカルファイルをアップロード
  # ファイル、シンボリックリンクの場合
  if [ -f $localFileOrDirectoryPath ]; then
    scp -i $identifyFilePath $localFileOrDirectoryPath $relayPointUser@$host:$relayServerTempDirectoryAbsolutePath

    # ディレクトリの場合
  else
    scp -i $identifyFilePath -r $localFileOrDirectoryPath $relayPointUser@$host:$relayServerTempDirectoryAbsolutePath
  fi

  #第二引数（absoluteFileServerPath）をabspass.txtにコピーしてディレクトリーにいれる

  absolutePathOfFileServerInRelayPoint=$relayServerTempDirectoryAbsolutePath/.absolutePathOfFileServer
  ssh -i $identifyFilePath $relayPointUser@$host "echo $absoluteFileServerPath > $absolutePathOfFileServerInRelayPoint"

else
  echo "第一引数はファイルまたはディレクトリの絶対パス"
  echo "第二引数はファイルサーバーの/home/share/ 以下のディレクトリの絶対パスが必要です。"
  echo "詳しくは、README を確認してください。"
  exit 2
fi
