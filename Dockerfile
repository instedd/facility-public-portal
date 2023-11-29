FROM ruby:2.7

# Cleanup expired Let's Encrypt CA (Sept 30, 2021)
RUN sed -i '/^mozilla\/DST_Root_CA_X3/s/^/!/' /etc/ca-certificates.conf && update-ca-certificates -f

# Update to a newer Debian version if needed
# The below lines are for Debian Stretch, consider updating to Buster or Bullseye
RUN echo 'deb http://deb.debian.org/debian/ buster main\n\
  deb http://security.debian.org/debian-security buster/updates main' > /etc/apt/sources.list

# Install Node.js (Consider updating Node.js version)
RUN apt-get -qq update && \
    apt-get -qq -y install apt-transport-https ca-certificates curl gnupg && \
    curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor | tee /usr/share/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_12.x buster main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get -qq update && \
    apt-get -qq install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Elm (Consider updating Elm version)
RUN cd /usr/local/bin && \
    curl -L "https://github.com/lydell/elm-old-binaries/releases/download/main/0.17.1-linux-x64.tar.gz" | tar xz --strip-components=1

WORKDIR /app

COPY Gemfile Gemfile.lock .
RUN bundle install --jobs 3 --deployment --without development test

# Update Elm package management commands if needed
COPY elm-package.json .
RUN git clone -b 4.0.2 https://github.com/thebritican/elm-autocomplete vendor/assets/elm/elm-autocomplete
RUN elm package install --yes

COPY . /app

RUN ./bin/precompile-assets.sh

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV PORT 80

EXPOSE $PORT

CMD bundle exec rails s -p $PORT -b '0.0.0.0'
