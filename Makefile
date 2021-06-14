PHP_SERVICE := php
SUPPORTED_COMMANDS := require require-dev remove add
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

start:
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

stop:
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml down

stop-v:
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v

logs:
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f

build:
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml build

build-n:
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml build --no-cache

dev:
	@make start
	@make logs

cli:
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec php bash

install:
	@docker-compose exec -e COMPOSER_MEMORY_LIMIT=-1 -T $(PHP_SERVICE) composer install
	@docker-compose exec -T $(PHP_SERVICE) yarn install

update:
	@docker-compose exec -e COMPOSER_MEMORY_LIMIT=-1 -T $(PHP_SERVICE) composer update
	# @docker-compose exec -T $(PHP_SERVICE) yarn upgrade

require:
	@docker-compose exec -e COMPOSER_MEMORY_LIMIT=-1 -T $(PHP_SERVICE) composer require $(COMMAND_ARGS)

add:
	@docker-compose exec -T $(PHP_SERVICE) yarn add $(COMMAND_ARGS)

require-dev:
	@docker-compose exec -e COMPOSER_MEMORY_LIMIT=-1 -T $(PHP_SERVICE) composer require $(COMMAND_ARGS) --dev

remove:
	@docker-compose exec -e COMPOSER_MEMORY_LIMIT=-1 -T $(PHP_SERVICE) composer remove $(COMMAND_ARGS)

migration:
	@docker-compose exec -T $(PHP_SERVICE) php bin/console make:migration

migrate:
	@make migration
	@docker-compose exec -T $(PHP_SERVICE) php bin/console doctrine:migration:migrate -n

test:
	@docker-compose exec -T $(PHP_SERVICE) bash -c "composer install --no-progress --no-suggest ; wait-for-it -t 120 db:3306 -- php bin/console doctrine:migrations:migrate -n ; php bin/console hautelook:fixtures:load -n ; php bin/phpunit --coverage-clover tests_logs/coverage.clover --log-junit tests_logs/junit.xml"

entity:
	@docker-compose exec -T $(PHP_SERVICE) php bin/console make:entity

entity-r:
	@docker-compose exec -T $(PHP_SERVICE) php bin/console make:entity --regenerate --overwrite

cache:
	@docker-compose exec -T $(PHP_SERVICE) php bin/console cache:clear

restartencore:
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml restart encore

rebuildsass:
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec -T $(PHP_SERVICE) npm rebuild node-sass
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec encore npm rebuild node-sass
	@make restartencore