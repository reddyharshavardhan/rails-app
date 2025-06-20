# Dockerfile
FROM ruby:3.2

# Install dependencies
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

WORKDIR /myapp

# Copy the Gemfiles and install
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the remaining app source
COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]