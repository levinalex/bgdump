#!/usr/bin/env ruby

# this is given a source data directory for bgbls and attempts to make sense of it
#
# USAGE: $0 source_dir target_dir

require 'fileutils'


# it will:
# - remove encryption
# - check page counts and warn if source data appears inconsistent
# - try to extract TOCs (?)

source_dir = File.join(Dir.pwd, ARGV[0])
target_dir = File.join(Dir.pwd, ARGV[1])

FileUtils.mkdir_p("tmp/staging")
Dir.chdir("tmp/staging")


p source_dir
Dir[source_dir + "/**/*.pdf"].each do |f|
  n = File.basename(f)

  if n =~ /^(\d{4}-\d{2}-\d{2}).(\d{3}).bgbl1\d{2}[si](\d{4})([a-e]?).pdf$/
    date = $1
    year = date[0...4]
    num = $2
    start_page = $3.to_i
    appendix = $4

    err = `qpdf --decrypt #{f} out.pdf`
    if $? == 0
      FileUtils.mkdir_p("x")

      err = `pdftk out.pdf burst output x/#{num}.%04d.pdf`
      if $? == 0

        files = Dir["x/*.pdf"].sort
        files.each_with_index do |x, idx|
          pdfpage = start_page + idx

          output = "#{date}.#{num}.#{"%05d" % pdfpage}#{appendix}.pdf"
          outpath = [target_dir, year, output].join("/")

          puts outpath

          FileUtils.mkdir_p(File.dirname(outpath))
          FileUtils.mv(x, outpath)
        end

        Dir.rmdir("x")


      else
        warn err
        warn "pdftk of #{f} failed"
        sleep 5
      end

    else
      warn err
      warn "parsing of #{f} failed"
      sleep 5
    end

  else
    warn "unparsable filename: #{n}"
  end

end

