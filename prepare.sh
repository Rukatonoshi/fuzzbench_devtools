#!/bin/bash

# Функция для обработки ошибок
error() {
  echo "Ошибка: $@" >&2
  exit 1
}

# Проверяем наличие аргументов
if [[ $# -eq 0 ]]; then
  error "Нет аргументов. Используйте --help для справки."
fi

# Инициализация пустых массивов для хранения значений
fuzzers=()
benchmarks=()

# Обрабатываем аргументы
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --fuzzers)
      # Собираем все оставшиеся аргументы до следующего флага
      while [[ "$#" -gt 1 && $2 != "--benchmarks" ]]; do
        fuzzers+=("$2")
        shift
      done
      shift
      ;;
    --benchmarks)
      # Собираем все оставшиеся аргументы до конца
      while [[ "$#" -gt 1 ]]; do
        benchmarks+=("$2")
        shift
      done
      shift
      ;;
    *)
      error "Неизвестный аргумент: $1"
      ;;
  esac
done

# Если не указаны фуззеры или бенчмарки, выводим ошибку
if [[ -z "${fuzzers[*]}" || -z "${benchmarks[*]}" ]]; then
  error "Необходимо указать фуззеры и бенчмарки!"
fi

eval "make -j base-image worker"

# Последовательный запуск команд
for fuzzer in "${fuzzers[@]}"; do
  for benchmark in "${benchmarks[@]}"; do
    command="make build-${fuzzer}-${benchmark}"
    echo "Запуск команды: ${command}"
    eval $command
  done
done

