FROM ghcr.io/scientist-softserv/dev-ops/samvera:f71b284f as hyku-base

USER app

COPY --chown=1001:101 $APP_PATH/Gemfile* /app/samvera/hyrax-webapp/
RUN sh -l -c " \
  bundle install --jobs "$(nproc)" && \
  sed -i '/require .enumerator./d' /usr/local/bundle/gems/oai-1.1.0/lib/oai/provider/resumption_token.rb && \
  sed -i '/require .enumerator./d' /usr/local/bundle/gems/edtf-3.0.6/lib/edtf.rb && \
  sed -i '/require .enumerator./d' /usr/local/bundle/gems/csl-1.6.0/lib/csl.rb"
COPY --chown=1001:101 $APP_PATH/bin/db-migrate-seed.sh /app/samvera/

COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp

ARG HYKU_BULKRAX_ENABLED="true"
RUN sh -l -c " \
  yarn install && \
  RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DATABASE_URL='postgresql://fake' bundle exec rake assets:precompile"

FROM hyku-base as hyku-worker
CMD ./bin/worker
