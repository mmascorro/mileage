FROM ruby:2.6.3
RUN mkdir /app
COPY Gemfile* /
RUN bundle install
WORKDIR /app
