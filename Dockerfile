FROM ubuntu:17.10
MAINTAINER Doug Headley <headley.douglas@gmail.com>

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev
RUN apt-get install -y curl git

ENV CONFIGURE_OPTS --disable-install-rdoc

ENV RUBY_VERSION=2.4.2
RUN curl -O http://ftp.ruby-lang.org/pub/ruby/2.4/ruby-${RUBY_VERSION}.tar.gz && \
    tar -zxvf ruby-${RUBY_VERSION}.tar.gz && \
    cd ruby-${RUBY_VERSION} && \
    ./configure --disable-install-doc --enable-shared && \
    make && \
    make install && \
    cd .. && \
    rm -r ruby-${RUBY_VERSION} ruby-${RUBY_VERSION}.tar.gz && \
    echo 'gem: --no-document' > /usr/local/etc/gemrcdoc

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN gem install bundler

WORKDIR /tmp
ADD ./Gemfile Gemfile
ADD ./Gemfile.lock Gemfile.lock
RUN bundle install
ADD ./ /opt/party

WORKDIR /opt/party
RUN bundle install
CMD rackup
