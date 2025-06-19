# Установка K3s

Руководство по установке отказоустойчивого K3s кластера с балансировщиком нагрузки.

# Подготовка

## Настройка виртуальных машин

Необходимо подготовить 3 виртуальные машины на линуксе. Я использовал Ubuntu Server 24.04 LTS.
Процесс установки стандартный. В установщике стоит выбрать установку openssh.

### Настройка ssh

На локальной машине создаем пару ключей
```sh
ssh-keygen -t rsa
```

**Обязательно создать ключ без `pass phrase`!**

Далее копируем ключи на все виртуальные машины
```sh
ssh-copy-id username@your_server_ip
```

Затем даем пользователю права на выполнение `sudo` без пароля, выполняем на всех виртуальных машинах:
```sh
sudo visudo # выполнить эту команду чтобы открыть конфиг

username ALL=(ALL) NOPASSWD: ALL # добавить строку в конце файла, username заменить на своего пользователя
```

### Настройка IP адресов виртуальных машин

Все машины должны иметь статический IP в локальной сети. Это настраивается в интерфейсе роутера. Рекомендуется создать отдельную подсеть для виртуальных машин, или просто расширить маску существующей подсети. В моем случае использована подсеть 192.168.0.0/16.

Конфигурация IP адресов:
- kube-1 = 192.168.10.11
- kube-2 = 192.168.10.12
- kube-3 = 192.168.10.13

После настройки в роутере машины обязательно перезапустить!

## Установка k3sup

Установить K3s на конечные машины поможет утилита [k3sup](https://github.com/alexellis/k3sup).

Необходимо установить ее на локальную машину. В случае macOS можно воспользоваться Homebrew:
```sh
brew install k3sup
```

Также нам необходима утилита kubectl
```sh
brew install kubectl
```

Создаем папку для конфигов кубера
```sh
mkdir ~/.kube
```

# Создаем первую мастер ноду кластера

На локальной машине используем k3sup:
```sh
k3sup install \
--ip 192.168.10.11 \ # ip kube-1
--tls-san 192.168.10.10 \ # виртуальный айпи для балансировщика
--tls-san kube.ancored.ru \ # доменное имя, которое ведет на виртуальный IP (опционально)
--cluster \
--k3s-channel latest \
--no-extras \
--local-path $HOME/.kube/config \
--user ancored \ # указать своего пользователя на виртуальной машине
--merge
```

Утилита сама установит K3s и поднимет мастер ноду на виртуальной машине.

## Настройка балансировщика

Чтобы иметь отказоустойчивый кластер, необходимо настроить балансировщик для мастер нод. Мы будем использовать kube-vip.

Полная инструкция: https://kube-vip.io/docs/usage/k3s/

Все команды ниже нужно выполнять из-под root пользователя. Для этого один раз пишем
```sh
sudo su
```

### Создаем директорию для манифестов балансера
```sh
mkdir -p /var/lib/rancher/k3s/server/manifests/
```

### Загружаем манифесты kube-vip
```sh
curl https://kube-vip.io/manifests/rbac.yaml > /var/lib/rancher/k3s/server/manifests/kube-vip-rbac.yaml
```

### Применяем манифесты
```sh
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
```

### Деплоим балансер

Сначала подготовим переменные:
```sh
export VIP=192.168.10.10 # виртуальный IP балансера, который указывали выше
export INTERFACE=ens18 # сетевой интерфейс который будет слушать балансер, можно посмотреть доступные через команду ip a. Выбрать тот, где показывается нормальный IP виртуалки
KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name") # берем последнюю версию балансера
```

Делаем алиас для установки балансера одной командой:
```sh
alias kube-vip="ctr image pull ghcr.io/kube-vip/kube-vip:$KVVERSION; ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"
```

Деплоим:
```sh
kube-vip manifest daemonset \
    --interface $INTERFACE \
    --address $VIP \
    --inCluster \
    --taint \
    --controlplane \
    --services \
    --arp \
    --leaderElection
```

Эта команда выдаст конфиг, который необходимо скопировать. Его мы используем в следующем шаге.

### Применяем конфиг балансера

Конфиг из предыдущей команды надо сохранить по пути `/var/lib/rancher/k3s/server/manifests/kube-vip-manifest.yaml`

Далее применяем конфиг:
```sh
kubectl apply -f /var/lib/rancher/k3s/server/manifests/kube-vip-manifest.yaml
```

На этом установка балансера для мастер нод завершена.

# Подключаем остальные мастер ноды

Также используем утилиту k3sup:
```sh
k3sup join \
--ip 192.168.10.12 \ # kube-2
--server-ip 192.168.10.11 \ # kube-1
--server \
--k3s-channel latest \
--no-extras \
--user ancored # указать своего пользователя на kube-2
```

Эту же команду повторяем на kube-3, поменяв --ip на адрес kube-3.

# Настраиваем балансер на работу с сервисами

Сейчас балансер работает только с нодами кластера. Нужно научить его выдавать внешние IP адреса для сервисов, чтобы они были доступны в нашей сети.

### Ставим kube-vip cloud provider
```sh
kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml
```

### Указываем диапазон IP адресов
```sh
kubectl create configmap -n kube-system kubevip --from-literal range-global=192.168.30.11-192.168.30.99
```

# Тестирование кластера

## Деплой nginx для проверки

Создаем namespace:
```sh
kubectl create namespace nginx
```

Создаем деплой с образом nginx:
```sh
kubectl create deployment nginx --image nginx --namespace nginx
```

Проверяем, что поды поднимаются:
```sh
kubectl get pods --all-namespaces -o wide
```

Создаем LoadBalancer сервис:
```sh
kubectl expose deployment nginx --port=80 --type=LoadBalancer --name=nginx --namespace nginx
```

Проверяем выданный IP:
```sh
kubectl get services --all-namespaces
```

Тестируем доступность nginx:
```sh
curl http://192.168.30.11
```
# Устранение неисправностей

## Проблемы с DNS в Ubuntu

В Ubuntu может возникнуть проблема с встроенным DNS сервером. Временное решение:

В конфиге локального DNS сервера необходимо указать IP роутера:
```sh
sudo nano /etc/resolv.conf

# записать в конфиг:
nameserver 192.168.1.1
```

**Примечание:** Это временное решение, файл может быть перезаписан системой.

