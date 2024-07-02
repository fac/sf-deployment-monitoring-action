# Container image
FROM public.ecr.aws/docker/library/ruby:3.1.1

COPY . /usr/src/app

RUN cd /usr/src/app && bundle install

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
