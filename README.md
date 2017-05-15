# sprockets-less

**Better Less integration with [Sprockets 2.x and 3.x](http://github.com/sstephenson/sprockets)**

[![Build Status](https://travis-ci.org/lloeki/sprockets-less.svg?branch=master)](https://travis-ci.org/lloeki/sprockets-less)

When using Sprockets 2.x or 3.x with Less you will eventually run into a pretty big issue. `//= require` directives will not allow Less mixins, variables, etc. to be shared between files. So you'll try to use `@import`, and that'll also blow up in your face. `sprockets-less` aims to fix this.

_Note: If you use Rails 3.1, you may want to use the [less-rails gem](http://github.com/rails/less-rails). But if you want to use Sprockets and Less anywhere else, like Sinatra, use `sprockets-less`._

## Usage

In your Rack application, setup Sprockets as you normally would, and require "sprockets-less":

``` ruby
require "sprockets"
require "sprockets-less"
require "less"

map "/assets" do
  environment = Sprockets::Environment.new
  environment.append_path "assets/stylesheets"
  run environment
end

map "/" do
  run YourRackApp
end
```

## Configuration

If you would like to configure any of the Less options, you can do so like this:

```ruby
Sprockets::Less.options[:compress] = true
```

## Import Hooks

Any `@import` to a `.less` file will automatically declare that file as a sprockets dependency to the file importing it. This means that you can edit imported framework files and see changes reflected in the parent durning development. So this:

```css
@import "frameworks/bootstrap/mixins";

#leftnav { .border-radius(5px); }
```

Will end up acting as if you had done this below:

```css
/*
 *= depend_on "frameworks/bootstrap/mixins.less"
*/

@import "frameworks/bootstrap/mixins";

#leftnav { .border-radius(5px); }
```

## Helpers

*Warning: this is currently non-functional*

When referencing assets use the following helpers in LESS.

```css
asset-path(@relative-asset-path)  /* Returns a string to the asset. */
asset-path("rails.png")           /* Becomes: "/assets/rails.png" */

asset-url(@relative-asset-path)   /* Returns url reference to the asset. */
asset-url("rails.png")            /* Becomes: url(/assets/rails.png) */
```

As a convenience, for each of the following asset classes there are corresponding `-path` and `-url` helpers image, font, video, audio, javascript and stylesheet. The following examples only show the `-url` variants since you get the idea of the `-path` ones above.

```css
image-url("rails.png")            /* Becomes: url(/assets/rails.png) */
font-url("rails.ttf")             /* Becomes: url(/assets/rails.ttf) */
video-url("rails.mp4")            /* Becomes: url(/videos/rails.mp4) */
audio-url("rails.mp3")            /* Becomes: url(/audios/rails.mp3) */
javascript-url("rails.js")        /* Becomes: url(/assets/rails.js) */
stylesheet-url("rails.css")       /* Becomes: url(/assets/rails.css) */
```

Lastly, we provide a data url method for base64 encoding assets.

```css
asset-data-uri("rails.png")       /* Becomes: url(data:image/png;base64,iVBORw0K...) */
```

Please note that these helpers are only available server-side, and something like ERB templates should be used if client-side rendering is desired.


## License

Sprocket::Less is released under the MIT license. See LICENSE file for details.
