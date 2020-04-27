require 'nokogiri'
require 'open-uri'
require 'cgi/util'

class MyShows

  BASE_URL = 'https://myshows.me'.freeze

  attr_accessor :query

  def initialize(query = nil)
    # @logger = Logger.new(STDOUT)
    @query = query
  end

  def parse_html(url = '')
    Nokogiri::HTML(URI.open(BASE_URL + url))
  rescue StandardError
    logger.debug 'Error 404. Page not found.'
    nil
  end

  # hash of searched series or top rated movies if no query
  def movies_list
    return top_rated if query.nil?

    content = {}
    encoded_query = CGI.escape(@query)
    html = parse_html("/search/?q=#{encoded_query}")
    all_series = html.css('table.catalogTable').search('tr')
    all_series[1...-1].each do |movie|
      movie_id = movie.css('td > a')[0]['href'][/\d+/]
      content[:"#{movie_id}"] = {
        en_title: movie.css('td > .catalogTableSubHeader')[0].text,
        ru_title: movie.css('td > a')[0].text,
        watchers: movie.css('td')[2].text,
        seasons: movie.css('td')[4].text,
        year: movie.css('td')[5].text
      }
    end
    content
  rescue NoMethodError
    logger.debug "Can't apply selectors in '#{__method__}' method. DOM structure apparently was changed."
  end

  def movie_info
    html = parse_html("/view/#{@query}/")
    movie_full_info = {
      movie_ru_title: html.css('.container > .row > .col8 > h1').text,
      movie_en_title: html.css('.container > .row > .col8 > .subHeader').text,
      movie_image: html.css('.presentBlock > .presentBlockImg').to_s[/(?<=\().+?(?=\))/],
      description: html.css('main > .row > .col5 > p').text.gsub(' ', ''),
      start_date: html.css('.clear > p')[0].text[/\d+\s+[а-яА-Я]+\s+\d+/],
      country: html.css('.clear > p')[1].text.split[1],
      imdb: html.css('.clear > p')[7].text[/\d.\d+\s[а-я]+\s\d+/],
      kinopoisk: html.css('.clear > p')[8].text[/\d.\d+\s[а-я]+\s\d+/]
    }
    movie_full_info
  rescue NoMethodError
    logger.debug "Can't apply selectors in '#{__method__}' method. DOM structure apparently was changed."
  end

  def episodes_list
    episodes_info = {}
    html = parse_html("/view/#{@query}/")
    # list of all seasons
    html.css('.col8 > form > .row[itemprop="season"]').reverse_each do |season|
      special_series_counter = 1

      season.css('.widerCont > .infoList > li').reverse_each do |series|
        episode_number = series.css('._numb').text
        if episode_number.empty?
          episode_number = "#{special_series_counter} (special)"
          special_series_counter += 1
        end
        season_number = season.css('.flat > a')[0].text.split(' ')[0]
        episodes_info[:"#{season_number}_#{episode_number}"] = {
          season_number: season_number,
          episode_number: episode_number,
          episode_title: series.css('._name').text,
          episode_date: series.css('._date').text
        }
      end
    end
    episodes_info
  rescue NoMethodError
    logger.debug "Can't apply selectors in '#{__method__}' method. DOM structure apparently was changed."
  end

  # top rated movies from main page
  def top_rated
    top_rated_list = {}
    html = parse_html
    html.css('.landing > .container > .row> .col3 > a')[1...8].each do |movie|
      movie_id = movie['href'][/\d+/]
      top_rated_list[:"#{movie_id}"] = {
        movie_ru_title: movie.css('.fsHeader').text,
        movie_en_title: movie.css('.cFadeLight').text,
        movie_image_link: movie.search('._img').to_s[/(?<=\().+?(?=\))/],
        movie_page_link: movie['href']
      }
    end
    top_rated_list
  rescue NoMethodError
    logger.debug "Can't apply selectors in '#{__method__}' method. DOM structure apparently was changed."
  end
end