# Homelab K3s Кластер

Этот репозиторий содержит конфигурационные файлы и документацию для настройки и управления полнофункционального K3s Kubernetes кластера для домашней лаборатории с мониторингом и хранением данных.

## 📁 Структура репозитория

```
homelab/
├── k3s/
│   ├── k3s.md                    # Полное руководство по установке K3s кластера
│   └── k3s.config.yaml           # Конфигурационный файл для kubectl
├── traefik/
│   ├── traefik.md                # Настройка Traefik ingress контроллера
│   ├── traefik-values.yaml       # Helm values для Traefik
│   ├── nginx-manifest.yaml       # Пример nginx деплоя для тестирования
│   ├── nginx-clusterip-manifest.yaml # ClusterIP сервис для nginx
│   └── nginx-ingressroute.yaml   # Конфигурация Traefik IngressRoute
├── longhorn/
│   ├── longhorn.md               # Руководство по установке Longhorn
│   ├── longhorn-values.yaml      # Helm values для Longhorn
│   ├── longhorn-ingressroute.yaml # IngressRoute для веб-интерфейса
│   ├── longhorn-smb-secret.yaml  # Секрет для SMB бэкапов
│   └── portainer-values.yaml     # Тестовый деплой для проверки PV
└── grafana-prometheus/
    ├── grafana.md                # Руководство по установке Grafana + Prometheus
    ├── grafana-values.yaml       # Helm values для kube-prometheus-stack
    ├── grafana-secret.yaml       # Секрет с учетными данными Grafana
    └── grafana-ingressroute.yaml # IngressRoute для веб-интерфейса Grafana
```

## 🚀 Быстрый старт

1. **Настройка K3s кластера**: Следуйте подробному руководству в [k3s/k3s.md](k3s/k3s.md):
   - Подготовка виртуальных машин с Ubuntu Server 24.04 LTS
   - Настройка SSH ключей и статических IP адресов
   - Установка K3s с помощью k3sup
   - Настройка kube-vip балансировщика для высокой доступности

2. **Деплой Traefik**: Используйте [traefik/traefik.md](traefik/traefik.md):
   - Установка Traefik как ingress контроллер
   - Настройка DNS и SSL сертификатов
   - Настройка Traefik дашборда

3. **Настройка хранилища**: Следуйте [longhorn/longhorn.md](longhorn/longhorn.md):
   - Установка Longhorn для постоянных томов
   - Настройка резервного копирования на NAS
   - Тестирование с Portainer

4. **Развертывание мониторинга**: Используйте [grafana-prometheus/grafana.md](grafana-prometheus/grafana.md):
   - Установка Grafana и Prometheus
   - Настройка дашбордов и алертов
   - Мониторинг всех компонентов кластера

## 🛠 Компоненты кластера

### Основные компоненты
- **K3s**: Легковесный Kubernetes дистрибутив
- **kube-vip**: Балансировщик нагрузки для высокой доступности кластера
- **Traefik**: Современный HTTP reverse proxy и ingress контроллер
- **Helm**: Пакетный менеджер для Kubernetes

### Хранение данных
- **Longhorn**: Распределенная система хранения блочных данных
- **SMB/CIFS**: Интеграция с NAS для резервного копирования

### Мониторинг и наблюдение
- **Prometheus**: Система мониторинга и сбора метрик
- **Grafana**: Платформа для визуализации и анализа данных
- **Alertmanager**: Управление алертами и уведомлениями
- **Node Exporter**: Сбор метрик хостовой системы
- **kube-state-metrics**: Метрики состояния объектов Kubernetes

## 📋 Требования

### Аппаратные требования
- 3 виртуальные машины с Ubuntu Server 24.04 LTS
- Минимум 4GB RAM и 50GB диска на каждую VM
- Настроенные статические IP адреса
- NAS или сетевое хранилище для резервных копий (опционально)

### Программные требования
- Доменное имя с контролем DNS записей
- Локальная машина с установленными:
  - kubectl
  - k3sup
  - helm

## 🔧 Конфигурация сети

Кластер использует следующую схему IP адресации:
- **Мастер ноды**: 192.168.10.11-13
- **VIP балансировщика**: 192.168.10.10
- **Пул балансировщика сервисов**: 192.168.30.11-99

### Доменные имена
- `traefik.kube.ancored.ru` - Traefik дашборд
- `longhorn.kube.ancored.ru` - Longhorn веб-интерфейс
- `grafana.kube.ancored.ru` - Grafana дашборды

## 📚 Документация

Подробные инструкции по настройке доступны в соответствующих директориях:

### Основная инфраструктура
- [k3s/k3s.md](k3s/k3s.md) - Установка и настройка K3s кластера
- [traefik/traefik.md](traefik/traefik.md) - Настройка Traefik ingress контроллера

### Хранение и мониторинг
- [longhorn/longhorn.md](longhorn/longhorn.md) - Развертывание системы хранения
- [grafana-prometheus/grafana.md](grafana-prometheus/grafana.md) - Настройка стека мониторинга
