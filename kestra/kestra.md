# Установка Kestra

Руководство по установке Kestra.

## Обзор

Kestra - это платформа для автоматизации процессов. Чсм-то похожа на ansible, но является не утилитой, а production-ready платформой с собственным UI и огромным количеством плагинов: от интеграции с Ansible до провижена кластеров в облаке.

**Официальная документация**: https://kestra.io

## Подготовка системы

### 0. Docker и Docker Compose

На машине должен быть установлен Docker и плагин Docker Compose.

### 1. 

Необходимо скопировать файл Docker Compose из этого репозитория на машину, где будет производится установка

## Установка

### 1. Поднимаем контейнеры

```sh
docker compose up -d
```

### 2. Проверка установки

Kestra будет доступна по ссылке `http://localhost:8056`. Также можно настроить ваш reverse proxy на адрес машины и порт Kestra.

## Использование

Здесь находятся некоторые заметки по использованию Kestra в homelab. Примеры разных флоу можно найти в папке `flows/`.

### Доступ к защищенным SSL доменам

По умолчанию встроенные плагины Kestra проверяют валидность ssl сертификата. В моем окружении все домены имеют валидный AlphaSSL Wildcard сертификат. Например, браузеры определяют его как валидный.

Однако Kestra не может проверить валидность этих сертификатов. К счастью, это можно отключить.

#### io.kestra.plugin.scripts.python.Script

Пример флоу, которое сможет сделать https запрос к сайту с "невалидным" сертификатом

```yaml
id: dogfish_194446
namespace: anco

inputs:
  - id: url
    type: STRING
    required: true
    defaults: 'https://grafana.ancored.ru'

tasks:
  - id: hello
    type: "io.kestra.plugin.scripts.python.Script"
    taskRunner:
      type: io.kestra.plugin.scripts.runner.docker.Docker
      networkMode: host # ВАЖНО! Без этого запрос зависает, хотя днс резолв происходит
    script: | # ВАЖНО! verify=False, чтобы отключить проверку сертификата
      import requests

      print('running')

      headers={}

      response = requests.get('{{ inputs.url }}', verify=False, timeout=10)
      print(response.status_code)
    beforeCommands:
      - pip install requests
```

#### io.kestra.plugin.core.http.Request

Пример флоу, которое сможет сделать https запрос к сайту с "невалидным" сертификатом

```yaml
id: microservices-and-apis
namespace: anco
description: Microservices and APIs

inputs:
  - id: server_uri
    type: URI
    defaults: https://grafana.ancored.ru.io

tasks:
  - id: http_request
    type: io.kestra.plugin.core.http.Request
    uri: "{{ inputs.server_uri }}"
    options:
      allowFailed: true
      ssl:
        insecureTrustAllCertificates: true # ВАЖНО! Отключаем проверку сертификатов

  - id: check_status
    type: io.kestra.plugin.core.flow.If
    condition: "{{ outputs.http_request.code != 200 }}"
    then:
      - id: server_unreachable_alert
        type: io.kestra.plugin.core.log.Log
        message: Fuck! Server is down!
    else:
      - id: healthy
        type: io.kestra.plugin.core.log.Log
        message: Everything is fine!
```
