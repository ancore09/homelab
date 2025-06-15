# Установка Traefik
#### Поды крутятся, ингрессы мутятся

# Подготовка

На данном этапе у нас уже есть k3s кластер с тремя нодами, настроенным kube-vip и рабочей утилитой kubectl на локальной машине.

## Helm

Чтобы удобно деплоить различные инструменты, нам необходимо установить утилиту helm на локальной машине:

```sh
brew install helm
```

На этом подготовка закончена.

# Деплоим Traefik

Создаем файл для конфигурации helm чарта traefik-values.yaml
```yaml
deployment:
  replicas: 3
```

Добавляем helm репозиторий
```sh
helm repo add traefik https://traefik.github.io/charts
helm repo update
```

Деплоим чарт:
```sh
helm install traefik traefik/traefik --namespace traefik --create-namespace --values traefik-values.yaml
```
Этот чарт создаст деплой traefik, а также ресурс с типом LoadBalancer. Kube-vip выдаст traefik свободный айпи адрес.

```sh
kubectl get pods -n traefik
```

## Настраиваем DNS

В конфигурацию зоны вашего домена в dns сервере необходимо добавить запись, которая будет вести в traefik. 

В моем случае используется домен ancored.ru. Все, что касается k3s находится в домене kube.ancored.ru. Поэтому я добавляю запись с вайлдкардом дя этого домена:
```
*.kube  IN  A   192.168.30.12 # айпи traefik
```

## Проверка

Уже сейчас мы можем проверить работу Traefik.

Для этого создадим тестовый деплой nginx и IngressRoute для него.

Сначала добавляем определения ресурсов Traefik:
```sh
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.4/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.4/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml
```

Далее применяем следующие манифесты черех `kubectl apply -f`

[Манифест для nginx](../nginx-manifest.yaml)

[Манифест для ClusterIp](../nginx-clusterip-manifest.yaml)

Осталось применить манифест для IngressRoute - именно на него смотрит Traefik.

В нем необходимо указать ваше доменное имя, которое было настроено в DNS сервере:
```yaml
- match: Host(`nginx-test.kube.ancored.ru`)
```

Также применяем манифест через `kubectl apply -f`

[Манифест для IngressRoute](../nginx-ingressroute.yaml)

Теперь мы можем сделать запрос на nginx через Traefik:
```sh
curl http://nginx-test.kube.ancored.ru # указать ваш домен
```

В ответ получаем приветствие от nginx.

# Настройка Traefik Dashboard

У traefik есть свой дашборд, который выключен по умолчанию. Чтобы его включить надо изменить параметры helm чарта:
```yaml
deployment:
  replicas: 3
ingressRoute:
  dashboard:
    enabled: true
    entryPoints: [web, websecure]
    matchRule: Host(`traefik.kube.ancored.ru`) # выбираем домен
```

После этого делаем апгрейд деплоя traefik:
```sh
helm upgrade traefik traefik/traefik --namespace traefik --values traefik-values.yaml
```

# Настройка SSL сертификатов

В следующих сериях, я заеблася..