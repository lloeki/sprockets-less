require 'spec_helper'

RSpec.configure do |c|
  c.filter_run_excluding :broken => true
  c.filter_run_excluding :todo => true
end

describe Sprockets::Less do
  before :each do
    @root   = create_construct
    @assets = @root.directory 'assets'
    @env    = Sprockets::Environment.new @root.to_s
    @env.append_path @assets.to_s
  end

  after :each do
    @root.destroy!
  end

  it 'processes less files normally' do
    @assets.file 'main.css.less', '//= require dep'
    @assets.file 'dep.less', %(body { color: blue; })
    asset = @env['main.css']
    asset.to_s.should == "body {\n  color: blue;\n}\n"
  end

  it 'imports standard files' do
    @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
    @assets.file 'dep.less', '@color: blue;'
    asset = @env['main.css']
    asset.to_s.should == "body {\n  color: #0000ff;\n}\n"
  end

  it 'imports partials' do
    @assets.file 'main.css.less', %(@import "_dep";\nbody { color: @color; })
    @assets.file '_dep.less', '@color: blue;'
    asset = @env['main.css']
    asset.to_s.should == "body {\n  color: #0000ff;\n}\n"
  end

  it 'imports files with the correct content type', :broken => true do
    @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
    @assets.file 'dep.js', 'var app = {};'
    @assets.file '_dep.less', '@color: blue;'
    asset = @env['main.css']
    asset.to_s.should == "body {\n  color: #0000ff;\n}\n"
  end

  it 'imports files with directives', :todo => true do
    @assets.file 'main.css.less', %(@import "dep";)
    @assets.file 'dep.css', "/*\n *= require subdep\n */"
    @assets.file 'subdep.css.less', "@color: blue;\nbody { color: @color; }"
    asset = @env['main.css']
    asset.to_s.should include("body {\n  color: #0000ff; }\n")
  end

  it 'imports files with additional processors', :todo => true do
    @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
    @assets.file 'dep.css.less.erb', "@color: <%= 'blue' %>;"
    asset = @env['main.css']
    asset.to_s.should == "body {\n  color: blue; }\n"
  end

  it 'imports relative files', :todo => true do
    @assets.file 'folder/main.css.less', %(@import "./dep-1";\n@import "./subfolder/dep-2";\nbody { background-color: @background-color; color: @color; })
    @assets.file 'folder/dep-1.less', '@background-color: red;'
    @assets.file 'folder/subfolder/dep-2.less', '@color: blue;'
    asset = @env['folder/main.css']
    asset.to_s.should == "body {\n  background-color: #ff0000;\n  color: #0000ff; }\n"
  end

  it 'imports relative partials', :todo => true do
    @assets.file 'folder/main.css.less', %(@import "./dep-1";\n@import "./subfolder/dep-2";\nbody { background-color: @background-color; color: @color; })
    @assets.file 'folder/_dep-1.less', '@background-color: red;'
    @assets.file 'folder/subfolder/_dep-2.less', '@color: blue;'
    asset = @env['folder/main.css']
    asset.to_s.should == "body {\n  background-color: #ff0000;\n  color: blue; }\n"
  end

  it 'imports relative files without preceding ./', :todo => true do
    @assets.file 'folder/main.css.less', %(@import "dep-1";\n@import "subfolder/dep-2";\nbody { background-color: @background-color; color: @color; })
    @assets.file 'folder/dep-1.less', '@background-color: red;'
    @assets.file 'folder/subfolder/dep-2.less', '@color: blue;'
    asset = @env['folder/main.css']
    asset.to_s.should == "body {\n  background-color: red;\n  color: blue; }\n"
  end

  it 'imports relative partials without preceding ./', :todo => true do
    @assets.file 'folder/main.css.less', %(@import "dep-1";\n@import "subfolder/dep-2";\nbody { background-color: @background-color; color: @color; })
    @assets.file 'folder/_dep-1.less', '@background-color: red;'
    @assets.file 'folder/subfolder/_dep-2.less', '@color: blue;'
    asset = @env['folder/main.css']
    asset.to_s.should == "body {\n  background-color: red;\n  color: blue; }\n"
  end

  it 'imports files relative to root' do
    @assets.file 'folder/main.css.less', %(@import "dep";\nbody { color: @color; })
    @assets.file 'dep.less', '@color: blue;'
    asset = @env['folder/main.css']
    asset.to_s.should == "body {\n  color: #0000ff;\n}\n"
  end

  it 'imports partials relative to root', :broken => true do
    @assets.file 'folder/main.css.less', %(@import "dep";\nbody { color: @color; })
    @assets.file '_dep.less', '@color: blue;'
    asset = @env['folder/main.css']
    asset.to_s.should == "body {\n  color: #0000ff;\n}\n"
  end

  it 'shares Less environment with other imports' do
    @assets.file 'main.css.less', %(@import "dep-1";\n@import "dep-2";)
    @assets.file 'dep-1.less', '@color: blue;'
    @assets.file 'dep-2.less', 'body { color: @color; }'
    asset = @env['main.css']
    asset.to_s.should == "body {\n  color: #0000ff;\n}\n"
  end

  it 'imports files from the assets load path' do
    vendor = @root.directory 'vendor'
    @env.append_path vendor.to_s

    @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
    vendor.file 'dep.less', '@color: blue;'
    asset = @env['main.css']
    asset.to_s.should == "body {\n  color: #0000ff;\n}\n"
  end

  it 'allows global Less configuration' do
    Sprockets::Less.options[:compress] = true
    @assets.file 'main.css.less', "body {\n  color: #00f;\n}"

    asset = @env['main.css']
    asset.to_s.should == "body{color:#00f}\n"
    Sprockets::Less.options.delete(:compress)
  end

  it 'imports files from the Less load path' do
    vendor = @root.directory 'vendor'
    Sprockets::Less.options[:paths] = [ vendor.to_s ]

    @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
    vendor.file 'dep.less', '@color: blue;'
    asset = @env['main.css']
    asset.to_s.should == "body {\n  color: #0000ff;\n}\n"
    Sprockets::Less.options.delete(:paths)
  end

  it 'adds dependencies when imported' do
    @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
    dep = @assets.file 'dep.less', '@color: blue;'

    asset = @env['main.css']
    asset.should be_fresh(@env)

    mtime = Time.now + 1
    dep.open('w') { |f| f.write '@color: red;' }
    dep.utime mtime, mtime

    asset.should_not be_fresh(@env)
  end

  it 'adds dependencies from assets when imported' do
    @assets.file 'main.css.less', %(@import "dep-1";\nbody { color: @color; })
    @assets.file 'dep-1.less', %(@import "dep-2";\n)
    dep = @assets.file 'dep-2.less', '@color: blue;'

    asset = @env['main.css']
    asset.should be_fresh(@env)

    mtime = Time.now + 1
    dep.open('w') { |f| f.write '@color: red;' }
    dep.utime mtime, mtime

    asset.should_not be_fresh(@env)
  end

  it "uses the environment's cache", :todo => true do
    cache = {}
    @env.cache = cache

    @assets.file 'main.css.less', %(@color: blue;\nbody { color: @color; })

    @env['main.css'].to_s
    less_cache = cache.keys.detect { |key| key =~ /main\.css\.less/ }
    less_cache.should_not be_nil
  end

  it 'adds the #asset_path helper', :broken => true do
    @assets.file 'asset_path.css.less', %(body { background: url(asset-path("image.jpg")); })
    @assets.file 'asset_url.css.less', %(body { background: asset-url("image.jpg"); })
    @assets.file 'asset_path_options.css.less', %(body { background: url(asset-path("image.jpg", $digest: true, $prefix: "/themes")); })
    @assets.file 'asset_url_options.css.less', %(body { background: asset-url("image.jpg", $digest: true, $prefix: "/themes"); })
    @assets.file 'image.jpg'

    @env['asset_path.css'].to_s.should == %(body {\n  background: url("/assets/image.jpg"); }\n)
    @env['asset_url.css'].to_s.should == %(body {\n  background: url("/assets/image.jpg"); }\n)
    @env['asset_path_options.css'].to_s.should =~ %r(body \{\n  background: url\("/themes/image-[0-9a-f]+.jpg"\); \}\n)
    @env['asset_url_options.css'].to_s.should =~ %r(body \{\n  background: url\("/themes/image-[0-9a-f]+.jpg"\); \}\n)
  end

  it 'adds the #image_path helper', :broken => true do
    @assets.file 'image_path.css.less', %(body { background: url(image-path("image.jpg")); })
    @assets.file 'image_url.css.less', %(body { background: image-url("image.jpg"); })
    @assets.file 'image_path_options.css.less', %(body { background: url(image-path("image.jpg", $digest: true, $prefix: "/themes")); })
    @assets.file 'image_url_options.css.less', %(body { background: image-url("image.jpg", $digest: true, $prefix: "/themes"); })
    @assets.file 'image.jpg'

    @env['image_path.css'].to_s.should == %(body {\n  background: url("/assets/image.jpg"); }\n)
    @env['image_url.css'].to_s.should == %(body {\n  background: url("/assets/image.jpg"); }\n)
    @env['image_path_options.css'].to_s.should =~ %r(body \{\n  background: url\("/themes/image-[0-9a-f]+.jpg"\); \}\n)
    @env['image_url_options.css'].to_s.should =~ %r(body \{\n  background: url\("/themes/image-[0-9a-f]+.jpg"\); \}\n)
  end

  it 'adds the #font_path helper', :broken => true do
    @assets.file 'font_path.css.less', %(@font-face { src: url(font-path("font.ttf")); })
    @assets.file 'font_url.css.less', %(@font-face { src: font-url("font.ttf"); })
    @assets.file 'font_path_options.css.less', %(@font-face { src: url(font-path("font.ttf", $digest: true, $prefix: "/themes")); })
    @assets.file 'font_url_options.css.less', %(@font-face { src: font-url("font.ttf", $digest: true, $prefix: "/themes"); })
    @assets.file 'font.ttf'

    @env['font_path.css'].to_s.should == %(@font-face {\n  src: url("/assets/font.ttf"); }\n)
    @env['font_url.css'].to_s.should == %(@font-face {\n  src: url("/assets/font.ttf"); }\n)
    @env['font_path_options.css'].to_s.should =~ %r(@font-face \{\n  src: url\("/themes/font-[0-9a-f]+.ttf"\); \}\n)
    @env['font_url_options.css'].to_s.should =~ %r(@font-face \{\n  src: url\("/themes/font-[0-9a-f]+.ttf"\); \}\n)
  end

  it 'adds the #asset_data_uri helper', :broken => true do
    @assets.file 'asset_data_uri.css.less', %(body { background: asset-data-uri("image.jpg"); })
    @assets.file 'image.jpg', File.read('spec/fixtures/image.jpg')

    @env['asset_data_uri.css'].to_s.should == %(body {\n  background: url(data:image/jpeg;base64,%2F9j%2F4AAQSkZJRgABAgAAZABkAAD%2F7AARRHVja3kAAQAEAAAAPAAA%2F%2B4ADkFkb2JlAGTAAAAAAf%2FbAIQABgQEBAUEBgUFBgkGBQYJCwgGBggLDAoKCwoKDBAMDAwMDAwQDA4PEA8ODBMTFBQTExwbGxscHx8fHx8fHx8fHwEHBwcNDA0YEBAYGhURFRofHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8f%2F8AAEQgAAQABAwERAAIRAQMRAf%2FEAEoAAQAAAAAAAAAAAAAAAAAAAAgBAQAAAAAAAAAAAAAAAAAAAAAQAQAAAAAAAAAAAAAAAAAAAAARAQAAAAAAAAAAAAAAAAAAAAD%2F2gAMAwEAAhEDEQA%2FACoD%2F9k%3D); }\n)
  end

  it "mirrors Less::Rails's #asset_path helpers", :broken => true do
    @assets.file 'asset_path.css.less', %(body { background: url(asset-path("image.jpg", image)); })
    @assets.file 'asset_url.css.less', %(body { background: asset-url("icon.jpg", image); })
    @assets.file 'image.jpg'

    @env['asset_path.css'].to_s.should == %(body {\n  background: url("/assets/image.jpg"); }\n)
    @env['asset_url.css'].to_s.should == %(body {\n  background: url("/images/icon.jpg"); }\n)
  end

  describe Sprockets::Less::LessTemplate do
    describe 'initialize_engine' do
      it 'initializes super if super is uninitialized' do
        Tilt::LessTemplate.stub(:engine_initialized?).and_return false
        template = Sprockets::Less::LessTemplate.new {}
        template.should_receive(:require_template_library) # called from Tilt::LessTemplate.initialize
        template.initialize_engine
      end

      it "does not initializes super if super is initialized to silence warnings" do
        Tilt::LessTemplate.stub(:engine_initialized?).and_return true
        template = Sprockets::Less::LessTemplate.new {}
        template.should_not_receive(:require_template_library) # called from Tilt::LessTemplate.initialize
        template.initialize_engine
      end
    end
  end
end
