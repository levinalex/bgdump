#!/usr/bin/ruby
#
# usage: ./fetch.sh <year_list_uri>

require "nokogiri"
require "open-uri"
require "digest/md5"
require "fileutils"


def open_with_cache(uri)
  digest = Digest::MD5.hexdigest(uri)
  cache_path = "cache/#{digest}.html"
  if !File.exist?(cache_path)
    warn "caching #{uri}"
    sleep rand(5)
    File.open(cache_path, "w") { |f| f.write(open(uri).read) }
  end
  File.open(cache_path) do |f|
    yield f
  end
end

def save_bgbl(uri, number, day, month, year)
  path = ["data", "%04d" % year.to_i].join("/")
  fpath = [path, "%03d_%04d-%02d-%02d.pdf" % [number, year, month, day].map(&:to_i)].join("/")

  FileUtils.mkdir_p(path)

  if File.exist?(fpath)
    warn "skipped #{fpath}"
  else
    warn "writing #{fpath}"
    sleep rand(5)
    File.open(fpath, "w") do |f|
      f.write(open(uri).read)
    end
  end
end

open_with_cache(ARGV[0]) do |data|
  doc = Nokogiri::HTML(data)

  doc.xpath('///a[@href][span[img]]').each do |link|
    open_with_cache(link["href"]) do |f2|
      d2 = Nokogiri::HTML(f2)
      d2.xpath('///a').each do |l|
        if l["title"] =~ /(\d+).*?vom.*?(\d+)\.(\d+)\.(\d+)/
          number, day, month, year = $1, $2, $3, $4
          open_with_cache(l["href"]) do |f3|
            d3 = Nokogiri::HTML(f3)

            d3.xpath("///a['@href']").each do |l|
              if l.content =~ /komplette\s*ausgabe/i
                save_bgbl(l["href"], number, day, month, year)
              end
            end
          end
        end
      end
    end
  end
end







