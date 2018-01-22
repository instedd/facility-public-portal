FROM ruby:2.3.1

RUN \
  apt-get update && \
  # node
  curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get install -y nodejs && \
  # elm
  npm install -g elm@0.17.1 --unsafe-perm=true --allow-root && \
  # clean
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install dependencies
RUN mkdir /app
WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install --jobs 3 --deployment --without development test
ADD elm-package.json /app/elm-package.json
RUN elm package install --yes

# Install the application
ADD . /app

# Precompile assets
RUN /bin/bash ./bin/precompile-assets.sh

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV PORT 80

EXPOSE $PORT

CMD bundle exec rails s -p $PORT -b '0.0.0.0'
