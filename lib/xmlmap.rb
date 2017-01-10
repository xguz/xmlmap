require 'rubygems'
require 'active_support'
require 'nokogiri'

class String
  def classify
    ActiveSupport::Inflector.classify(ActiveSupport::Inflector.singularize(self))
  end

  def constantize
    ActiveSupport::Inflector.constantize(self)
  end
end

class Xmlmap
   class << self #we stand on the context of the metaclass, the methods here defined wont be instance ones but class methods

		 #when Xmlmap is inherited, we create the @xml_map variable in the context of the inheritor metaclass, this variable will contain the results of configuration 
		 def inherited(subclass)
       subclass.class_eval do
         @xml_map = {}
       end
     end

     def set_url(url)
       @xml_map[:url] = url
       @xml_map[:xml_object] = Nokogiri::XML(open(@xml_map[:url]))
     end

     def set_path(path, opts = {})
			 #if there is an established base we'll build an anonymous function (Proc) that triggers the construction of the route that corresponds to taht base function, else the path for this class will simply be the string in the path parameter. Pay attention to the fact that the xml_path method we call here simpy returns the contents of @xml_map[:path] in the base class. So what we are doing is we are going up the hierarchy until we reeach a "patriarch" class that contains an absolute path and then we add strings for routes as we go down.
       if opts[:base]
         @xml_map[:path] = [ Proc.new { opts[:base].to_s.classify.constantize.get_xml_path }, path ]
       else 
         @xml_map[:path] = path
       end
     end
   
		 #the #all method, which will create an array of fresh instances for all the elements that match the chosen path
     def all
       find_many(self.get_xml_path).map do |xml_element|
         self.new(xml_element)
       end
     end

     def get_xml_path
       @xml_map[:path]
     end     

     def find_many(path_parts)
       @xml_map[:xml_object].search stringify_path(path_parts) 
     end

     def stringify_path(path_parts)
			 #if this is a single element, we'll still create an array with a single element just like when we receive an array - we verify in Duck Typing fashion
       path_parts = [path_parts] unless path_parts.respond_to?(:join)
       path_parts = path_parts.flatten.map do |path_part|
         if path_part.respond_to?(:call)
           path_part.call
         else
           path_part
         end
       end
       path_parts.join(' ')
     end

     def get_destination_relative_path_to_self(destination_name)
       destination_path = destination_name.classify.constantize.get_xml_path
       if destination_path.is_a? Array
         destination_path.last
       else
         destination_path
       end
     end

		 #lets build a method with the name of the associated entity (yay metaprogramming!), that searches for subelements using the part that is relative to the base (the last) or in the case that the destination entity is not nested into the origin one (that happens when we receive the :non_descendant_path option), calling the ::all method on the associated class. If an anonymous function (Proc) called :conditions is present in options, the found instances will be filtered by it.

     def has_many(what, opts={})
       define_method(what) do
         if opts[:non_descendant_path]
           result_instances = what.to_s.classify.constantize.all
         else
           subpath = self.class.get_destination_relative_path_to_self(what.to_s)
           result_instances = find_many(subpath, what.to_s)
         end

         if opts[:conditions]
           result_instances = result_instances.select {|result_instance| opts[:conditions].call(self, result_instance) }
         end
         result_instances
       end
     end
   end

	#instance methods
	 
	 #this is the method that will run when an inheritor class receives a ::new message
  def initialize(element)
    @xml_element = element
  end
 
	#we divert all calls to unknown methods of instances of classes that inherit Xmlmap to the associated Nokogiri object for that instance. That way you can use Nokogiri methods like #at, #inner_text, etc directly against the Xmlmap objects 
  def method_missing(name, *args, &block)
    @xml_element.send(name, *args, &block)
  end

	#find_many simpy passes the call to the #search Nokogiri method, to bring subelelements by a css string or xpath and creates instances for the corresponding class
  def find_many(subpath, class_name)
    self.search(subpath).map {|xml_element| class_name.classify.constantize.new(xml_element) }
  end
end
