FROM instedd/nginx-rails:2.3

ARG SKIP_ASSETS_COMPILATION

RUN apt-get update && apt-get -y install npm && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN wget https://nodejs.org/dist/v4.6.0/node-v4.6.0-linux-x64.tar.xz \
    && tar -xvf node-v4.6.0-linux-x64.tar.xz \
    && ln -s /opt/node-v4.6.0-linux-x64/bin/node /usr/local/bin/node \
    && ln -s /opt/node-v4.6.0-linux-x64/bin/npm /usr/local/bin/npm \
    && npm install -g elm \
    && ln -s /opt/node-v4.6.0-linux-x64/lib/node_modules/elm/binwrappers/* /usr/local/bin/

WORKDIR /app

# Install gem bundle
ADD Gemfile /app/
ADD Gemfile.lock /app/
RUN bundle install --jobs 3 --deployment --without development test

# Default environment settings
ENV PUMA_OPTIONS "--preload -w 4"

# Install the application
ADD . /app

# Add config files
ADD docker/precompile-assets.sh /app/
ADD docker/runit-web-run /etc/service/web/run
ADD docker/database.yml /app/config/database.yml

# Precompile assets
RUN /bin/bash /app/precompile-assets.sh
