# Revised version of a Sprockets 3.x processor for Elm.
require "open3"

# Elm Sprockets integration
class ElmProcessor
  VERSION = "1"

  class CompileError < StandardError; end

  class << self
    def call(input)
      new(input).call
    end

    def cmd
      @_cmd ||= ENV.fetch("ELM_MAKE_PATH", "elm-make")
    end

    def elm_version
      @_elm_version ||= begin
        line = `#{cmd} --help`.lines.first.chomp
        line.match(/\(Elm Platform (.+)\)/) { |m| m[1] }
      end
    end

    def cache_key
      @_cache_key ||= "#{name}:#{elm_version}:#{VERSION}"
    end
  end

  def initialize(input)
    @input = input
  end

  def call
    input[:cache].fetch([cache_key, hexdigest]) { compile }
  end

  private
  attr_reader :input

  def compile
    Open3.popen3(cmd, "--yes", "--output", output_file.to_s, filename, chdir: Rails.root) do |_in, out, err, t|
      compiler_out = out.read
      compiler_err = err.read
      if t.value != 0
        raise CompileError, compiler_err
      end

      add_dependencies
      context.metadata.merge(data: output_file.read)
    end
  end

  def output_file
    root.join("tmp", "cache", "assets", "elm", "#{input[:name]}.js")
  end

  def cmd
    self.class.cmd
  end

  def cache_key
    self.class.cache_key
  end

  def filename
    input[:filename]
  end

  def data
    input[:data]
  end

  def root
    Pathname.new(input[:environment].root)
  end

  def logger
    input[:environment].logger
  end

  def context
    @_context ||= input[:environment].context_class.new(input)
  end

  def add_dependencies
    dependencies do |dep|
      context.depend_on(dep.name)
    end
  end

  def hexdigest
    dependencies.map(&:hexdigest).push(Digest::SHA1.hexdigest(data))
  end

  def dependencies
    return to_enum(__method__) unless block_given?

    queue = [data]
    while curr = queue.pop
      curr.scan(/^import\s+([^\s]+)/).map do |import|
        logical_name = import.first.gsub(".", "/")
        path = File.join(input[:load_path], "#{logical_name}.elm")

        if File.file?(path)
          dep = Dependency.new(logical_name, path, File.read(path))
          queue.push(dep.content)
          yield dep
        end
      end
    end
  end

  Dependency = Struct.new(:name, :path, :content) do
    def hexdigest
      Digest::SHA1.hexdigest(content)
    end
  end
end

Sprockets.register_mime_type 'text/x-elm', extensions: ['.elm']
Sprockets.register_transformer 'text/x-elm', 'application/javascript', ElmProcessor
