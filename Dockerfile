FROM ruby:3.3
RUN apt-get update && apt-get install -y nodejs npm && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile* /app/
RUN bundle install
COPY package.json package-lock.json* /app/
RUN npm i
COPY . /app
EXPOSE 4000
CMD ["bash","-lc","bundle exec jekyll serve --host 0.0.0.0 --livereload"]
