# University of Louisville
----
## Table of Contents
  * [Running the stack](#running-the-stack)
    * [Important URL's](#important-urls)
    * [Dory](#dory)
    * [With Docker](#with-docker)
      * [Install Docker](#install-docker)
      * [Start the server](#start-the-server)
      * [Seed the database](#seed-the-database)
      * [Access the container](#access-the-container)
      * [Stop the app and services](#stop-the-app-and-services)
      * [Troubleshooting](#troubleshooting)
      * [Rubocop](#rubocop)
  * [Admin User](#admin-user)
  * [Bulkrax](#importing)
    * [Enable Bulkrax](#enable-bulkrax)
    * [Disable Bulkrax](#disable-bulkrax)
    * [Importing](#importing)
    * [Exporting](#exporting)
----

## Running the stack
### Important URL's
- Local site:
  - With dory: single.hyku.test
  - Without dory: localhost:3000
- Staging site: http://lv-hyku-staging.notch8.cloud/
- Production site: https://hyku.library.louisville.edu/
  - The server credentials are in 1Password
- Solr: http://solr.hyku.test
  - Check the `SOLR_ADMIN_USER` and `SOLR_ADMIN_PASSWORD` in "docker-compose.yml"
- Sidekiq: http://single.hyku.test/sidekiq

### Dory
On OS X or Linux we recommend running [Dory](https://github.com/FreedomBen/dory). Be sure to [adjust your ~/.dory.yml file to support the .test tld](https://github.com/FreedomBen/dory#config-file).

You can still run in development via docker with out Dory, but to do so please uncomment the ports section in docker-compose.yml

```bash
gem install dory
dory up
```

### Stack Car
stack_car is optional, but all instructions will be given using this gem. If you choose not to use stack_car, please use the docker-compose equivalents.

```bash
gem install stack_car
```

### With Docker
We distribute two configuration files:
- `docker-compose.yml` is set up for development / running the specs
- `docker-compose.production.yml` is for running the Hyku stack in a production setting

#### Install Docker
- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in

#### If this is your first time working in this repo or the Dockerfile has been updated you will need to pull your services first
  ```bash
  sc pull
  sc build
  ```

#### Start the server
```bash
sc up
```
This command starts the web and worker containers allowing Rails to be started or stopped independent of the other services. Once that starts (you'll see the line `Listening on tcp://0.0.0.0:3000` to indicate a successful boot), you can view your app at one of the [dev URL's](#important-urls) above.

#### Seed the database
```bash
sc be rails db:seed
```

#### Access the container
- In a separate terminal window or tab than the running server, run:
  ``` bash
  sc sh
  ```

- You need to be inside the container to:
  - Access the rails console for debugging
  ``` bash
  rails c
  ```

  - Run [rspec](https://github.com/rspec/rspec-rails/tree/4-1-maintenance#running-specs)
  ``` bash
  rspec
  ```

  - Recompile the assets
  ``` bash
  RAILS_ENV=development bundle exec rake assets:precompile
  ```

#### Stop the app and services
- Press `Ctrl + C` in the window where `sc up` is running
- When that's done `sc stop` shuts down the running containers
- `dory down` stops Dory

#### Troubleshooting
- Was the Dockerfile changed on your most recent `git pull`? Refer to the instructions above
- Double check your dory set up
- Do migrations need to be run?
  ``` bash
  sc be rails db:migrate
  ```
- Do seeds need to be run?
  ``` bash
  sc be rails db:seed
  ```

- Issue: Sidekiq isn't working (e.g.: importer/exporter status stays stuck at "pending")
  - Try:
    ``` bash
    sc sh
    sidekiq
    ```

- Issue: Assets don't display correctly (e.g. the text on the homepage is all jumbled)
  - Try:
    ``` bash
    dc down -v
    sc build
    sc up
    ```
    Then recompile the assets using [these instructions](#access-the-containers)

- Issue: No default admin set
  - Try:
    - make sure you're signed in with the user defined at `ENV['INITIAL_ADMIN_EMAIL']`
    ``` bash
    user = User.find_or_create_by(email: ENV['INITIAL_ADMIN_EMAIL'])
    user.is_superadmin
    # if the above returns false, make your user a superadmin
    # which is what is should have been already because of the seeds
    user.add_role(:superadmin)
    ```
    - if that doesn't work, use hyku.test instead of single.hyku.test

- You can't access hyku.test/sidekiq
  - Try: comment out the do block around `mount Sidekiq::Web => '/sidekiq'` in routes.rb

#### Rubocop
Rubocop can be run in docker locally using either of the options below:
- Outside the container:
  ```bash
  sc be rake
  ```
- With autocorrect: (learn about the `-a` flag [here](https://docs.rubocop.org/rubocop/usage/basic_usage.html#auto-correcting-offenses))
  ```bash
  sc exec rubocop -a
  ```
- Inside the container:
  ```bash
  rubocop -a
  ```

## Admin User
This is for the admin login on the Shared Research Repository page or when logging in to a specific tenant
- Local: `INITIAL_ADMIN_EMAIL` and `INITIAL_ADMIN_PASSWORD` in ".env"
- Staging: `INITIAL_ADMIN_EMAIL` and `INITIAL_ADMIN_PASSWORD` in "staging-deploy.yaml"

## Bulkrax
### Enable Bulkrax:
- Change `HYKU_BULKRAX_ENABLED` to `true` in ".env"
- Change `//require bulkrax/application` to `//= require bulkrax/application` in "application.js"
- Change `require bulkrax/application` to `*= require bulkrax/application` in "application.css"
- Change `HYKU_BULKRAX_ENABLED` to `true` in "docker-compose.yml" (it's in there more than once)
- Change the value under `name: HYKU_BULKRAX_ENABLED` to `true` in "staging-deploy.yaml" (it's in there more than once)
- Restart the server

### Disable Bulkrax:
- Revert each of the changes above
- Restart the server

### Importing
- Use the "tmp" folder to organize any csv's and their related files
  e.g.
  ``` bash
  mkdir tmp/yearbooks < -- this is where the csv will live
  mkdir tmp/yearbooks/files < -- this is where the associated files will live
  ```
- Choose "Importers" from the left navbar on the dashboard
- Click "New"
- Fill in the required fields
  (Refer to this [Wiki article](https://github.com/samvera-labs/bulkrax/wiki/Bulkrax-User-Interface---Importers) for more details about the fields and save options)
- Select the "CSV" parser option
- Choose the "Specify a path on the server" radio button
- Use a path to a csv in the tmp folder
  e.g.
  ``` bash
  /app/samvera/hyrax-webapp/tmp/yearbooks/1999.csv
  ```

### Exporting
``` bash
# TODO(alishaevn): fill this out if/when necessary
```