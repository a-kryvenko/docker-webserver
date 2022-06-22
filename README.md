# Вебсервер на контейнерах Docker.

Описание процесса создания доступно на **[habr.com](https://habr.com/ru/post/670938/)**.

В состав входят:
- MySQL
- PHP
- Nginx
- msmtp
- composer
- letsencrypt SSL сертификаты
- резервное копирование в облако

## Перед началом работы

1. **[Подготовить](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04)** сервер
2. **[Установить](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04)** **docker**
3. **[Установить](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-22-04)** **docker-compose**

## Порядок установки:

### 1. Клонируем репозиторий

~~~
git clone git@github.com:a-kryvenko/docker-website.git .
~~~

### 2. Копируем файл с переменными окружения:

~~~
cp .env.example .env
~~~

### 3. В файле .env указываем значения для переменных

<details>
    <summary><b>Описание переменных</b></summary>
    <ul>
        <li><b>COMPOSE_FILE</b> - какие файлы docker-compose подключаем. Отличаются для dev и production окружений;</li>
        <li><b>SYSTEM_GROUP_ID</b> - ID группы пользователя хоста, от имени которого работаем с сервером. Обычно 1000;</li>
        <li><b>SYSTEM_USER_ID</b> - ID группы пользователя хоста, от имени которого работаем с сервером. Обычно 1000;</li>
        <li><b>APP_NAME</b> - <b>url</b>, по которому доступен сайт. Например, <b>example.com</b> или <b>example.local</b> для локальной разработки;</li>
        <li><b>ADMINISTRATOR_EMAIL</b> - email, на который отправляем информацию о сертификатах;</li>
        <li><b>DB_HOST</b> - хост базы данных. По умолчанию <b>db</b>, но в случае, когда база данных на другом сервере - указываем адрес сервера;</li>
        <li><b>DB_DATABASE</b> - название базы данных;</li>
        <li><b>DB_USER</b> - имя пользователя, который работает с базой данных;</li>
        <li><b>DB_USER_PASSWORD</b> - пароль пользователя базы данных;</li>
        <li><b>DB_ROOT_PASSWORD</b> - пароль <b>root</b> пользователя базы данных;</li>
        <li><b>AWS_S3_URL</b> - <b>url</b> облачного хранилища бэкапов;</li>
        <li><b>AWS_S3_BUCKET</b> - название бакета в хранилище бэкапов;</li>
        <li><b>AWS_S3_ACCESS_KEY_ID</b> - ключ к хранилищу;</li>
        <li><b>AWS_S3_SECRET_ACCESS_KEY</b> - пароль к хранилищу;</li>
        <li><b>AWS_S3_LOCAL_MOUNT_POINT</b> - путь к локальной папке, в которую монтируем облачное хранилище;</li>
        <li><b>MAIL_SMTP_HOST</b> - smpt хост для отправки почты, например <b>smtp.gmail.com</b>;</li>
        <li><b>MAIL_SMTP_PORT</b> - smpt порт. По умолчанию 25;</li>
        <li><b>MAIL_SMTP_USER</b> - имя пользователя smpt;</li>
        <li><b>MAIL_SMTP_PASSWORD</b> - пароль smtp.</li>
    </ul>
</details>

Отдельно стоит упомянуть **COMPOSE_FILE**. В зависимости от того, в каком окружении 
мы запускаем сайт - нам нужны разные сервисы. К примеру, локально - нам 
нужен только базовый и облако для бэкапов:

> compose-app.yml:compose-cloud.yml

Для **dev** сайта - бэкапы и https:

> compose-app.yml:compose-https.yml:compose-cloud.yml

Для **production** - весь набор:
> compose-app.yml:compose-https.yml:compose-cloud.yml:compose-production.yml

### 4. Собираем образы и запускаем наш сервер

~~~
docker-compose build \  
docker-compose up -d
~~~

### 5. Если мы используем https, то запускаем скрипт для получения сертификатов

~~~
./cgi-bin/prepare-certbot.sh
~~~

### 6. Инициализируем crontab

~~~ 
./cgi-bin/prepare-crontab.sh
~~~
