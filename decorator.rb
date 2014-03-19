require 'json'

class Decorator
  def initialize(app)
    @app = app
  end

  def call(env)
    res = @app.call(env)
    p res
    content_size = 0
    if res[1]['Content-Type'] == 'application/json;charset=utf-8'
      res[2] = res[2].inject([]) do |array, json|
        json = JSON.dump(formatter(JSON.parse(json), :to_camel))
        content_size += json.bytesize
        array << json
      end
      res[1]['Content-Length'] = content_size.to_s
    end
    p res
    res
  end

  private
  # hashのkeyがstringの場合、symbolに変換します。hashが入れ子の場合も再帰的に変換します。
  # format引数に :to_snake, :to_camelを渡すと、応じたフォーマットに変換します
  def formatter(args, format)

    case_changer = lambda(&method(format))
    # to_snakeの場合、さらにsymbolに変換する
    case_changer = lambda{ |x| lambda(&method(format)).call(x).to_sym } if format == :to_snake

    key_converter = lambda do |key|
      key = case_changer.call(key) if key.is_a?(String)
      key
    end

    case args
      when Hash
        args.inject({}){ |hash, (key, value)| hash[key_converter.call(key)] = formatter(value, format); hash}
      when Array
        args.inject([]){ |array, value| array << formatter(value, format) }
      else
        args
    end
  end

  def to_camel(string)
    string.gsub(/_+([a-z])/){ |matched| matched.tr("_", '').upcase }.sub(/^(.)/){ |matched| matched.downcase }
  end

end