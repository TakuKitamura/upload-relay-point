#!/bin/bash

# 内容理解をすべて理解するには bashの最低限の知識が必要
# bash について詳しくは → Google!

# 鍵のパス
identifyFilePath="$HOME/.ssh/ri-oneFileServerRelayPoint.pem"

# 鍵が存在しない時
if [ ! -f $identifyFilePath ]; then
  echo ${identifyFilePath} が存在しません。
  echo "詳しくは、README を確認してください。"
  exit 2
fi

relayPointUser="ec2-user"

host="52.192.59.159"

option=$1

# 引数が１つ
if [ $# -eq 1 ]; then

  # ディレクトリツリーを表示
  if [ $option = "-t" ]; then
    ssh -T -i $identifyFilePath $relayPointUser@$host "cat ~/.tree"

  # ディレクトリリストを表示
  elif [ $option = "-l" ]; then
    ssh -T -i $identifyFilePath $relayPointUser@$host "cat ~/.absolutePathListOfFileServer"

  # バージョン情報を表示
  elif [ $option = "-v" ]; then
    echo "Version 1.00 2017-2018 by Junichiro Kawano, Taku Kitamura, Kansei Ishikawa"
  fi

# 引数が２つ
elif [ $# -eq 2 ]; then

  # ファイルサーバへDELETEリクエスト
  if [ $option = "-d" ]; then

    deleteFileServerPath=$2

    # ファイルサーバへのリクエスト情報
    requestParamsText="uploadAbsolutePath=''\ndeleteAbsolutePath=${deleteFileServerPath}\nrenameAbsolutePath=''\ndownloadAbsolutePath=''"

    # 経由サーバへ、ファイルサーバへのリクエスト情報を一意なディレクトリ内に配置
    ssh -T -i $identifyFilePath $relayPointUser@$host << EOF
    relayServerTempDirectoryAbsolutePath=\`mktemp -d -p '/home/ec2-user/share'\`/.requestParams
    echo -e '$requestParamsText' > \`echo \$relayServerTempDirectoryAbsolutePath\`
EOF

  # ファイルサーバへPULLリクエスト
  elif [ $option = "-p" ]; then
    pullFileSeverPath=$2

    # ファイルサーバへのリクエスト情報
    requestParamsText="uploadAbsolutePath=''\ndeleteAbsolutePath=''\nrenameAbsolutePath=''\ndownloadAbsolutePath=${pullFileSeverPath}"

    # 経由サーバへ、ファイルサーバへのリクエスト情報を一意なディレクトリ内に配置
    ssh -T -i $identifyFilePath $relayPointUser@$host << EOF
    relayServerTempDirectoryAbsolutePath=\`mktemp -d -p '/home/ec2-user/share'\`/.requestParams
    echo -e '$requestParamsText' > \`echo \$relayServerTempDirectoryAbsolutePath\`
EOF

  else
    # コマンドライン引数の第一引数を取得
    # ex $ /home/hoge/upload-relay-point/upload.sh /home/user/hello.txt abc/def/
    # この場合 $absoluteFileServerPath は abc/def/

    localFileOrDirectoryPath=$1

    if [ ! -e $localFileOrDirectoryPath ]; then
      echo "ローカル上の、 $localFileOrDirectoryPath が存在しません。"
      echo "終了します。"
      exit 2
    fi

    # 絶対パスからベースネームを取得
    # ex. $ basename /Users/kitamurataku/downloads/test.txt
    #       test.txt
    baseFileOrDirectoryName=`basename $localFileOrDirectoryPath`

    # ファイルサーバーにアップロード予定の、絶対パス
    willUploadFileAbsolutePath=`echo "$2/$baseFileOrDirectoryName" | sed -e 's/\/\//\//g'`

    # ファイルサーバへのリクエスト情報
    requestParamsText="uploadAbsolutePath=${2}\ndeleteAbsolutePath=''\nrenameAbsolutePath=''\ndownloadAbsolutePath=''"

    # 経由サーバへ、ファイルサーバへのリクエスト情報を一意なディレクトリ内に配置
    ssh -T -i $identifyFilePath $relayPointUser@$host << EOF > /tmp/.relayServerTempDirectoryAbsolutePath

    # ローカルから、ファイルサーバへ上げる予定のファイルがファイルサーバ上の同じパスに存在するかチェック
    uploadFileAbsolutePath=\`cat ~/.absolutePathListOfFileServer | grep -x $willUploadFileAbsolutePath\`

    # 存在する場合
    if [ -n "$uploadFileAbsolutePath" ]; then
      echo "ファイルサーバー上に、 $willUploadFileAbsolutePath が存在します。"
      echo "終了します。"
      exit 2

    # 存在しない場合
    else
      # 経由サーバへ、ファイルサーバへのリクエスト情報を一意なディレクトリ内に配置
      relayServerTempDirectoryAbsolutePath=\`mktemp -d -p '/home/ec2-user/share'\`/.requestParams
      echo -e '$requestParamsText' > \`echo \$relayServerTempDirectoryAbsolutePath\`
      echo \$relayServerTempDirectoryAbsolutePath
    fi
EOF

    relayServerTempDirectoryAbsolutePath=`cat /tmp/.relayServerTempDirectoryAbsolutePath | xargs dirname`
    # 経由するインスタンス上に、ローカルファイルをアップロード
    # ファイル、シンボリックリンクの場合
    if [ -f $localFileOrDirectoryPath ]; then
      echo "ファイルをアップロードします。"
      scp -C -i $identifyFilePath $localFileOrDirectoryPath $relayPointUser@$host:$relayServerTempDirectoryAbsolutePath

      # ディレクトリの場合
    else
      echo "ディレクトリをアップロードします。"
      scp -C -i $identifyFilePath -r $localFileOrDirectoryPath $relayPointUser@$host:$relayServerTempDirectoryAbsolutePath
    fi
  fi

# 引数が3つ
elif [ $# -eq 3 ]; then

  # 変更前のファイルパス
  beforePath=$2

  # 変更後のファイルパス
  afterPath=$3

  if [ $option = "-r" ]; then

    # ファイルサーバへのリクエスト情報
    requestParamsText="uploadAbsolutePath=''\ndeleteAbsolutePath=''\nrenameAbsolutePath=${beforePath}|${afterPath}\ndownloadAbsolutePath=''"

    # 経由サーバへ、ファイルサーバへのリクエスト情報を一意なディレクトリ内に配置
    ssh -T -i $identifyFilePath $relayPointUser@$host << EOF
    relayServerTempDirectoryAbsolutePath=\`mktemp -d -p '/home/ec2-user/share'\`/.requestParams
    echo -e '$requestParamsText' > \`echo \$relayServerTempDirectoryAbsolutePath\`
EOF
  fi
fi
