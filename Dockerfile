FROM ruby:2.1

RUN apt-get update -qq && apt-get -y install locales && rm -rf /var/lib/apt/lists/*
RUN dpkg-reconfigure -fnoninteractive locales && \
    locale-gen en_US en_US.UTF-8 && \
    /usr/sbin/update-locale en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

WORKDIR /octopress

ADD Gemfile /octopress/Gemfile
ADD Gemfile.lock /octopress/Gemfile.lock
RUN bundle install --system
ADD . /octopress/

VOLUME /octopress/public

CMD bundle exec rake generate
