FROM octohost/octopress-nginx

WORKDIR /srv/www

ADD Gemfile /srv/www/Gemfile
ADD Gemfile.lock /srv/www/Gemfile.lock
RUN bundle install --quiet
ADD . /srv/www/

RUN locale-gen  en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN bundle exec rake generate

EXPOSE 80

CMD nginx
