require 'spec_helper'

describe Sprockets::Less do
  before :each do
    @root = create_construct
    @assets = @root.directory 'assets'
    @public_dir = @root.directory 'public'
    @env = Sprockets::Environment.new @root.to_s
    @env.append_path @assets.to_s
    @env.register_postprocessor 'text/css', FailPostProcessor

    Sprockets::Helpers.configure do |config|
      config.environment = @env
      config.prefix      = "/assets"
      config.digest      = false
      config.public_path = @public_dir

      # Force to debug mode in development mode
      # Debug mode automatically sets
      # expand = true, digest = false, manifest = false
    #  config.debug       = true
    end
  end

  after :each do
    @root.destroy!
  end

  it 'processes scss files normally' do
    @assets.file 'main.css.less', '//= require "dep"'
    @assets.file 'dep.css.less', 'body{ color: blue; }'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue;\n}\n")
  end

  if Sprockets::Less::Utils.version_of_sprockets < 4
    it 'processes scss files normally without the .css extension' do
      @assets.file 'main.less', '//= require dep'
      @assets.file 'dep.less', 'body { color: blue; }'
      asset = @env['main']
      expect(asset.to_s).to eql("body {\n  color: blue;\n}\n")
    end
  end

  it 'processes sass files normally' do
    @assets.file 'main.css.less', '//= require dep'
    @assets.file 'dep.css.less', 'body { color: blue; }'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: blue;\n}\n")
  end

  it 'imports standard files' do
    @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
    @assets.file 'dep.css.less', '@color: blue;'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: #0000ff;\n}\n")
  end

  it 'imports partials' do
    @assets.file 'main.css.less', %(@import "_dep";\nbody { color: @color; })
    @assets.file '_dep.css.less', '@color: blue;'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: #0000ff;\n}\n")
  end

  it 'imports files with the correct content type' do
    @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
    @assets.file 'dep.js', 'var app = {};'
    @assets.file '_dep.css.less', '@color: blue;'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: #0000ff;\n}\n")
  end

  it 'imports files with directives' do
    @assets.file 'main.css.less', %(@import "dep";)
    @assets.file 'dep.css', "/*\n *= require subdep\n */"
    @assets.file 'subdep.css.less', "@color: blue;\nbody { color: @color; }"
    asset = @env['main.css']
    expect(asset.to_s).to include("body {\n  color: #0000ff;\n}\n")
  end

  it 'imports files with additional processors' do
    @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
    @assets.file 'dep.css.less.erb', "@color: <%= 'blue' %>;"
    asset = @env['main.css.less']
    expect(asset.to_s).to eql("body {\n  color: #0000ff;\n}\n")
  end

  it 'imports relative files' do
    @assets.file 'folder/main.css.less', %(@import "./dep-1";\n@import "./subfolder/dep-2";\nbody { background-color: @background-color; color: @color; })
    @assets.file 'folder/dep-1.css.less', '@background-color: red;'
    @assets.file 'folder/subfolder/dep-2.css.less', '@color: blue;'
    asset = @env['folder/main.css']
    expect(asset.to_s).to eql("body {\n  background-color: #ff0000;\n  color: #0000ff;\n}\n")
  end

  it 'imports relative partials' do
    @assets.file 'folder/main.css.less', %(@import "./dep-1";\n@import "./subfolder/dep-2";\nbody { background-color: @background-color; color: @color; })
    @assets.file 'folder/_dep-1.css.less', '@background-color: red;'
    @assets.file 'folder/subfolder/_dep-2.css.less', '@color: blue;'
    asset = @env['folder/main.css']
    expect(asset.to_s).to eql("body {\n  background-color: #ff0000;\n  color: #0000ff;\n}\n")
  end

  it 'imports deeply nested relative partials' do
    @assets.file 'package-prime/stylesheets/main.css.less', %(@import "package-dep/src/stylesheets/variables";\nbody { background-color: @background-color; color: @color; })
    @assets.file 'package-dep/src/stylesheets/_variables.css.less', %(@import "./colors";\n@background-color: red;)
    @assets.file 'package-dep/src/stylesheets/_colors.css.less', '@color: blue;'
    asset = @env['package-prime/stylesheets/main.css.less']
    expect(asset.to_s).to eql("body {\n  background-color: #ff0000;\n  color: #0000ff;\n}\n")
  end

    it 'imports relative files without preceding ./' do
      @assets.file 'folder/main.css.less', %(@import "dep-1";\n@import "subfolder/dep-2";\nbody { background-color: @background-color; color: @color; })
      @assets.file 'folder/dep-1.css.less', '@background-color: red;'
      @assets.file 'folder/subfolder/dep-2.css.less', '@color: blue;'
      asset = @env['folder/main.css']
      expect(asset.to_s).to eql("body {\n  background-color: #ff0000;\n  color: #0000ff;\n}\n")
    end

    it 'imports relative partials without preceding ./' do
      @assets.file 'folder/main.css.less', %(@import "dep-1";\n@import "subfolder/dep-2";\nbody { background-color: @background-color; color: @color; })
      @assets.file 'folder/_dep-1.css.less', '@background-color: red;'
      @assets.file 'folder/subfolder/_dep-2.css.less', '@color: blue;'
      asset = @env['folder/main.css']
      expect(asset.to_s).to eql("body {\n  background-color: #ff0000;\n  color: #0000ff;\n}\n")
    end

    it 'imports files relative to root' do
      @assets.file 'folder/main.css.less', %(@import "dep";\nbody { color: @color; })
      @assets.file 'dep.css.less', '@color: blue;'
      asset = @env['folder/main.css']
      expect(asset.to_s).to eql("body {\n  color: #0000ff;\n}\n")
    end

    it 'imports partials relative to root' do
      @assets.file 'folder/main.css.less', %(@import "dep";\nbody { color: @color; })
      @assets.file '_dep.css.less', '@color: blue;'
      asset = @env['folder/main.css']
      expect(asset.to_s).to eql("body {\n  color: #0000ff;\n}\n")
    end

  it 'shares Sass environment with other imports' do
    @assets.file 'main.css.less', %(@import "dep-1";\n@import "dep-2";)
    @assets.file '_dep-1.css.less', '@color: blue;'
    @assets.file '_dep-2.css.less', 'body { color: @color; }'
    asset = @env['main.css']
    expect(asset.to_s).to eql("body {\n  color: #0000ff;\n}\n")
  end

    it 'imports files from the assets load path' do
      vendor = @root.directory 'vendor'
      @env.append_path vendor.to_s

      @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
      vendor.file 'dep.css.less', '@color: blue;'
      asset = @env['main.css']
      expect(asset.to_s).to eql("body {\n  color: #0000ff;\n}\n")
    end

  it 'imports nested partials with relative path from the assets load path' do
    vendor = @root.directory 'vendor'
    @env.append_path vendor.to_s

    @assets.file 'folder/main.css.less', %(@import "dep";\nbody { color: @color; })
    vendor.file 'dep.css.less', '@import "folder1/dep1";'
    vendor.file 'folder1/_dep1.css.less', '@import "folder2/dep2";'
    vendor.file 'folder1/folder2/_dep2.css.less', '@color: blue;'
    asset = @env['folder/main.css']
    expect(asset.to_s).to eql("body {\n  color: #0000ff;\n}\n")
  end

    it 'imports nested partials with relative path and glob from the assets load path' do
      vendor = @root.directory 'vendor'
      @env.append_path vendor.to_s

      @assets.file 'folder/main.css.less', %(@import "dep";\nbody { color: @color; })
      vendor.file 'dep.css.less', '@import "folder1/dep1";'
      vendor.file 'folder1/_dep1.css.less', '@import "folder2/*";'
      vendor.file 'folder1/folder2/_dep2.css.less', '@color: blue;'
      asset = @env['folder/main.css']
      expect(asset.to_s).to eql("body {\n  color: #0000ff;\n}\n")
    end

    it 'allows global Sass configuration' do
      @assets.file 'main.css.less', "body {\n  color: blue;\n}"

      asset = @env['main.css']
      expect(asset.to_s).to eql("body {\n  color: blue;\n}\n")
    end

    it 'imports files from the Sass load path' do
      vendor = @root.directory 'vendor'
      @env.append_path vendor.to_s

      @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
      vendor.file 'dep.less', '@color: blue;'
      asset = @env['main.css']
      expect(asset.to_s).to eql("body {\n  color: #0000ff;\n}\n")
    end

    it 'imports globbed files' do
      @assets.file 'main.css.less', %(@import "folder/*";\nbody { color: @color; background: @bg-color; })
      @assets.file 'folder/dep-1.css.less', '@color: blue;'
      @assets.file 'folder/dep-2.css.less', '@bg-color: red;'
      asset = @env['main.css']
      expect(asset.to_s).to eql("body {\n  color: #0000ff;\n  background: #ff0000;\n}\n")
    end

    it 'adds dependencies when imported' do
      @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
      dep = @assets.file 'dep.css.less', '@color: blue;'

      asset = @env['main.css']
      old_asset = asset.dup
      expect(asset).to be_fresh(@env, old_asset)

      write_asset(dep, '@color: red;')

      asset = Sprockets::Less::Utils.version_of_sprockets >= 3 ? @env['main.css'] : asset
      expect(asset).to_not be_fresh(@env, old_asset)
    end

  it 'adds dependencies from assets when imported' do
    @assets.file 'main.css.less', %(@import "dep-1.css.less";\nbody { color: @color; })
    @assets.file 'dep-1.css.less', %(@import "dep-2.css.less";\n)
    dep = @assets.file 'dep-2.css.less', '@color: blue;'

    asset = @env['main.css']
    old_asset = asset.dup
    expect(asset).to be_fresh(@env, old_asset)

    write_asset(dep, '@color: red;')

    asset = Sprockets::Less::Utils.version_of_sprockets >= 3 ? @env['main.css'] : asset
    expect(asset).to_not be_fresh(@env, old_asset)
  end

    it 'adds dependencies when imported from a glob' do
      @assets.file 'main.css.less', %(@import "folder/*";\nbody { color: @color; background: @bg-color; })
      @assets.file 'folder/_dep-1.css.less', '@color: blue;'
      dep = @assets.file 'folder/_dep-2.css.less', '@bg-color: red;'

      asset = @env['main.css']
      old_asset = asset.dup
      expect(asset).to be_fresh(@env, old_asset)

      write_asset(dep, "@bg-color: white;" )

      asset = Sprockets::Less::Utils.version_of_sprockets >= 3 ? @env['main.css'] : asset

      expect(asset).to_not be_fresh(@env, old_asset)
    end

  it "uses the environment's cache" do
    cache = {}
    @env.cache = cache

    @assets.file 'main.css.less', %(@color: blue;\nbody { color: @color; })

    @env['main.css'].to_s
    if Sprockets::Less::Utils.version_of_sprockets < 3
      sass_cache = cache.detect { |key, value| value['pathname'] =~ /main\.css\.less/ }
    else
      sass_cache = cache.detect { |key, value| value =~ /main\.css\.less/ }
    end
    expect(sass_cache).to_not be_nil
  end


  it 'adds the #asset_path helper' do
    @assets.file 'asset_path.css.less',  %(body { background: asset-path('image.jpg'); })
    @assets.file 'asset_url.css.less', %(body { background: asset-url("image.jpg"); })
    @assets.file 'asset_url_digest.css.less', %(body { background: asset-url("image.jpg",  @digest: true, @prefix: "/themes"); })
    @assets.file 'asset_path_options.css.less', %(body { background: url(asset-path("image.jpg", @digest: true, @prefix: "/themes")); })
    @assets.file 'asset_url_options.css.less', %(body { background: url(asset-url("image.jpg", @digest: true, @prefix: "/themes")); })
    @assets.file 'image.jpg'

    # expect(@env['asset_path.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg");\n}\n))
    # expect(@env['asset_url.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg");\n}\n))
    expect(@env['asset_url_digest.css'].to_s).to match(%r(body \{\n  background\: url\(\"/themes/image-[0-9a-f]+.jpg\"\)\;\n}\n))
    expect(@env['asset_path_options.css'].to_s).to match(%r(body \{\n  background\: url\(\"/themes/image-[0-9a-f]+.jpg\"\)\;\n}\n))
    expect(@env['asset_url_options.css'].to_s).to match(%r(body \{\n  background\: url\(\"/themes/image-[0-9a-f]+.jpg\"\)\;\n}\n))
  end
  #
  it 'adds the #image_path helper' do
    @assets.file 'image_path.css.less', %(body { background: image-path("image.jpg"); })
    @assets.file 'image_url.css.less', %(body { background: image-url("image.jpg"); })
    @assets.file 'image_path_options.css.less', %(body { background: url(image-path("image.jpg", @digest: true, @prefix: "/themes")); })
    @assets.file 'image_url_options.css.less', %(body { background: image-url("image.jpg", @digest: true, @prefix: "/themes"); })
    @assets.file 'image.jpg'

    expect(@env['image_path.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg");\n}\n))
    expect(@env['image_url.css'].to_s).to eql(%(body {\n  background: url("/assets/image.jpg");\n}\n))
    expect(@env['image_path_options.css'].to_s).to match(%r(body \{\n  background\: url\(\"/themes/image-[0-9a-f]+.jpg\"\);\n\}\n))
    expect(@env['image_url_options.css'].to_s).to match(%r(body \{\n  background\: url\(\"/themes/image-[0-9a-f]+.jpg\"\);\n\}\n))
  end

  it 'adds the #font_path helper' do
    @assets.file 'font_path.css.less', %(@font-face { src: url(font-path("font.ttf")); })
    @assets.file 'font_url.css.less', %(@font-face { src: font-url("font.ttf"); })
    @assets.file 'font_path_options.css.less', %(@font-face { src: url(font-path("font.ttf", @digest: true, @prefix: "/themes")); })
    @assets.file 'font_url_options.css.less', %(@font-face { src: font-url("font.ttf", @digest: true, @prefix: "/themes"); })
    @assets.file 'font.ttf'

    expect(@env['font_path.css'].to_s).to eql(%(@font-face {\n  src: url("/assets/font.ttf");\n}\n))
    expect(@env['font_url.css'].to_s).to eql(%(@font-face {\n  src: url("/assets/font.ttf");\n}\n))
    expect(@env['font_path_options.css'].to_s).to match(%r(@font-face \{\n  src: url\(\"/themes/font-[0-9a-f]+.ttf\"\);\n\}\n))
    expect(@env['font_url_options.css'].to_s).to match(%r(@font-face \{\n  src: url\(\"/themes/font-[0-9a-f]+.ttf\"\);\n\}\n))
  end

  it 'adds the #asset_data_uri helper' do
    @assets.file 'asset_data_uri.css.less', %(body { background: asset-data-uri("image.jpg"); })
    @assets.file 'image.jpg', File.read('spec/fixtures/image.jpg')

    expect(@env['asset_data_uri.css'].to_s).to include("body {\n  background: url(data:image/jpeg;base64,")
  end

  describe Sprockets::Less::LessTemplate do

    let(:template) do
      Sprockets::Less::LessTemplate.new(@assets.file 'bullet.gif') do
        # nothing
      end
    end
    describe 'initialize_engine' do

      it 'does add Sass functions if sprockets-helpers is not available' do
        Sprockets::Less::LessTemplate.less_functions_initialized = false
        Sprockets::Less.add_less_functions = true
        expect_any_instance_of(Sprockets::Less::LessTemplate).to receive(:require).with('sprockets/helpers').and_raise(LoadError)
        expect_any_instance_of(Sprockets::Less::LessTemplate).to_not receive(:require).with 'sprockets/less/functions'
        template
        expect(Sprockets::Less::LessTemplate.engine_initialized?).to be_falsy
      end

      it 'does not add Sass functions if add_less_functions is false' do
        Sprockets::Less.add_less_functions = false
        expect(template).to_not receive(:require).with 'sprockets/less/functions'
        template.initialize_engine
        expect(Sprockets::Less::LessTemplate.engine_initialized?).to be_falsy
        Sprockets::Less.add_less_functions = true
      end
    end
  end
end
