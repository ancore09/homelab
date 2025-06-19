# Установка Grafana и Prometheus

Руководство по установке стека мониторинга Grafana + Prometheus в кластере Kubernetes с использованием kube-prometheus-stack.

## Обзор

Grafana — это платформа для мониторинга и наблюдаемости с открытым исходным кодом, которая позволяет запрашивать, визуализировать, оповещать и анализировать метрики из различных источников данных.

Prometheus — это система мониторинга и алертинга с открытым исходным кодом, которая собирает и хранит метрики в виде временных рядов.

**kube-prometheus-stack** — это Helm chart, который включает в себя полный стек мониторинга Kubernetes:
- Prometheus Operator
- Prometheus
- Alertmanager
- Grafana
- Node Exporter
- kube-state-metrics
- Предустановленные дашборды и правила алертинга

**Официальная документация**: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

## Подготовка системы

### 0. Конфигурация k3s

По умолчанию k3s экспортирует не все метрики. Чтобы это исправить, необходимо указать дополнительные параметры запуска k3s.

Скопируйте [конфиг k3s](k3s/k3s.config.yaml) в `/etc/rancher/k3s/config.yaml` на каждом узле кластера. Все узлы необходимо перезапуститью

### 1. Создание namespace

```sh
kubectl create namespace monitoring
```

### 2. Создание секрета для учетных данных Grafana

Создаем секрет с учетными данными администратора:

```sh
kubectl apply -f grafana-secret.yaml
```

Файл `grafana-secret.yaml` содержит закодированные в base64 логин и пароль:
- Логин: `admin` (YWRtaW4=)
- Пароль: `admin` (YWRtaW4=)

## Установка через Helm

### 1. Добавление Helm репозитория

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 2. Установка kube-prometheus-stack

```sh
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values grafana-values.yaml
```

**Note**: Процесс установки может занять несколько минут, так как загружается множество компонентов.

### 3. Проверка установки

Проверяем статус всех подов в namespace monitoring:

```sh
kubectl -n monitoring get pods
```

Все поды должны быть в статусе `Running`. Основные компоненты:
- `prometheus-<id>` — сервер Prometheus
- `grafana-<id>` — сервер Grafana  
- `alertmanager-<id>` — менеджер алертов
- `node-exporter-<id>` — экспортеры метрик узлов
- `kube-state-metrics-<id>` — метрики состояния кластера

### 4. Настройка доступа через Traefik

Применяем IngressRoute для доступа к веб-интерфейсу Grafana:

```sh
kubectl apply -f grafana-ingressroute.yaml
```

После применения конфигурации веб-интерфейс Grafana будет доступен по адресу: **grafana.kube.ancored.ru**

## Конфигурация

### Основные настройки values.yaml

Ключевые параметры конфигурации:

#### Grafana
- **Учетные данные**: Используется секрет `grafana-admin-credentials`
- **Дашборды**: Включены дашборды по умолчанию для Kubernetes
- **Часовой пояс**: UTC
- **Источники данных**: Автоматически настроен Prometheus

#### Prometheus
- **Хранение данных**: 20Gi через Longhorn PVC
- **Время хранения**: 6 часов
- **Размер хранения**: 4GiB
- **Интервал сбора**: 30 секунд
- **Сжатие WAL**: Включено

#### Мониторинг компонентов K8s
Настроен мониторинг всех основных компонентов:
- kube-apiserver
- kubelet  
- kube-controller-manager
- kube-scheduler
- kube-proxy
- etcd
- CoreDNS

#### Node Exporter
- **Исключения файловых систем**: Системные и временные FS
- **Ресурсы**: 512Mi RAM запрос, 2048Mi лимит
- **CPU**: 250m запрос

### Endpoints для компонентов управления

В конфигурации указаны IP-адреса мастер-узлов (192.168.10.11-13) для мониторинга:
- kube-controller-manager
- kube-scheduler  
- kube-proxy
- etcd (порт 2381)

## Доступ к системе

### Grafana
- **URL**: https://grafana.kube.ancored.ru
- **Логин**: admin
- **Пароль**: admin

### Встроенные дашборды
После установки доступны предустановленные дашборды:
- Kubernetes Cluster Monitoring
- Node Exporter Full
- Kubernetes Pod Monitoring
- Kubernetes Deployment Monitoring
- И многие другие

### Prometheus
Prometheus также доступен внутри кластера через сервис `prometheus-kube-prometheus-prometheus:9090`

### Alertmanager  
Alertmanager доступен через сервис `alertmanager-operated:9093`

## Управление и мониторинг

### Проверка метрик

Убедитесь, что Prometheus собирает метрики:
```sh
kubectl -n monitoring port-forward под-прометея 9090:9090
```

Откройте http://localhost:9090 и проверьте доступные цели в разделе Status → Targets.

### Проверка дашбордов

1. Войдите в Grafana
2. Перейдите в раздел Dashboards
3. Откройте любой из предустановленных дашбордов
4. Убедитесь, что отображаются данные

### Настройка алертов

Alertmanager настроен, но требует дополнительной конфигурации для отправки уведомлений (email, Slack, Telegram и т.д.).

## Масштабирование и оптимизация

### Увеличение хранилища Prometheus

Для увеличения времени хранения метрик отредактируйте values.yaml:

```yaml
prometheus:
  prometheusSpec:
    retention: 30d  # Увеличить до 30 дней
    retentionSize: 50GiB  # Увеличить размер
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 100Gi  # Увеличить размер диска
```

## Заключение

После выполнения всех шагов в кластере будет развернут полнофункциональный стек мониторинга с Grafana и Prometheus, включающий:
- Автоматический сбор метрик со всех компонентов Kubernetes
- Готовые дашборды для визуализации
- Настроенный Alertmanager для уведомлений
- Веб-интерфейс для управления и анализа