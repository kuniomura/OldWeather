# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'kconv'
require 'date'

SEPARATOR = ','

#STARTDATE = "2013-5-20"
#ENDDATE = "2013-6-2"

class OldWeather
  def initialize
    @lastym = ""
    @weather_infos = []    
  end

  def ym(date)
    date.year.to_s + date.month.to_s
  end
 
  def download(date)
    year = date.year
    month = date.month

    url = "http://www.data.jma.go.jp/obd/stats/etrn/view/daily_s1.php?prec_no=51&block_no=47636&year=#{year}&month=#{month}&day=1&view="
    @doc = Nokogiri::HTML(open(url))
    @lastym = ym(date)

    @weather_infos = []
    tables = @doc/:table
    table = tables[2]
    records = table/:tr
    @weather_infos << "#{year}-#{month}-"
    records.each do |record|
      items = record/:td
      if items[0] && /[0-9]+/ =~ items[0].inner_text then
        line = [items[0].inner_text,
               items[7].inner_text,
               items[8].inner_text,
               items[19].inner_text]
        @weather_infos << line
      end
    end
  end
  
  def info(date)
    if ym(date) != @lastym then
      download(date)
    end
    @weather_infos[date.day]
  end
end


#
# main routine
#
# input
#     date date 日付指定
#　　　　　　　　　　　　指定した日付間が処理の対象となる
#　　　　　　　　　　　　dateの書式は、　"YYYY-MM-DD"
#               日付が前後した場合は、過去の日付から直近の日付に並べ替えられる
#
#     n         日数指定
#　　　　　　　　　　　　昨日から昨日のn日前まで期間が処理の対象となる
#
#　　　　なし　　　　　　昨日が処理の対象となる
#
# output
#     日付（日のみ） \t 最高気温/最低気温 \t天気概要
#       ...
#
if ARGV.size == 2 then  # 開始日付と最終日付が指定されている
  startdate_str = ARGV[0]
  enddate_str = ARGV[1]
elsif ARGV.size == 1 then # 開始日付のみ指定されている。最終日付は処理日前日。
  yesterday = Date.today - 1
  enddate_str = yesterday.to_s
  begin
    startdate_str = (yesterday - ARGV[0].to_i).to_s
  rescue
    puts "Argument error!! [" + ARGV[0] + "]"
    abort()
  end
else    # 開始日付も最終日付も無し。処理日の2週間前から前日まで。
  yesterday = Date.today - 1
  startdate_str = (yesterday-13).to_s
  enddate_str = yesterday.to_s
end

begin
  startdate = Date.parse(startdate_str)
  enddate = Date.parse(enddate_str)
rescue
  puts "Date format error!! [" + startdate_str + " " + enddate_str + "]"
else
  weather = OldWeather.new

  if startdate > enddate then
    temp = startdate
    startdate = enddate
    enddate = temp
  end

  date = startdate
  while date <= enddate do
    weather_info = weather.info(date)
    puts "#{date.month}/#{weather_info[0]}#{SEPARATOR}#{weather_info[1]}/#{weather_info[2]}#{SEPARATOR}#{weather_info[3]}"
    date += 1
  end
end

