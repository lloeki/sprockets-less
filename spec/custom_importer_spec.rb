require 'spec_helper'

describe Sprockets::Less::LessTemplate do

  before :each do
    # Create the custom importer.
    @custom_importer =  Sprockets::Less::DummyImporter.new
    Sprockets::Less.options[:importer] = @custom_importer

    # Initialize the environment.
    @root = create_construct
    @assets = @root.directory 'assets'
    @env = Sprockets::Environment.new @root.to_s
    @env.append_path @assets.to_s
    @env.register_postprocessor 'text/css', FailPostProcessor
  end

  after :each do
    @root.destroy!
    #Sprockets::Less.options[:importer] = nil
  end

  it 'imports standard files' do
     @assets.file 'main.css.less', %(@import "dep";\nbody { color: @color; })
     @assets.file 'dep.less', '@color: blue;'
     asset = @env['main.css']
     expect(asset.to_s).to  eq("body {\n  color: #0000ff;\n}\n")
    expect(@custom_importer.has_been_used).to be_truthy
   end


end
