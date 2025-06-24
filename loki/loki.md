# Установка Loki

Руководство по установке системы агрегации логов Loki в кластере Kubernetes с использованием Helm chart.

## Обзор

Loki — это горизонтально масштабируемая, высокодоступная система агрегации логов, вдохновленная Prometheus. Loki индексирует только метаданные логов (labels), а не содержимое самих логов, что делает его крайне эффективным и экономичным.

**Основные компоненты:**
- Distributor — принимает логи от клиентов
- Ingester — записывает логи в хранилище
- Querier — обрабатывает LogQL запросы
- Compactor — управляет retention и сжатием

**Официальная документация**: https://grafana.com/docs/loki/

## Подготовка системы

### 0. Предварительные требования

- Kubernetes кластер (K3s)
- Helm 3.x
- Настроенный Grafana для визуализации логов
- Минимум 1GB свободной памяти

### 1. Создание namespace

```sh
kubectl create namespace loki-stack
```

## Установка через Helm

### 1. Добавление Helm репозитория

```sh
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### 2. Установка Loki

```sh
helm install loki grafana/loki \
  --namespace loki-stack \
  --values loki-values.yaml
```

**Note**: Установка займет 1-2 минуты.

### 3. Проверка установки

Проверяем статус подов в namespace loki:

```sh
kubectl -n loki-stack get pods
```

Основные компоненты должны быть в статусе `Running`:
- `loki-<id>` — основной под Loki в режиме SingleBinary
- `loki-gateway` — Gateway, к которому пудут подключаться Grafana и Promtail'ы

### 5. Настройка Persistnet Volume

В Longhorn необдимо настроить Recurring Job для выполнения Trim Filesystem, чтобы забирать неиспользуемые приложение блоки.

## Интеграция с Grafana

### 1. Настройка источника данных

Войдите в Grafana и добавьте источник данных:

1. Перейдите в **Configuration** → **Data Sources**
2. Нажмите **Add data source**
3. Выберите **Loki**
4. Укажите URL: `http://loki-gateway.loki-stack.svc.cluster.local`
5. Нажмите **Save & Test**

### 2. Проверка подключения

В разделе **Explore** попробуйте выполнить простой запрос:
```logql
{job="loki/loki"}
```

## Установка Promtail (отправка логов)

### 1. Установка Promtail

```sh
helm install promtail grafana/promtail \
  --namespace loki-stack \
  --values promtail-values.yaml
```

### 2. Проверка Promtail

```sh
kubectl -n loki-stack get pods
```

Должны быть поды на каждом узле кластера (DaemonSet).

## Тестирование системы

Просмотр логов в Grafana

1. Откройте Grafana → **Drilldown** → **Logs**
2. Выберите источник данных **Loki**
3. Выполните запрос:
```logql
{app="grafana"}
```