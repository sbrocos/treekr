FROM ruby:4.0-slim

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install

COPY . .

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "config.ru", "--host", "0.0.0.0", "--port", "4567"]
