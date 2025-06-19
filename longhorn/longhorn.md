# Установка Longhorn

Руководство по установке провайдера постоянных томов (Persistent Volumes) Longhorn в кластере Kubernetes.

## Обзор

Longhorn — это легковесная, надежная и простая в использовании система хранения данных для Kubernetes, которая предоставляет высокодоступные постоянные блочные тома.

**Официальная документация**: https://longhorn.io/docs/1.9.0/deploy/install/

## Подготовка системы

### 1. Установка longhornctl

Longhorn требует определенные системные зависимости. Разработчики предоставили утилиту `longhornctl`, которая проверяет и устанавливает их автоматически.

```sh
# Для AMD64 платформы
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v1.9.0/longhornctl-linux-amd64

# Для ARM платформы
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v1.9.0/longhornctl-linux-arm64

# Делаем файл исполняемым
chmod +x longhornctl
```

### 2. Проверка зависимостей

Проверяем готовность всех узлов кластера:

```sh
sudo ./longhornctl check preflight --kube-config=/etc/rancher/k3s/config.yaml
```

### 3. Установка зависимостей

Устанавливаем недостающие зависимости:

```sh
sudo ./longhornctl install preflight --kube-config=/etc/rancher/k3s/config.yaml
```

### 4. Отключение multipathd

После установки зависимостей могут остаться предупреждения о coredns и multipathd. CoreDNS можно игнорировать, а multipathd необходимо отключить на всех узлах:

```sh
sudo systemctl stop multipathd multipathd.socket
sudo systemctl disable multipathd multipathd.socket
```

### 5. Финальная проверка

Снова запускаем проверку для подтверждения готовности:

```sh
sudo ./longhornctl check preflight --kube-config=/etc/rancher/k3s/config.yaml
```

Все критические ошибки должны быть устранены.

## Установка через Helm

**Документация по установке**: https://longhorn.io/docs/1.9.0/deploy/install/install-with-helm/

### 1. Добавление Helm репозитория

```sh
helm repo add longhorn https://charts.longhorn.io
helm repo update
```

### 2. Установка Longhorn

```sh
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --values longhorn-values.yaml
```

**Note**: Процесс установки может занять несколько минут. Helm может казаться "зависшим" — это нормально.

### 3. Проверка установки

Проверяем статус подов Longhorn:

```sh
kubectl -n longhorn-system get pods
```

Все поды должны быть в статусе `Running`.

### 4. Настройка доступа через Traefik

Применяем IngressRoute для доступа к веб-интерфейсу:

```sh
kubectl apply -f longhorn-ingressroute.yaml
```

После применения конфигурации веб-интерфейс Longhorn будет доступен по адресу: **longhorn.kube.ancored.ru**

## Тестирование с Portainer

Для проверки работы провайдера постоянных томов развернем Portainer, который требует собственный volume.

### 1. Добавление репозитория Portainer

```sh
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
```

### 2. Установка Portainer

```sh
helm upgrade --install --create-namespace \
  -n portainer portainer portainer/portainer \
  --values portainer-values.yaml
```

**Note**: Данный Helm chart автоматически создает IngressRoute согласно настройкам в values.yaml

### 3. Проверка создания volume

После запуска подов Portainer в веб-интерфейсе Longhorn (longhorn.kube.ancored.ru) можно увидеть новый созданный том.

## Настройка резервного копирования

Для настройки бэкапов используется SMB-шара, размещенная на NAS (в данном примере TrueNAS).

### 1. Создание секрета для подключения к SMB

Все данные в Kubernetes секретах должны быть закодированы в base64:

```sh
echo -n 'user/password' | base64
```

Создаем секрет:

```sh
kubectl apply -f longhorn-smb-secret.yaml
```

### 2. Настройка Backup Target

В веб-интерфейсе Longhorn:

1. Переходим в **Settings** → **Backup Target**
2. Для **Default Target** указываем параметры:
   - **URL**: `cifs://IP-адрес-NAS/название-SMB-share`
   - **Credential Secret**: `smb-secret`

⚠️ **Важно**: В URL указывается именно название SMB Share, а не файловый путь к нему.

### 3. Тестирование резервного копирования

Создаем тестовый бэкап тома Portainer через веб-интерфейс Longhorn. Резервная копия должна появиться в настроенном SMB-share на NAS.

## Заключение

После выполнения всех шагов в кластере будет развернут полнофункциональный провайдер постоянных томов Longhorn с возможностью резервного копирования на внешний NAS.

