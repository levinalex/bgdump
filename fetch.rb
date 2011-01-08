#!/usr/bin/ruby
#
# usage: ./fetch.sh < file_with_year_list_uri

require "nokogiri"
require "open-uri"
require "digest/md5"
require "fileutils"


def open_with_cache(uri)
  FileUtils.mkdir_p("tmp/cache")
  digest = Digest::MD5.hexdigest(uri)
  cache_path = "tmp/cache/#{digest}.html"
  if !File.exist?(cache_path)
    warn "caching #{uri}"
    sleep rand
    File.open(cache_path, "w") { |f| f.write(open(uri).read) }
  end
  File.open(cache_path) do |f|
    yield f
  end
end

def save_bgbl(uri, fname, number, day, month, year)
  path = ["data", "%04d" % year.to_i].join("/")
  fpath = [path, "%04d-%02d-%02d.%03d.#{fname}" % [year, month, day, number].map(&:to_i)].join("/")

  FileUtils.mkdir_p(path)

  if File.exist?(fpath) && File.size(fpath) > 0
    warn "skipped #{fpath}"
  else
    warn "writing #{fpath}"
    sleep rand
    File.open(fpath, "w") do |f|
      f.write(open(uri).read)
    end
  end
end

def each_year(uri)
  open_with_cache(uri) do |data|
    doc = Nokogiri::HTML(data)
    arr = doc.xpath('///a[@href][span[img]]')
    arr = arr.sort_by { rand }
    arr.each do |doc|
      yield doc["href"]
    end
  end
end

def each_document(uri)
  open_with_cache(uri) do |f|
    d2 = Nokogiri::HTML(f)
    d2.xpath('///a').reverse_each do |l|
      if l["title"] =~ /(\d+).*?vom.*?(\d+)\.(\d+)\.(\d+)/
        number, day, month, year = $1, $2, $3, $4
        yield l["href"], number.to_i, day.to_i, month.to_i, year.to_i
      end
    end
  end
end

def each_document_page(uri)
  open_with_cache(uri) do |f|
    doc = Nokogiri::HTML(f)
    doc.xpath("///a[@href]").each do |l|
      path = l["href"]
      fname = path.split("%2F").last
      yield path, fname
    end
  end
end


uri = gets.strip

each_year(uri) do |year_uri|
  each_document(year_uri) do |toc_uri, num, day, month, year|
    each_document_page(toc_uri) do |uri, fname|
      next unless fname =~ /[si]/
      save_bgbl(uri, fname, num, day, month, year)
    end
  end
end







