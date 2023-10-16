# rmq2kafka
Драфт проект реализации пайплайна между RabbitMQ и kafka
с помощью open source платформы Benthos (https://www.benthos.dev)
## Предыстория вопроса
Базовые требования к решению
- Аппаратная архитектура amd64, arm64
- Операционная система Linux>=3.10, macOS>=10.14 (macOS для разработки)
- Kafka версия >= 0.10
- RabbitMQ версия >= 2
- Отсутствие требований к OS Linux (CentOS,Debian,Ubuntu и т.д.)
- Задание параметров подключения в конфигурации
- Возможность разработки специализированной логики (легкие пайплайны для конвертации потока)
- Поддержка режима кэширования (если целевая система не отвечает)
- Горизонтальное и вертикальное масштабирование
## Поиск решения
В итоге поиск отсановился на решении Benthos, новомодном решении для процессинговой обработки.
Что подкупило?
1) Использует декларативный подход, код пишется на yaml
2) Практически 0 порог старта, скачал, запустил
3) Скомпилирован в статический бинарник (теоритически нет проблем с совместимостью legacy инфраструктуры)
4) Использует IBM sarama go библиотеку для работы с kafka с поддержкой версии >=0.8.2
5) Использует amqp091-go для RabbitMQ (версии >=2 поддерживаются)
6) Удобно настривать параметры подключения и пайплайны
## Стенд
- Apple macbook pro m1 10-core 16gb 
- macOS Ventura 13.5
- Docker Engine 24.0.5
Входной поток генериуется скриптом используя возможности Benthos
- Скрипт ```./pipeline/generator.yml```
- Количество записей 100000
- Каждая запись имеет структуру json c 35 полями, общий размер около 750 байт
- kafka использует строчный сериализатор, 2 партиции, пишется батчами по 10000
## Запуск
```shell
# запуск стенда
/bin/sh ./start.sh
# Запуск теста
/bin/sh ./test.sh
```
## Результаты тестов
Статистика http://localhost:4195/metrics
```log
# HELP batch_created Benthos Counter metric
# TYPE batch_created counter
batch_created{label="",mechanism="check",path="root.output.batching"} 0
batch_created{label="",mechanism="count",path="root.output.batching"} 98
batch_created{label="",mechanism="period",path="root.output.batching"} 0
batch_created{label="",mechanism="size",path="root.output.batching"} 0
# HELP input_connection_failed Benthos Counter metric
# TYPE input_connection_failed counter
input_connection_failed{label="",path="root.input"} 0
# HELP input_connection_lost Benthos Counter metric
# TYPE input_connection_lost counter
input_connection_lost{label="",path="root.input"} 0
# HELP input_connection_up Benthos Counter metric
# TYPE input_connection_up counter
input_connection_up{label="",path="root.input"} 1
# HELP input_latency_ns Benthos Timing metric
# TYPE input_latency_ns summary
input_latency_ns{label="",path="root.input",quantile="0.5"} 2.6263e+07
input_latency_ns{label="",path="root.input",quantile="0.9"} 5.1743542e+07
input_latency_ns{label="",path="root.input",quantile="0.99"} 9.473875e+07
input_latency_ns_sum{label="",path="root.input"} 3.1700816747e+12
input_latency_ns_count{label="",path="root.input"} 100000
# HELP input_received Benthos Counter metric
# TYPE input_received counter
input_received{label="",path="root.input"} 100000
# HELP output_batch_sent Benthos Counter metric
# TYPE output_batch_sent counter
output_batch_sent{label="",path="root.output"} 102
# HELP output_connection_failed Benthos Counter metric
# TYPE output_connection_failed counter
output_connection_failed{label="",path="root.output"} 0
# HELP output_connection_lost Benthos Counter metric
# TYPE output_connection_lost counter
output_connection_lost{label="",path="root.output"} 0
# HELP output_connection_up Benthos Counter metric
# TYPE output_connection_up counter
output_connection_up{label="",path="root.output"} 1
# HELP output_error Benthos Counter metric
# TYPE output_error counter
output_error{label="",path="root.output"} 0
# HELP output_latency_ns Benthos Timing metric
# TYPE output_latency_ns summary
output_latency_ns{label="",path="root.output",quantile="0.5"} 8.027042e+06
output_latency_ns{label="",path="root.output",quantile="0.9"} 1.458325e+07
output_latency_ns{label="",path="root.output",quantile="0.99"} 3.1955834e+07
output_latency_ns_sum{label="",path="root.output"} 1.001017168e+09
output_latency_ns_count{label="",path="root.output"} 102
# HELP output_sent Benthos Counter metric
# TYPE output_sent counter
output_sent{label="",path="root.output"} 100000
# HELP processor_batch_received Benthos Counter metric
# TYPE processor_batch_received counter
processor_batch_received{label="",path="root.pipeline.processors.0"} 100000
# HELP processor_batch_sent Benthos Counter metric
# TYPE processor_batch_sent counter
processor_batch_sent{label="",path="root.pipeline.processors.0"} 100000
# HELP processor_error Benthos Counter metric
# TYPE processor_error counter
processor_error{label="",path="root.pipeline.processors.0"} 0
# HELP processor_latency_ns Benthos Timing metric
# TYPE processor_latency_ns summary
processor_latency_ns{label="",path="root.pipeline.processors.0",quantile="0.5"} 12875
processor_latency_ns{label="",path="root.pipeline.processors.0",quantile="0.9"} 22042
processor_latency_ns{label="",path="root.pipeline.processors.0",quantile="0.99"} 67084
processor_latency_ns_sum{label="",path="root.pipeline.processors.0"} 2.035183517e+09
processor_latency_ns_count{label="",path="root.pipeline.processors.0"} 100000
# HELP processor_received Benthos Counter metric
# TYPE processor_received counter
processor_received{label="",path="root.pipeline.processors.0"} 100000
# HELP processor_sent Benthos Counter metric
# TYPE processor_sent counter
processor_sent{label="",path="root.pipeline.processors.0"} 100000
```
Общее время можно посчитать примерно 
input_latency_ns_sum+processor_latency_ns_sum+output_latency_ns_sum
Для указанной выборки примерная скорость обработки составила 15000 запросов в секунду
Полезные ссылки
- Rabbit management: http://localhost:15672 (user test, pwd test)
- Kafka-ui: http://localhost:8080
## Итоги и дальнейшие планы
Решение имеет потенциал, необходимо продолжить исследования  
- Протестировать на совместимость с различными версиями RabbitMQ, Kafka
- Различные отказоустойчивые сценарии
