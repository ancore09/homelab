# Установка Vault

Руководство по установке Vault.

**Официальная документация**: https://developer.hashicorp.com/vault

## Установка

### 1. Развертывание сервисов

```sh
docker compose pull
docker compose up -d postgres
docker compose up -d vault
```

### 2. Инициализация Vault

Выполняем команду для генерации ключей и root токена:
```sh
docker exec vault vault operator init -key-shares=5 -key-threshold=3
```

После выполнения мы увидим следующий вывод:
```sh
Unseal Key 1: <key-1>
Unseal Key 2: <key-2>
Unseal Key 3: <key-3>
Unseal Key 4: <key-4>
Unseal Key 5: <key-5>

Initial Root Token: <root-token>
```

Unseal ключи используются для расшифровки хранилища Vault после рестарта. 
Root токен используется для аутентификации под root пользователем.

### 3. Вход в UI

Переходим на `http://ip:8200`, чтобы попасть в UI Vault.

Так как это первый запуск, то Vault потребует Unseal ключи. Вводим один за одним любые 3 ключа из шага 2.

После этого входим под root пользователем, используя токен из шага 2.

Все, Vault готов к использованию.

⚠️ **Важно**: После каждого рестарта необходимо проводить процедуру unseal заново.
