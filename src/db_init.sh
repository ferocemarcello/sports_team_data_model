sudo apt update
sudo apt install postgresql postgresql-contrib
sudo -i -u postgres
psql
ALTER USER postgres WITH PASSWORD 'postgres_pass';
CREATE DATABASE spond_db;
CREATE USER spond_user WITH PASSWORD 'spond_pass';
GRANT ALL PRIVILEGES ON DATABASE spond_db TO spond_user;
\q
exit

psql -h localhost -U spond_user -d spond_db