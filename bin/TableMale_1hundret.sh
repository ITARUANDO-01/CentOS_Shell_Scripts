#!/bin/bash
#set -vxe
#set -x

#==================================================================================
# MySQL上にて、100テーブル入ったデータベースを作成するスクリプト
# DB名は$1を、テーブル名は$2に_001～_100という感じで命名する。
# なお、作成されるテーブルのカラムの内容は一緒にする
# MySQLのパスワードはホームディレクトリ配下に「.my_pass.rsa」というファイルから読み出す
#==================================================================================

#==================================================================================
# 各種変数設定
#==================================================================================
#パスワード用設定
MYSQL_PWD=$(openssl rsautl -decrypt -inkey ~/.ssh/id_MySQL_rsa -in ~/.my_pass.rsa)


#==================================================================================
# usage表示ファンクション
#==================================================================================

function usage_echo()
{
   echo 'このスクリプトについて：MySQL上にテスト用のDBと100テーブルを作成するスクリプト'
   echo '実行条件：引数を2つつける'
   echo '第一引数：作成するDB名'
   echo '第二引数：作成するテーブル名'
}

#==================================================================================
# 各処理サブシェル
#==================================================================================

### データベース作成用サブシェル

function make_database()
{
#set -vx

# データベース作成コマンド
databasecre="create database $1"

echo "$databasecre" | MYSQL_PWD=$(openssl rsautl -decrypt -inkey ~/.ssh/id_MySQL_rsa -in ~/.my_pass.rsa) mysql -uroot

#set +vx
}

### テーブル作成用サブシェル

function make_tables()
{
#set -vx
# データベース名
databasename="$1"

# sqlファイル名
sqlfilename="`echo "$HOME"`/$2"

# テーブル作成コマンド
tablecre="create table $(echo "${databasename}.${tablename}")"

# テーブル作成処理
MYSQL_PWD=$(openssl rsautl -decrypt -inkey ~/.ssh/id_MySQL_rsa -in ~/.my_pass.rsa) mysql -uroot $(echo "$databasename") < "$sqlfilename" #$(echo "$sqlfilename")

#set +vx
}

#==================================================================================
# 各種確認
#==================================================================================

### 第二引数まで指定されているか確認

if [ "$#" -ne 2 ]; then

   if [[ "$1" == 'usage' ]]; then
      # usage表示用条件文
      usage_echo
      exit 0

   fi

   echo "このシェルスクリプトを実行するには2つの引数が必要です。"
   exit 1

fi

### 「.my_pass.rsa」というファイルがあるか確認

if [ -e ~/.my_pass.rsa ]; then
   :
else

   echo '「.my_pass.rsa」がホームディレクトリ上にありません'
   exit 1

fi

### 第二引数に指定されたファイルが存在するか確認

#set -vx
if [ -e $(echo ~/"$2") ]; then
   :
else

   echo '第二引数に指定したファイルが存在しません'
   exit 1

fi
#set +vx

### sqlファイル名とテーブル名が一致しているか確認

#set -vx
fulpass="$HOME"/"$2"
finame=$(basename "$fulpass" .sql)
tbnamecont=$(cat "$fulpass" | grep "$finame" | wc -l)

if [ 0 -eq "$tbnamecont" ]; then

   echo 'sqlファイル名と作成するテーブル名は同じものにして下さい'
   exit 1

fi
#set +vx

### MySQLにログインが問題ないか確認

LoginTest=$(MYSQL_PWD=$(openssl rsautl -decrypt -inkey ~/.ssh/id_MySQL_rsa -in ~/.my_pass.rsa) mysql -uroot -e "\! echo testloginOK")

if [[ "$LoginTest" -eq 'testloginOK' ]]; then

   echo 'パスワード問題無し'

else

   echo 'パスワードの値が一致しません。「.my_pass.rsa」の値を確認して下さい。 '
   exit 1

fi

#==================================================================================
# 本処理
#==================================================================================

# データベース作成処理
make_database $1

# テーブル作成処理
#set -vx
i=1

while [ $i -le 100 ]
do
   makename=${finame}${i}
   ficname="${makename}.sql"

   sed s/"$finame"/"$makename"/ "$fulpass" > ~/"$ficname"

   make_tables $1 $ficname

   rm -f ~/"$ficname"

   i=`expr "$i" + 1`

done
#set +vx
