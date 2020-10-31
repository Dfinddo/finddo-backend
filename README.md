# Finddo - Backend

## Executando o Projeto

### Com Docker

- Executando pela primeira vez
  - `docker-compose build`
  - `docker-compose up`
  
- Executando outras vezes
  - `docker-compose up`
  
- Executando em background
  - `docker-compose up -d`


- Montando o banco de dados pela primeira vez
  - `docker-compose run --rm app bundle exec rails db:setup`

- Rodar as migrações
  - `docker-compose run --rm app bundle exec rails db:migrate`
  
- Rodar o seed
  - `docker-compose run --rm app bundle exec rails db:seed`
  
- Para rodar outros comandos rake
  - `docker-compose run --rm app bundle exec -comando a ser executado` 
  
  
OBS: Pode precisar de sudo


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


### Para dar push no heroku

- Checando se existe um remote chamado heroku
  - `git remote -v`
    - Caso não exista
      - `git remote add heroku https://git.heroku.com/nome_da_branch`

- Dando push
  - `git push heroku nome_da_branch:master`
    - Em caso de erros por falhas no git
      - `git push heroku nome_da_branch:master`

- Atualizar as migrations no banco associado ao heroku
  - `heroku run rails db:migrate`


### Referências documentais de APIs

- Wirecard (Procurar por Marketplace)
  - http://dev.wirecard.com.br/reference
