# Container image
FROM ruby:3.1.1

COPY . /usr/src/app

RUN cd /usr/src/app && bundle install

RUN chmod +x /usr/src/app/entrypoint.sh

ENTRYPOINT ["ruby", "/usr/src/app/app.rb"]