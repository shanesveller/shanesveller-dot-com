FROM ruby:2.1

WORKDIR /octopress

ADD Gemfile /octopress/Gemfile
ADD Gemfile.lock /octopress/Gemfile.lock
RUN bundle install --system
ADD . /octopress/

VOLUME /octopress/public

CMD bundle exec rake generate
