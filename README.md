# mruby-wheelcake

This is a fork of [mruby-shelf](https://github.com/katzer/mruby-shelf) and [mruby-yeah](https://github.com/katzer/mruby-yeah). The intention is to run it inside a mruby VM in a fork of redbean, [redbean-mruby](https://github.com/rguiscard/cosmopolitan/blob/master/README.mruby.md). Possible modification are:

* some more features (probably not much).
* removal of web server handler because this fork is intended to be used inside redbean web server. This may reduce dependencies.
* mostly work on mruby-yeah while keeping mruby-shelf untouched

----

# Shelf, a modular webserver interface for mruby 

Inspired by [Rack][rack], empowers [mruby][mruby], a work in progress!

> Rack provides a minimal, modular, and adaptable interface for developing web applications in Ruby. By wrapping HTTP requests and responses in the simplest way possible, it unifies and distills the API for web servers, web frameworks, and software in between (the so-called middleware) into a single method call.
>
> The exact details of this are described in the Rack specification, which all Rack applications should conform to.
>
> -- <cite>https://github.com/rack/rack</cite>

```ruby
Shelf::Builder.app do
  run ->(env) { [200, {}, ['A barebones shelf app']] }
end
```

## Installation

Add the line below to your `build_config.rb`:

```ruby
MRuby::Build.new do |conf|
  # ... (snip) ...
  conf.gem 'mruby-shelf'
end
```

Or add this line to your aplication's `mrbgem.rake`:

```ruby
MRuby::Gem::Specification.new('your-mrbgem') do |spec|
  # ... (snip) ...
  spec.add_dependency 'mruby-shelf'
end
```

## Builder

The Rack::Builder DSL is compatible with Shelf::Builder. Shelf uses [mruby-r3][mruby-r3] for the path dispatching to add some nice extras.

```ruby
app = Shelf::Builder.app do
  run ->(env) { [200, { 'content-type' => 'text/plain' }, ['A barebones shelf app']] }
end

app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/')
# => [200, { 'content-type' => 'text/plain' }, ['A barebones shelf app']]

app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/info')
# => [404, { 'content-type' => 'text/plain', 'X-Cascade' => 'pass' }, ['Not Found']]
```

Using middleware layers is dead simple:

```ruby
class NoContent
  def initialize(app)
    @app = app
  end

  def call(env)
    [204, @app.call(env)[1], []]
  end
end

app = Shelf::Builder.app do
  use NoContent
  run ->(env) { [200, { ... }, ['A barebones shelf app']] }
end

app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/')
# => [204, { ... }, []]
```

Mounted routes may contain slugs and can be restricted to a certain HTTP method:

```ruby
app = Shelf::Builder.app do
  get('/users/{id}') { run ->(env) { [200, { ... }, [env['shelf.request.query_hash'][:id]]] } }
end

app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/users/1')
# => [200, { ... }, ['1']]

app.call('REQUEST_METHOD' => 'PUT', 'PATH_INFO' => '/users/1')
# => [405, { ... }, ['Method Not Allowed']]
```

Routes can store any kind of additional data:

```ruby
app = Shelf::Builder.app do
  get('data', [Object.new]) { run ->(env) { [200, { ... }, env['shelf.r3.data']] } }
end

app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/data')
# => [200, { ... }, ['#<Object:0x007fd5739dfe40>']]
```

## Handler

The Rack::Handler class is mostly compatible with Shelf::Handler except that it takes the handler class instead of the path string.

```ruby
Shelf::Handler.register 'h2o', H2O::Shelf::Handler
```

Per default Shelf uses its built-in handler for [mruby-simplehttpserver][mruby-simplehttpserver]:

```ruby
Shelf::Handler.default
# => Shelf::Handler::SimpleHttpServer
```

Howver its possible to customize that:

```ruby
ENV['SHELF_HANDLER'] = 'h2o'
```

## Server

The Rack::Server API is mostly compatible with Shelf::Server except that there's no _config.ru_ file, built-in opt parser. Only the main options (:app, :port, :host, ...) are supported. Also note that :host and :port are written downcase!

```ruby
Shelf::Server.start(
  app: ->(e) {
    [200, { 'Content-Type' => 'text/html' }, ['hello world']]
  },
  server: 'simplehttpserver'
)
```

The default middleware stack can be extended per environment:

```ruby
Shelf::Server.middleware[:production] << MyCustomMiddleware
```

## Middleware

Shelf comes with some useful middlewares. These can be defined by app or by environment.

- ContentLength

  ```ruby
  app = Shelf::Builder.app do
    use Shelf::ContentLength
    run ->(env) { [200, {}, ['A barebones shelf app']] }
  end

  app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/')
  # => [200, { 'Content-Length' => 21 }, ['A barebones shelf app']]
  ```

- ContentType

  ```ruby
  app = Shelf::Builder.app do
    use Shelf::ContentLength
    use Shelf::ContentType, 'text/plain'
    run ->(env) { [200, {}, ['A barebones shelf app']] }
  end

  app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/')
  # => [200, { 'Content-Length' => 21, 'Content-Type' => 'text/plain' }, ['A barebones shelf app']]
  ```

- QueryParser

  ```ruby
  app = Shelf::Builder.app do
    map('/users/{id}') do
      use Shelf::QueryParser
      run ->(env) { [200, env['shelf.request.query_hash'], []] }
    end
  end

  app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/users/1', 'QUERY_STRING' => 'field=age&field=name')
  # => [200, { 'id' => '1', 'field' => ['age', 'name'] }, []]
  ```

- Head

  ```ruby
  app = Shelf::Builder.app do
    use Shelf::Head
    run ->(env) { [200, {}, ['A barebones shelf app']] }
  end

  app.call('REQUEST_METHOD' => 'HEAD', 'PATH_INFO' => '/')
  # => [200, { 'Content-Length' => 21 }, []]
  ```

- Static

  ```ruby
  app = Shelf::Builder.app do
    use Shelf::Static, urls: { '/' => 'index.html' }, root: 'public'
    run ->(env) { [200, {}, ['A barebones shelf app']] }
  end

  app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/')
  # => [200, { 'Content-Length' => xxx, 'Content-Type' => 'text/html; charset=utf-8' }, ['<html>...</html>']]
  ```

  - See [here][static] for more samples
  - Requires [mruby-io][mruby-io]

- Logger

  ```ruby
  app = Shelf::Builder.app do
    use Shelf::Logger, Logger::INFO
    run ->(env) { [200, {}, [Log-Level: "#{env['shelf.logger'].level}"] }
  end

  app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/')
  # => [200, {}, ['Log-Level: 1']]
  ```

  - Writes to `env[SHELF_ERRORS]` which is _$stderr_ by default
  - Requires [mruby-logger][mruby-logger]

- CommonLogger

  ```ruby
  app = Shelf::Builder.app do
    use Shelf::CommonLogger, Logger.new
    run ->(env) { [200, {}, ['A barebones shelf app']] }
  end

  app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/index.html')
  # => 127.0.0.1 - [23/05/2017:18:03:36 +0200] "GET /index.html HTTP/1.1" 200 2326
  ```

  - Requires [mruby-logger][mruby-logger], mruby-time and mruby-sprintf

- CatchError

  ```ruby
  app = Shelf::Builder.app do
    use Shelf::CatchError
    run ->(env) { undef_method_call }
  end

  app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/')
  # => [500, { 'Content-Length' => 21, 'Content-Type' => 'text/plain' }, ['Internal Server Error']]
  ```

  - Requires [mruby-io][mruby-io]
  - Writes all expection traces to `env[SHELF_ERRORS]`
  - Response body contains the stack trace under development mode

- Deflater

  ```ruby
  app = Shelf::Builder.app do
    use Shelf::Deflater
    run ->(env) { [200, {}, ['A barebones shelf app']] }
  end

  app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/', 'Accept-Encoding' => 'gzip')
  # => [200, { 'Content-Encoding' => 'gzip', ... }, ['...']]
  ```

  - Requires [mruby-shelf-deflater][mruby-shelf-deflater]
  - Supported compression algorithms are `gzip`, `deflate` and `identity`

## Development

Clone the repo:
    
    $ git clone https://github.com/katzer/mruby-shelf.git && cd mruby-shelf/

Compile the source:

    $ rake compile

Run the tests:

    $ rake test

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/katzer/mruby-shelf.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors

- Sebastián Katzer, Fa. appPlant GmbH

## License

The mgem is available as open source under the terms of the [MIT License][license].

Made with :yum: in Leipzig

© 2017 [appPlant GmbH][appplant]

[rack]: https://github.com/rack/rack
[mruby]: https://github.com/mruby/mruby
[mruby-r3]: https://github.com/katzer/mruby-r3
[mruby-logger]: https://github.com/katzer/mruby-logger
[mruby-io]: https://github.com/iij/mruby-io
[mruby-shelf-deflater]: https://github.com/katzer/mruby-shelf-deflater
[mruby-simplehttpserver]: https://github.com/matsumotory/mruby-simplehttpserver
[static]: mrblib/shelf/static.rb#L31
[license]: http://opensource.org/licenses/MIT
[appplant]: www.appplant.de

------

<p align="center">
    <img src="logo.png">
</p>

__Yeah!__ is a DSL for quickly creating [shelf applications][shelf] in [mruby][mruby] with minimal effort:

```ruby
# mrblib/your-mrbgem.rb

extend Yeah::DSL                                      |   extend Yeah::DSL
                                                      |
set port: 3000                                        |   opt(:port) { |port| set port: port }
                                                      |
get '/hi/{name}' do |name|                            |   get '/hi' do
  "Hi #{name}"                                        |     "Hi #{params['name'].join(' and ')}"
end                                                   |   end
```

```sh
$ your-mrbgem &                                       |   $ your-mrbgem --port 8080 & 
Starting application at http://localhost:3000         |   Starting application at http://localhost:8080
                                                      |
$ curl 'localhost:3000/hi/Ben'                        |   $ curl 'localhost:8080/hi?name=Tom&name=Jerry'
Hi Ben                                                |   Hi Tom and Jerry
```

## Installation

Add the line below to your `build_config.rb`:

```ruby
MRuby::Build.new do |conf|
  # ... (snip) ...
  conf.gem 'mruby-yeah'
end
```

Or add this line to your aplication's `mrbgem.rake`:

```ruby
MRuby::Gem::Specification.new('your-mrbgem') do |spec|
  # ... (snap) ...
  spec.add_dependency 'mruby-yeah'
end
```

## Routes

In Yeah!, a route is an HTTP method paired with a URL-matching pattern. Each route is associated with a block:

```ruby
post '/' do
  .. create something ..
end
```

Routes are matched in the order they are defined. The first route that matches the request is invoked.

Routes with trailing slashes are __not__ different from the ones without:

```ruby
get '/foo' do
  # Does match "GET /foo/"
end
```

Use `root` to specify the default entry point:

```ruby
# Redirect "GET /" to "GET /public/index.html"
root '/public/index.html'
```

Route patterns may include named parameters, accessible via the `params` hash:

```ruby
# matches "GET /hello/foo" and "GET /hello/bar"
get '/hello/{name}' do
  # params[:name] is 'foo' or 'bar'
  "Hello #{params[:name]}!"
end
```

You can also access named parameters via block parameters:

```ruby
# matches "GET /hello/foo" and "GET /hello/bar"
get '/hello/{name}' do |name|
  # params[:name] is 'foo' or 'bar'
  # name stores params[:name]
  "Hello #{name}!"
end
```

Routes may also utilize query parameters:

```ruby
# matches "GET /posts?title=foo&author=bar"
get '/posts' do
  title  = params['title']
  author = params['author']
end
```

Route matching with Regular Expressions:

```ruby
get '/blog/post/{id:\\d+}' do |id|
  post = Post.find(id)
end
```

Support for regular expression requires __mruby-regexp-pcre__ to be installed before mruby-yeah!

Routes can also be defined to match any HTTP method:

```ruby
# matches "GET /" and "PUT /" and ...
route '/', R3::ANY do
  request[Shelf::REQUEST_METHOD]
end
```

Last but not least its possible to get a list of all added HTTP routes:

```ruby
routes # => ['GET /blog/post/{id}']
```

## Response

Each routing block is invoked within the scope of an instance of `Yeah::Controller`. The class provides access to methods like `request`, `params`, `logger` and `render`.

- `request` returns the Shelf request and is basically a hash.

```ruby
get '/' do
  request # => { 'REQUEST_METHOD' => 'GET', 'REQUEST_PATH' => '/', 'User-Agent' => '...' }
end
```

- `params` returns the query params and named URL params. Query params are accessible by string keys and named params by symbol.

```ruby
# "GET /blogs/b1/posts/p1?blog_id=b2"
get '/blogs/{blog_id}/posts/{post_id}' do
  params # => { blog_id: 'b1', post_id: 'p1' }
end
```

- `logger` returns the query params and named URL params. Query params are accessible by string keys and named params by symbol. Dont forget to include the required middleware!

```ruby
use Shelf::Logger

get '/' do
  logger # => <Logger:0x007fae54987308>
end
```

- `render` returns a well-formed shelf response. The method allows varoius kind of invokation:

```ruby
get '/500' do                     |   get '/yeah' do
  render 500                      |     render html: '<h1>Yeah!</h1>'
end                               |   end
                                  |
get '/say_hi' do                  |   post '/api/stats' do
  render 'Hi'                     |     render json: Stats.create(params), status: 201, headers: {...}
end                               |   end
                                  |
get '/say_hello' do               |   get '/' do
  'Hello'                         |     render redirect: 'public/index.html'
end                               |   end
```

## Controller

Instead of a code block to execute a route also accepts an controller and an action similar to Rails.

```ruby
class GreetingsController < Yeah::Controller
  def greet(name)
    render "Hello #{name.capitalize}"
  end
end

Yeah.application.routes.draw do
  get 'greet/{name}', to: 'greetings#greet'
end

Yeah.application.configure :production do
  log_folder '/logs', 'iss.log', 'iss.err'
end

Yeah.application.run! port: 3000
```

## Command Line Arguments

Yeah! ships with a small opt parser. Each option is associated with a block:

```ruby
# matches "your-mrbgem --port 80" or "your-mrbgem -p 80"
opt :port, :int, 8080 do |port|
  # port is 80
  set :port, port
end
```

Opts can have a default value. The block will be invoked in any case either with the command-line value, its default value or just _nil_.

Sometimes however it is intended to only print out some meta informations for a single given option and then exit without starting the server:

```ruby
# matches "your-mrbgem --version" or "your-mrbgem -v"
opt! :version do
  # prints 'v1.0.0' on STDOUT and exit
  'v1.0.0'
end
```

## Configuration

Run once, at startup, in any environment:

```ruby
configure do
  # setting one option
  set :option, 'value'
  # setting multiple options
  set a: 1, b: 2
  # same as `set :option, true`
  enable :option
  # same as `set :option, false`
  disable :option
end
```

Run only when the environment (`SHELF_ENV` environment variable) is set to `production`:

```ruby
configure :production do
  ...
end
```

Run only when the environment is set to either `development` or `test`:

```ruby
configure :development, :test do
  ...
end
```

You can access those options via `settings`:

```ruby
configure do
  set :foo, 'bar'
end

get '/' do
  settings[:foo] # => 'bar'
end
```

## Shelf Middleware

Yeah! rides on [Shelf][shelf], a minimal standard interface for mruby web frameworks. One of Shelf's most interesting capabilities for application developers is support for "middleware" -- components that sit between the server and your application monitoring and/or manipulating the HTTP request/response to provide various types of common functionality.

Sinatra makes building Rack middleware pipelines a cinch via a top-level `use` method:

```ruby
use Shelf::CatchError
use MyCustomMiddleware

get '/hello' do
  'Hello World'
end
```

The semantics of `use` are identical to those defined for the [Shelf::Builder][builder] DSL. For example, the use method accepts multiple/variable args as well as blocks:

```ruby
use Shelf::Static, urls: ['/public'], root: ENV['DOCUMENT_ROOT']
```

Shelf is distributed with a variety of standard middleware for logging, debugging, and URL routing. Yeah! uses many of these components automatically based on configuration so you typically don't have to use them explicitly.

## Server

Yeah! works with any Shelf-compatible web server. Right now these are _mruby-simplehttpserver_ and _mruby-heeler_:

```ruby
set :server, 'simplehttpserver' # => Default
```

However its possible to register handlers for other servers. See [here][server] for more info.

## Development

Clone the repo:
    
    $ git clone https://github.com/katzer/mruby-yeah.git && cd mruby-yeah/

Compile the source:

    $ rake compile

Run the tests:

    $ rake test

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/katzer/mruby-yeah.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors

- Sebastián Katzer, Fa. appPlant GmbH

## License

The mgem is available as open source under the terms of the [MIT License][license].

Made with :yum: in Leipzig

© 2017 [appPlant GmbH][appplant]

[shelf]: https://github.com/katzer/mruby-shelf
[mruby]: https://github.com/mruby/mruby
[builder]: https://github.com/katzer/mruby-shelf/blob/master/mrblib/shelf/builder.rb
[server]: https://github.com/katzer/mruby-shelf#handler
[license]: http://opensource.org/licenses/MIT
[appplant]: www.appplant.de
