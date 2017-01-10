# xmlmap
An active record like lib for parsing xml files, with which you can define relations with has_many and conditions, letting you do ::all and #<relation name>. Paths can be defined using css paths or xpath. 

Install

```
gem install xmlmap
```

so lets see an example of it in action. Given an xml file with this structure (actual games.xml sample file is a bit longer):

```
<?xml version="1.0" encoding="ISO-8859-1" ?>

<data>
	<categories>
		<category>RTS</category>
		<category>Adventure</category>
		<category>FPS</category>
	<categories>

<game>
	<title>Starcraft</title>
 <screenshot>http://fake.com/starcraft1.jpg</screenshot> 
 <screenshot>http://fake.com/starcraft2.jpg</screenshot> 
 <screenshot>http://fake.com/starcraft3.jpg</screenshot> 
 <categories>RTS</categories>
</game>

<game>
	<title>Full throttle</title>
 <screenshot>http://fake.com/fullthrottle1.jpg</screenshot> 
 <screenshot>http://fake.com/fullthrottle2.jpg</screenshot> 
 <screenshot>http://fake.com/fullthrottle3.jpg</screenshot> 
 <categories>Adventure</categories>
</game>

</data>
```

We can use xmlmap like:

```
gem 'xmlmap'
require 'xmlmap'

#if a pluralization you need isnt already covered by ActiveSupport, then you'll need to add it like this:
#ActiveSupport::Inflector.inflections do |inflect|
  #inflect.irregular 'rohir', 'rohirrim'
#end

class Game < Xmlmap
set_url './games.xml'
set_path 'data game'
has_many :screenshots, 
	       :conditions => Proc.new { |gm,screen| true } #demo condition filter doing nothing 

  def categories
		self.at('categories').inner_text.strip
  end
end

class Screenshot < Xmlmap
set_url './games.xml'
set_path 'screenshot', :base => :game #so Screenshot.all will look for the combined 'data game screenshot' path

end

class Category < Xmlmap
set_url './games.xml'
set_path 'data categories category'

has_many :games, 
	       :non_descendant_path => [:game],
	       :conditions => Proc.new { |category, game| game.categories.match category.inner_text }           
end

puts 'All game titles and screenshots'
puts ' '

games = Game.all
games.each do |game|
  puts game.at('title').inner_text
  puts '   '+game.screenshots.map(&:inner_text).join(' ')
end

puts ' '
puts 'now lets get the first screenshot for the games in the RTS category'
puts ' '



games = Category.all.detect { |cat| cat.inner_text.strip == 'RTS' }.games

games.each do |game|
  puts game.screenshots.first.inner_text unless game.screenshots.empty?
end
```


