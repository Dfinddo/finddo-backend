# Finddo - Backend

## Executando o Projeto

### Com Docker

- Executando pela primeira vez
  - `docker-compose build`
  - `docker-compose up`
- Executando outras vezes
  - `docker-compose up`
- Rodar as migrações
  - `docker-compose run --rm app bundle exec rails db:migrate`
- Rodar o seed
  - `docker-compose run --rm app bundle exec rails db:seed`
- Para rodar outros comandos rake
  - `docker-compose run --rm app bundle exec ` -comando a ser executado-

### Sem Docker

- Executando pela primeira vez
  - `bundle install` para instalar as dependências
  - `rails s`
- Executando outras vezes
  - `rails s`
- Rodar as migrações
  - `rails db:migrate`
- Rodar o seed
  - `rails db:seed`
