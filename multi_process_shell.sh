#!/bin/bash

# メインプロセスをラップしてマルチプロセスでの並列処理を提供するシェルスクリプ
# トのテンプレートです。必要に応じてカスタマイズして下さい。

## settings
status=0

readonly TMP_DIR=tmp
readonly LOG_DIR=log
readonly APP_LOG_FILE_NAME=application.log
readonly ERORR_LOG_FILE_NAME=error.log.$$

readonly PROC_MAX=4
readonly PROC_SLEEP=1
proc_active_count=0
proc_queue=""

## fanctions
# プロセスをエンキューします。
enqueue() {
  proc_queue="${proc_queue} $1"
  proc_active_count=$((${proc_active_count}+1))
}

# 終了したプロセスがないかチェックします。
# 少なくとも1つのプロセスが終了していたらキューを再構築します。
check_queue() {
  local old_queue=${proc_queue}
  for pid in ${old_queue}
  do
    if [ ! -d /proc/${pid} ]; then
      restructure_queue
      break
    fi
  done
}

# キューを再構築します。
restructure_queue() {
  local old_queue=${proc_queue}
  proc_queue=""
  proc_active_count=0
  for pid in ${old_queue}
  do
    if [ -d /proc/${pid} ]; then
      proc_queue="${proc_queue} ${pid}"
      proc_active_count=$((${proc_active_count}+1))
    fi
  done
}

## Setup
if [ ! -d ${LOG_DIR} ]; then
  mkdir ${LOG_DIR}
fi

if [ ! -d ${TMP_DIR} ]; then
  mkdir ${TMP_DIR}
fi

## Exercise
args=(1 2 3 4 5 6 7 8 9 10) # 適当なテストデータ

for arg in ${args[@]}
do
  # 1つのサブプロセスが異常終了しても、他のサブプロセスを継続できる場合は、
  # このif文を削除してください。
  if [ -f ${TMP_DIR}/${ERORR_LOG_FILE_NAME} ]; then
    break
  fi

  # メインプロセスを記述して下さい。
  {
    ./main_process.sh ${arg} || {
      echo "ERORR: ${arg}" 2>> ${ERORR_LOG_FILE_NAME}
    }
  } >> ${LOG_DIR}/${APP_LOG_FILE_NAME} &

  pid=$!
  enqueue ${pid}
  while [ ${proc_active_count} -ge ${PROC_MAX} ]; do
    check_queue
    sleep ${PROC_SLEEP}
  done
done
wait

if [ -f ${TMP_DIR}/${ERORR_LOG_FILE_NAME} ]; then
  cat ${TMP_DIR}/${ERORR_LOG_FILE_NAME} >> ${LOG_DIR}/${APP_LOG_FILE_NAME}
  rm -f ${TMP_DIR}/${ERORR_LOG_FILE_NAME}
  status=1
fi

exit ${status}
