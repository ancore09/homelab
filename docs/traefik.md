# Установка Traefik

Руководство по установке и настройке Traefik ingress контроллера для K3s кластера.

# Подготовка

На данном этапе у нас уже есть K3s кластер с тремя нодами, настроенным kube-vip и рабочей утилитой kubectl на локальной машине.

## Helm

Чтобы удобно деплоить различные инструменты, нам необходимо установить утилиту Helm на локальной машине:

```sh
brew install helm
```

На этом подготовка закончена.

# Деплой Traefik

Создаем файл для конфигурации Helm чарта `traefik-values.yaml`:
```yaml
deployment:
  replicas: 3
```

Добавляем Helm репозиторий:
```sh
helm repo add traefik https://traefik.github.io/charts
helm repo update
```

Деплоим чарт:
```sh
helm install traefik traefik/traefik --namespace traefik --create-namespace --values traefik-values.yaml
```
Этот чарт создаст деплой Traefik, а также ресурс с типом LoadBalancer. Kube-vip выдаст Traefik свободный IP адрес.

```sh
kubectl get pods -n traefik
```

## Настройка DNS

В конфигурацию зоны вашего домена в DNS сервере необходимо добавить запись, которая будет вести в Traefik.

В моем случае используется домен `ancored.ru`. Все, что касается K3s находится в домене `kube.ancored.ru`. Поэтому я добавляю запись с wildcard для этого домена:
```
*.kube  IN  A   192.168.30.12 # IP Traefik
```

## Тестирование

Уже сейчас мы можем проверить работу Traefik.

Для этого создадим тестовый деплой nginx и IngressRoute для него.

Сначала добавляем определения ресурсов Traefik:
```sh
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.4/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.4/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml
```

Далее применяем следующие манифесты через `kubectl apply -f`:

- [Манифест для nginx](../nginx-manifest.yaml)
- [Манифест для ClusterIP](../nginx-clusterip-manifest.yaml)

Осталось применить манифест для IngressRoute - именно на него смотрит Traefik.

В нем необходимо указать ваше доменное имя, которое было настроено в DNS сервере:
```yaml
- match: Host(`nginx-test.kube.ancored.ru`)
```

Также применяем манифест через `kubectl apply -f`:

- [Манифест для IngressRoute](../nginx-ingressroute.yaml)

Теперь мы можем сделать запрос на nginx через Traefik:
```sh
curl http://nginx-test.kube.ancored.ru # указать ваш домен
```

В ответ получаем приветствие от nginx.

# Настройка Traefik Dashboard

У Traefik есть свой dashboard, который выключен по умолчанию. Чтобы его включить надо изменить параметры Helm чарта:
```yaml
deployment:
  replicas: 3
ingressRoute:
  dashboard:
    enabled: true
    entryPoints: [web, websecure]
    matchRule: Host(`traefik.kube.ancored.ru`) # выбираем домен
```

После этого делаем upgrade деплоя Traefik:
```sh
helm upgrade traefik traefik/traefik --namespace traefik --values traefik-values.yaml
```

# Настройка SSL сертификатов

## Автоматическое получение сертификатов

Для автоматического получения SSL сертификатов можно использовать Let's Encrypt с cert-manager или встроенные возможности Traefik.

Также можно использовать внешний стетический сертификат. 

**Примечание:** Детальная настройка SSL сертификатов будет добавлена в следующих версиях документации.