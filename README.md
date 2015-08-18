# app_api

My Sinatra/Rspec/Postgres/Api mash-up

####setup postgres with Sequel

CD into project directory and run the following in the command line:
    $ psql -d postgres -U <username> -f scripts/create_database_app_api.sql

# Then create tables

    $ sequel -m migrations postgres://<username>:<password>@localhost/app_api_development
    $ sequel -m migrations postgres://<username>:<password>@localhost/app_api_test

###### EDIT 'import_csv.sql' file and PUT IN the full location of 'appt_data.txt'

# Import CSV


    $ psql -d postgres -U westoncooper -f scripts/import_csv.sql

# to RUN
    $ rerun rackup
